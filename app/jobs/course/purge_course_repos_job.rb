class PurgeCourseReposJob < CourseJob

  @job_name = "Purge Course GitHub Repo Records"
  @job_short_name = "purge_course_repos"
  @job_description = "Removes all cached records of this course organization's GitHub repos from the database."

  def attempt_job
    destroyed_repos = GithubRepo.where(:course_id => @course.id).destroy_all
    "Purged #{destroyed_repos.size} records from the database."
  end
end