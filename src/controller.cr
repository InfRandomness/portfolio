module Portfolio
  class RoutingControllers < ATH::Controller
    @[ARTA::Get("/")]
    def index : String
      "Hello, World"
    end
  end
end
