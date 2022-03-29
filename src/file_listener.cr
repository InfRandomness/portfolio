module Portfolio::Listeners
  @[ADI::Register]
  struct StaticFile
    include AED::EventListenerInterface
    private PUBLIC_DIR = Path.new("public").expand

    def self.subscribed_events : AED::SubscribedEvents
      AED::SubscribedEvents{ATH::Events::Request => 256}
    end

    def call(event : ATH::Events::Request, _dispatche r : AED::EventDispatcherInterface) : Nil
      return unless event.request.method.in? "GET", "HEAD"

      original_path = event.request.path
      request_path = URI.decode original_path

      if request_path.includes? '\0'
        raise ATH::Exceptions::BadRequest.new "File path cannot contain NUL bytes."
      end

      request_path = Path.posix request_path
      expanded_path = request_path.expand "/"

      file_path = PUBLIC_DIR.join expanded_path.to_kind Path::Kind.native

      is_dir = Dir.exists? file_path
      is_dir_path = original_path.ends_with? '/'

      event.response = if request_path != expanded_path || is_dir && !is_dir_path
                         redirect_path = expanded_path
                         if is_dir && !is_dir_path
                           redirect_path = expanded_path.join ""
                         end

                         # Request is a directory but acting as a file,
                         # redirect to the actual directory URL.
                         ATH::RedirectResponse.new redirect_path
                       elsif File.file? file_path
                         ATH::BinaryFileResponse.new file_path
                       else
                         # Nothing to do.
                         return
                       end
    end
  end
end
