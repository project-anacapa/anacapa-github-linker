class GithubRepo < ApplicationRecord
  belongs_to :course
  has_many :repo_contributors
  has_many :users, through: :repo_contributors
  has_many :repo_team_contributors, dependent: :destroy
  has_many :org_teams, through: :repo_team_contributors
  has_many :org_webhook_events
  has_many :repo_commit_events
  has_many :repo_issue_events

  # Note: most (if not all) of the GitHub-related objects store a unique identifier for that object assigned by GitHub.
  # These are, by our convention, something like #repo_id, #hook_id, #team_id, etc.
  # For all but repositories and users (uid), we use the "node_id" string provided by GitHub to fill this field. HOWEVER, for repositories (repo_id),
  # because GitHub sometimes omits the node_id for repos, we use the GitHub "id" integer (in GraphQL responses, this is called the "databaseId").

  def find_contributors
    # This query gets certain information about a student, their user, and relationship to the repository in question.
    # It is written in raw SQL because it would take several queries using Rails syntax.
    query = <<-SQL
        SELECT rs.first_name, rs.last_name, rs.id, u.username, rc.permission_level
        FROM users u
          JOIN roster_students rs ON (u.id = rs.user_id and #{self.course_id} = rs.course_id)
          JOIN repo_contributors rc ON u.id = rc.user_id
        WHERE #{self.id} = rc.github_repo_id
    SQL
    ActiveRecord::Base.connection.exec_query(query)
  end

  def find_team_contributors
    query = <<-SQL
      SELECT t.name, t.id, t.url, t.slug, rtc.permission_level
      FROM org_teams t
        JOIN repo_team_contributors rtc ON t.id = rtc.org_team_id
      WHERE #{self.id} = rtc.github_repo_id
    SQL
    ActiveRecord::Base.connection.exec_query(query)
  end

  def self.commit_csv_export_headers
    %w[
      github_repo_name
      github_repo_url
      roster_student_id
      roster_student_name
      roster_student_github_id
      message
      commit_hash
      url
      branch
      files_changed
      commit_timestamp
      filenames_changed
      committed_via_web
    ]
  end

  # self.method so it can be reused in course.rb
  def self.commit_csv_export_fields(repo,c)
    [
      repo.name,
      repo.url,
      c.roster_student_id,
      c.roster_student&.full_name,
      c.roster_student&.user_id,
      c.message,
      c.commit_hash,
      c.url,
      c.branch,
      c.files_changed,
      c.commit_timestamp,
      c.filenames_changed,
      c.committed_via_web,
    ]
  end

  # self.method so it can be reused in course.rb
  def self.issue_csv_export_headers
    %w[
      github_repo_name
      github_repo_url
      url
      title
      state
      closed
      closed_at
      assignee_count
      assignee_logins
      assignee_names
      project_card_count
      project_column_names
      project_names
      project_urls
      checklist_items,
      checked,
      unchecked,
      roster_student_id
      roster_student_name
      roster_student_github_id
    ]
  end


  def self.issue_csv_export_fields(repo,i)
    [
      repo.name,
      repo.url,
      i.url,
      i.title,
      i.state,
      i.closed,
      i.closed_at,
      i.assignee_count,
      i.assignee_logins,
      i.assignee_names,
      i.project_card_count,
      i.project_card_column_names,
      i.project_card_column_project_names,
      i.project_card_column_project_urls,
      self.checklist_item_count(i.body),
      self.checklist_item_checked_count(i.body),
      self.checklist_item_unchecked_count(i.body),
      i.roster_student_id,
      i.roster_student&.full_name,
      i.roster_student&.user_id,
    ]
  end

  def export_commits_to_csv
    CSV.generate(headers: true) do |csv|
      csv << GithubRepo.commit_csv_export_headers
      repo_commit_events.each do |c|
        csv << GithubRepo.commit_csv_export_fields(self,c)
      end
    end
  end

  def export_issues_to_csv
    CSV.generate(headers: true) do |csv|
      csv << GithubRepo.issue_csv_export_headers
      repo_issue_events.each do |c|
        csv << GithubRepo.issue_csv_export_fields(self,c)
      end
    end
  end

  def self.checklist_item_count(body) 
    # both checked and unchecked
    body.scan(/\r\n- \[[ x]\]/).count
  end

  def self.checklist_item_checked_count(body) 
    # both checked and unchecked
    body.scan(/\r\n- \[x\]/).count
  end

  def self.checklist_item_unchecked_count(body) 
    # both checked and unchecked
    body.scan(/\r\n- \[ \]/).count
  end
  
end
