module ActionDispatch::Routing
  module BulkHelpers
    def bulk_routes(path)
      get    path => "bulk/api#get"
      post   path => "bulk/api#create"
      put    path => "bulk/api#update"
      delete path => "bulk/api#delete"
    end
  end

  class Mapper
    include BulkHelpers
  end
end
