module ActionDispatch::Routing
  module SproutcoreHelpers
    def sproutcore(path)
      get    path => "sproutcore/bulk#get"
      post   path => "sproutcore/bulk#create"
      put    path => "sproutcore/bulk#update"
      delete path => "sproutcore/bulk#delete"
    end
  end

  class Mapper
    include SproutcoreHelpers
  end
end
