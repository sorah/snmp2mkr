require 'mackerel/client'

module Mackerel
  class Client
    def put_host(host_id, host)
      response = client.put "/api/v0/hosts/#{host_id}" do |req|
        req.headers['X-Api-Key'] = @api_key
        req.headers['Content-Type'] = 'application/json'
        req.body = host.to_json
      end

      unless response.success?
        raise "POST /api/v0/hosts/#{host_id} failed: #{response.status}"
      end

      data = JSON.parse(response.body)
    end
  end
end
