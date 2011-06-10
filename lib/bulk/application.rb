require 'rack'

module Bulk

  MethodMap = {
    :get    => :get,
    :post   => :create,
    :put    => :update,
    :delete => :delete
  }.freeze

  class Application
    def call(env)
      request  = Rack::Request.new(env)
      response = Rack::Response.new

      method = request.request_method.downcase.to_sym

      if action = MethodMap[method] 
        options = Bulk::Resource.send(action, request)
        yield options if block_given?

        response.status = options[:status] || 200
        response.write options[:json].to_json
      else
        # Method not allowed.
        response.status = 405
      end

      response.header['Content-Type'] = 'application/json'

      response.finish
    end
  end

end
