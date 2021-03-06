require 'webrick'
require 'erb'
require 'github/markup'

module GfmPreview

  class Server

    def start(path, address, port)
      @server = WEBrick::HTTPServer.new({:BindAddress => address, :Port => port})
      @server.mount_proc('/') do|req, res|
        if req.path =~ /\.(md|markdown)$/
          file_path = path + req.path
          file_name = File.basename(file_path)
          content = GitHub::Markup.render(file_path)
          open(File.join(File.dirname(__FILE__), '..', 'templates', 'markdown.html.erb')) { |file|
            erb = ERB.new(file.read)
            body = erb.result(binding)
            res.body = body
            res.content_type = 'text/html; charset=uft-8'
          }
        elsif req.path =~ /\.txt$/
          file_path = path + req.path
          file_name = File.basename(file_path)
          open(file_path) { |file|
            content = ERB::Util.html_escape(file.read)
            open(File.join(File.dirname(__FILE__), '..', 'templates', 'text.html.erb')) { |file|
              erb = ERB.new(file.read)
              body = erb.result(binding)
              res.body = body
              res.content_type = 'text/html; charset=uft-8'
            }
          }
        elsif req.path =~ /^\/gfm-preview\//
          WEBrick::HTTPServlet::FileHandler.new(@server, File.join(File.dirname(__FILE__), '..', 'public')).service(req, res)
        else
          WEBrick::HTTPServlet::FileHandler.new(@server, path, {:FancyIndexing => true}).service(req, res)
        end
      end
      @server.start
    end

    def shutdown
      @server.shutdown
    end

  end

end
