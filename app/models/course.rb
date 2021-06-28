# coding: utf-8
require "Octokit_Wrapper"
require "json"

class Course < ApplicationRecord
  # validates :name,  presence: true,
  #                   length: { minimum: 3 }
  validates :name, presence: true, length: { minimum: 3 }, uniqueness: true
  validates :term, presence: false
  validates :course_organization, presence: true, length: { minimum: 3 }, uniqueness: true
  validates :start_date, presence: false
  validates :end_date, presence: false
  validate :check_course_org_exists
  has_many :roster_students, dependent: :destroy
  has_many :informed_consents, dependent: :destroy
  has_many :completed_jobs, dependent: :destroy
  has_many :github_repos, dependent: :destroy, class_name: '::GithubRepo'
  has_many :org_teams, dependent: :destroy
  has_one :slack_workspace, dependent: :destroy
  has_one :org_webhook, dependent: :destroy
  has_many :org_webhook_events, dependent: :destroy
  has_many :project_teams
  belongs_to :school, optional: true

  after_save :update_org_webhook, if: :will_save_change_to_github_webhooks_enabled?
  before_destroy :remove_webhook_from_course_org

  resourcify

  def org
    return @org if @org or @no_org
    begin
      @org = github_machine_user.organization(course_organization)
    rescue Octokit::NotFound
      @no_org = true
      @org = nil
    end
  end

  def student_for_uid(uid)
    RosterStudent.where(course_id: self.id).includes(:user).references(:user).merge(User.where(uid: uid.to_s)).first
  end

  def student_for_github_username(username)
    RosterStudent.where(course_id: self.id).includes(:user).references(:user).merge(User.where(username: username)).first
  end

  def accept_invite_to_course_org
    github_machine_user.update_organization_membership(course_organization, { state: "active" })
  end

  def invite_user_to_course_org(user)
    unless github_machine_user.organization_member?(course_organization, user.username)
      github_machine_user.update_organization_membership(course_organization, { user: "#{user.username}", role: "member" })
    end
  end

  def update_org_webhook
    if github_webhooks_enabled
      add_webhook_to_course_org
    else
      remove_webhook_from_course_org
    end
  end

  def add_webhook_to_course_org
    # Register course webhook
    begin
      response = github_machine_user.create_org_hook(course_organization, {
        :url => Rails.application.routes.url_helpers.course_github_webhooks_url(self),
        :content_type => "json",
        :secret => ENV["GITHUB_WEBHOOK_SECRET"],
      }, {
        :events => %w[repository member team membership organization issues pull_request project_column
                      issue_comment pull_request_review_comment push],
        :active => true,
      })
      OrgWebhook.create(hook_id: response.id, hook_url: response.url, course: self)
    rescue Octokit::Error => e
      self.github_webhooks_enabled = false
      error = "Failed to add webhook to course organization."
      if ENV["DEBUG_VERBOSE"] && ENV["DEBUG_VERBOSE"] == 1
        error += e.to_s
      end
      puts e
      errors.add(:base, error)
    end
  end

  def remove_webhook_from_course_org
    begin
      return if org_webhook.nil?
      github_machine_user.remove_org_hook(course_organization, org_webhook.hook_id)
      org_webhook.destroy
    rescue Octokit::Error => e
      error = "Failed to remove webhook from course organization."
      if ENV["DEBUG_VERBOSE"] && ENV["DEBUG_VERBOSE"] == 1
        error += e.to_s
      end
      puts e
      errors.add(:base, error)
    end
  end

  def check_course_org_exists
    # NOTE: this is run as a validation step on creation and update for the organization
    if org
      begin
        membership = github_machine_user.organization_membership(course_organization)
        unless membership.role == "admin"
          errors.add(:base, "You must add #{ENV["MACHINE_USER_NAME"]} to your organization before you can proceed.")
        end
      rescue Octokit::NotFound
        errors.add(:base, "You must add #{ENV["MACHINE_USER_NAME"]} to your organization before you can proceed.")
      end
    else
      errors.add(:base, "You must create a github organization with the name of your class and add #{ENV["MACHINE_USER_NAME"]} as an owner of that organization.")
    end
  end

  def users
    return (self.roster_students.map { |student| student.user }).compact
  end


  # import roster students from a roster file provided by gradescope
  def import_students(file, header_map, header_row_exists)
    ext = File.extname(file.original_filename)
    spreadsheet = Roo::Spreadsheet.open(file, extension: ext)

    # get index for each param
    id_index = header_map.index("student_id")
    email_index = header_map.index("email")
    first_name_index = header_map.index("first_name")
    last_name_index = header_map.index("last_name")
    full_name_index = header_map.index("full_name")
    section_index = header_map.index("section")
    github_username_index = header_map.index("github_username")

    unenroll_all_students

    # start at row 1 if header row exists (via checkbox)
    ((header_row_exists ? 2 : 1)..spreadsheet.last_row).each do |i|
      spreadsheet_row = spreadsheet.row(i)

      row = {} # build dynamically based on choices

      row["student_id"] = spreadsheet_row[id_index]
      row["email"] = spreadsheet_row[email_index]
      row["section"] = spreadsheet_row[section_index] unless section_index.nil?

      if first_name_index
        row["first_name"] = spreadsheet_row[first_name_index]
        row["last_name"] = spreadsheet_row[last_name_index]
      else
        name_arr = spreadsheet_row[full_name_index].split(" ") # this seems prone to bugs because last names are weird
        row["first_name"] = name_arr[0]
        row["last_name"] = name_arr[1]
      end

      next if row.values.all?(&:nil?) # skip empty rows

      # check if there is an existing student in the course or create a new one
      student = roster_students.find_by(perm: row["student_id"]) || roster_students.new

      if github_username_index
        github_username = spreadsheet_row[github_username_index]
        if github_username
          user = User.where(username: github_username).first || create_user(github_username,row["email"])
          student.user = user unless user.nil?
        end
      end

      student.enrolled = true
      # We're changing the outward references to student id, but not renaming the perm column for now
      student.perm = row["student_id"]
      student.first_name = row["first_name"]
      student.last_name = row["last_name"]
      student.email = row["email"]
      student.section = row["section"] unless section_index.nil?
      student.save
    end
  end

  def create_user(github_username, email)
    github_user = github_user_lookup(github_username)
    return nil unless github_user 
    User.create(
          provider: ENV['OMNIAUTH_STRATEGY'],
          uid: github_user.data.user.databaseId,
          email: email,
          name: github_user.data.user.name,
          username: github_user.data.user.login,
          password: Devise.friendly_token[0,20],
    )
  end

  def unenroll_all_students
    self.roster_students.each do |student|
      student.enrolled = false
      student.save
    end
  end

  def import_informed_consents(file, header_map, header_row_exists)
    ext = File.extname(file.original_filename)
    spreadsheet = Roo::Spreadsheet.open(file, extension: ext)

    # get index for each param
    id_index = header_map.index("student_id")
    name_index = header_map.index("name")
    student_consents_index = header_map.index("student_consents")

    delete_all_existing_informed_consents

    # start at row 1 if header row exists (via checkbox)
    ((header_row_exists ? 2 : 1)..spreadsheet.last_row).each do |i|
      spreadsheet_row = spreadsheet.row(i)

      row = {} # build dynamically based on choices

      row["student_id"] = spreadsheet_row[id_index]
      row["name"] = spreadsheet_row[name_index]
      row["student_consents"] = spreadsheet_row[student_consents_index] unless student_consents_index.nil?

      next if row.values.all?(&:nil?) # skip empty rows

      informed_consent = informed_consents.find_by(perm: row["student_id"]) || informed_consents.new

      informed_consent.perm = row["student_id"]
      informed_consent.name = row["name"]
      informed_consent.student_consents = student_consents_index.nil? ? true : row["student_consents"] 
      
      informed_consent.roster_student = roster_students.where(perm: informed_consent.perm).first

      informed_consent.save
    end
  end

  def delete_all_existing_informed_consents
    self.informed_consents.map(&:destroy)
  end

  def commit_csv_export_headers
    GithubRepo.commit_csv_export_headers
  end

  def commit_csv_export_fields(repo,c)
    GithubRepo.commit_csv_export_fields(repo,c)
  end

  def commits
     github_repos.map{ |repo| repo.repo_commit_events }.flatten(1)
  end

  def export_commits_to_csv
    CSV.generate(headers: true) do |csv|
      csv << commit_csv_export_headers
      github_repos.each do |repo|
        repo.repo_commit_events.each do |c|
          csv << commit_csv_export_fields(repo,c)
        end
      end
    end
  end

  def issue_csv_export_headers
    GithubRepo.issue_csv_export_headers
  end

  def issue_csv_export_fields(repo,c)
    GithubRepo.issue_csv_export_fields(repo,c)
  end

  def export_issues_to_csv
    CSV.generate(headers: true) do |csv|
      csv << issue_csv_export_headers
      github_repos.each do |repo|
        repo.repo_issue_events.each do |c|
          csv << issue_csv_export_fields(repo,c)
        end
      end
    end
  end
  
  def student_csv_export_headers
    %w[
      student_id 
      email 
      first_name 
      last_name 
      enrolled 
      section 
      github_username 
      slack_uid 
      slack_username 
      slack_display_name 
      org_status teams
    ]
  end


  def student_csv_export_fields(user)
    org_member_status = user.org_membership_type || user.is_org_member

    slack_uid = user.slack_user.nil? ? nil : user.slack_user.uid
    slack_username = user.slack_user.nil? ? nil : user.slack_user.username
    slack_display_name = user.slack_user.nil? ? nil : user.slack_user.display_name

    [
      user.perm,
      user.email,
      user.first_name,
      user.last_name,
      user.enrolled,
      user.section,
      user.username,
      slack_uid,
      slack_username,
      slack_display_name,
      org_member_status,
      user.teams_string,
    ]
  end

  def export_students_to_csv
    CSV.generate(headers: true) do |csv|
      csv << student_csv_export_headers
      roster_students.each do |user|
        csv << student_csv_export_fields(user)
      end
    end
  end

  def export_students_to_json
    result = []
    roster_students.each do |user|
      org_member_status = user.org_membership_type || user.is_org_member

      slack_uid = user.slack_user.nil? ? nil : user.slack_user.uid
      slack_username = user.slack_user.nil? ? nil : user.slack_user.username
      slack_display_name = user.slack_user.nil? ? nil : user.slack_user.display_name

      result << {
        "perm" => user.perm,
        "email" => user.email,
        "first_name" => user.first_name,
        "last_name" => user.last_name,
        "enrolled" => user.enrolled,
        "section" => user.section,
        "username" => user.username,
        "slack_uid" => slack_uid,
        "slack_username" => slack_username,
        "slack_display_name" => slack_display_name,
        "org_member_status" => org_member_status,
        "teams" => user.teams_string,
      }
    end
    result.to_json
  end


  def github_user_lookup(github_username) 
    response = github_machine_user.post '/graphql', 
               { query: github_user_graphql_query(github_username) }.to_json
    if !response.respond_to?(:data) || response.respond_to?(:errors)
      return nil
    end   
    response       
  end

  def github_user_graphql_query(github_username)
    <<-GRAPHQL
    query { 
      user (login: "#{github_username}") { 
        login
        name
        databaseId
      }
    }
    GRAPHQL
  end
  
  def self.all_course_names
      Course.all.map{|c| c.name}
  end
end

