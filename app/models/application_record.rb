class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.github_machine_user
    Octokit_Wrapper::Octokit_Wrapper.machine_user
  end

  def github_machine_user
    ApplicationRecord.github_machine_user
  end
end
