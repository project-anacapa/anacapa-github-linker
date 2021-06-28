module Api
  class CoursesController < ApplicationController
    respond_to :json
    load_and_authorize_resource
    include Response

    def graphql
      puts("graphql")
      @course = Course.find(params[:course_id])
      query = params[:query]
      accept = params[:accept]
      results = perform_graphql_query(query,accept)
      json_response(results.to_hash)
    end

    def commits
      @course = Course.find(params[:course_id])
      json_response(@course.commits)
    end
    
    private


    def perform_graphql_query(graphql_query_string, accept)
      puts("perform graphqlquery")
      data = {
          :query => graphql_query_string
      }.to_json
      options = accept ?  {
          :headers => {
          :accept => accept
          }
        } : {}
      result = github_machine_user.send :request, :post, '/graphql', data, options
      puts("result=#{result.to_hash.to_s}")
      result
    end

    def github_machine_user
      Octokit_Wrapper::Octokit_Wrapper.machine_user
    end

    respond_to :json
    load_and_authorize_resource

    def index
    end

  end
end
