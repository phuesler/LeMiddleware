require 'couchrest'
require 'json'

module Rack
  class CouchLogger

    def initialize(app, db=nil)
      @app = app
      @db = db
    end

    def call(env)
      log = {}
      log['started_at'] = Time.now
      log['url'] = env['REQUEST_URI']
      log['request_body'] = env["rack.input"].read
      # rewind the input string so sinatra can find it
      env["rack.input"].rewind
      log['env'] = env
      begin
        response = @app.call(env)
      rescue Exception => raised
        log['error_message'] = raised.message
        log['stacktrace'] = raised.backtrace.join('\n')
       # let's report the log in a different thread so we don't slow down the app
        @db ? Thread.new(@db, log){|db, rlog| db.save_doc(rlog);} : p(log.inspect)
        raise
      end
      log['response_status'] = response[0]
      log['response_content_type'] = response[1]
      log['response_body'] = response[2].join
       # let's report the log in a different thread so we don't slow down the app
      @db ? Thread.new(@db, log){|db, rlog| db.save_doc(rlog);} : p(log.inspect)
      response
    end
  end
end
