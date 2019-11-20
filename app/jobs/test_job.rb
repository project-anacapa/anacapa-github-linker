class TestJob < CourseJob

  @job_name = "Test Job"

  def perform(course_id)
    CompletedJob.create(job_name: "Test Job", summary: "Test completed.",
                        course_id: course_id)
  end
end
