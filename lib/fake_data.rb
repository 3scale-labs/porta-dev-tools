# frozen_string_literal: true

require_relative 'api'
require 'logger'
require 'pry'

begin
  logger = Logger.new(STDOUT)

  api_endpoint = ENV.fetch('API_ENDPOINT', 'http://provider-admin.3scale.localhost:3000')
  access_token = ENV.fetch('ACCESS_TOKEN', 'secret')
  api = Api.new(endpoint: "#{api_endpoint}/admin/api", access_token: access_token, logger: logger)

  # Rename the API product to "Talker"
  talker_api = api.get('services.json')['services'].first['service']
  api.put("services/#{talker_api['id']}.json", name: 'Talker')

  # Remove catch-all mapping rule from the API product
  catch_all_mapping_rule = api.get("services/#{talker_api['id']}/proxy/mapping_rules.json")['mapping_rules'].first&.fetch('mapping_rule')
  api.delete("services/#{talker_api['id']}/proxy/mapping_rules/#{catch_all_mapping_rule['id']}.json") if catch_all_mapping_rule

  # [Echo API] Turn default Backend API into the Echo API, with 3 mapping rules and mounted at '/echo'
  echo_api = api.get('backend_apis.json')['backend_apis'].first['backend_api']
  api.put("backend_apis/#{echo_api['id']}.json", name: 'Echo API', private_endpoint: 'https://echo-api.3scale.net:443')
  echo_api_hits_metric = api.get("backend_apis/#{echo_api['id']}/metrics.json")['metrics'].first['metric']
  %w[/hello /say/{something} /bye].each do |pattern|
    api.post("backend_apis/#{echo_api['id']}/mapping_rules.json", http_method: 'GET', pattern: pattern, metric_id: echo_api_hits_metric['id'], delta: 1)
  end
  echo_api_usage = api.get("services/#{talker_api['id']}/backend_usages.json").first['backend_usage']
  api.put("services/#{talker_api['id']}/backend_usages/#{echo_api_usage['id']}.json", path: '/echo')

  # [Quotes API] Define the Backend API Quotes API, with 1 mapping rule (GET /qod) and mounted at '/quotes'
  quotes_api = api.post('backend_apis.json', name: 'Quotes API', private_endpoint: 'https://quotes.rest:443')['backend_api']
  quotes_api_hits_metric = api.get("backend_apis/#{quotes_api['id']}/metrics.json")['metrics'].first['metric']
  api.post("backend_apis/#{quotes_api['id']}/mapping_rules.json", http_method: 'GET', pattern: '/qod', metric_id: quotes_api_hits_metric['id'], delta: 1)
  api.post("services/#{talker_api['id']}/backend_usages.json", backend_api_id: quotes_api['id'], path: '/quotes')

  # [Ipsum Lorem API] Define the Backend API Ipsum Lorem API, with the catch-all mapping rule and mounted at '/bs'
  ipsum_api = api.post('backend_apis.json', name: 'Ipsum Lorem API', private_endpoint: 'https://randommer.io:443/api/Text/LoremIpsum')['backend_api']
  ipsum_api_hits_metric = api.get("backend_apis/#{ipsum_api['id']}/metrics.json")['metrics'].first['metric']
  api.post("backend_apis/#{ipsum_api['id']}/mapping_rules.json", http_method: 'GET', pattern: '/', metric_id: ipsum_api_hits_metric['id'], delta: 1)
  api.post("services/#{talker_api['id']}/backend_usages.json", backend_api_id: ipsum_api['id'], path: '/bs')

  # Define a product-level mapping rule GET /bs to support requests without trailing slash
  hits_metric = api.get("services/#{talker_api['id']}/metrics.json")['metrics'].first['metric']
  api.post("services/#{talker_api['id']}/proxy/mapping_rules.json", http_method: 'GET', pattern: '/bs', metric_id: hits_metric['id'], delta: 1)

  # Define policy chain with policies to add default parameters for the Ipsum Lorem API
  policies_config = <<~JSON
  [
      {
          "name": "headers",
          "version": "builtin",
          "configuration": {
              "request": [
                  {
                      "value_type": "plain",
                      "op": "set",
                      "header": "X-Api-Key",
                      "value": "2139d0df317449a1bae887111b26cfd9"
                  }
              ]
          },
          "enabled": true
      },
      {
          "name": "url_rewriting",
          "version": "builtin",
          "configuration": {
              "query_args_commands": [
                  {
                      "value_type": "plain",
                      "op": "set",
                      "arg": "loremType",
                      "value": "normal"
                  },
                  {
                      "value_type": "plain",
                      "op": "set",
                      "arg": "type",
                      "value": "paragraphs"
                  },
                  {
                      "value_type": "plain",
                      "op": "set",
                      "arg": "number",
                      "value": "1"
                  }
              ]
          },
          "enabled": true
      },
      {
          "name": "apicast",
          "version": "builtin",
          "configuration": {},
          "enabled": true
      }
  ]
  JSON
  api.put("/admin/api/services/#{talker_api['id']}/proxy/policies.json", policies_config: policies_config)

  # Deploy the Talker API Product to APIcast staging environment
  api.post("/admin/api/services/#{talker_api['id']}/proxy/deploy.json")

  # Create another API Product: Economy
  economy_api = api.post('services.json', name: 'Economy')['service']

  # Create a paid application plan
  api.post("/admin/api/services/#{economy_api['id']}/application_plans.json", name: 'Enterprise', setup_fee: 100, cost_per_month: 17)

  # Remove catch-all mapping rule from the API product
  catch_all_mapping_rule = api.get("services/#{economy_api['id']}/proxy/mapping_rules.json")['mapping_rules'].first&.fetch('mapping_rule')
  api.delete("services/#{economy_api['id']}/proxy/mapping_rules/#{catch_all_mapping_rule['id']}.json") if catch_all_mapping_rule

  # [DBnomics API] Define the Backend API DBnomics, with a few mapping rules and mounted at '/'
  dbnomics_api = api.post('backend_apis.json', name: 'DBnomics API', private_endpoint: 'https://api.db.nomics.world/v22')['backend_api']
  dbnomics_api_hits_metric = api.get("backend_apis/#{dbnomics_api['id']}/metrics.json")['metrics'].first['metric']
  %w[
    /datasets/{provider_code}
    /datasets/{provider_code}/{dataset_code}
    /last-updates
    /providers
    /providers/{provider_code}
    /search
    /series
    /series/{provider_code}/{dataset_code}
    /series/{provider_code}/{dataset_code}/{series_code}
  ].each do |pattern|
    api.post("backend_apis/#{dbnomics_api['id']}/mapping_rules.json", http_method: 'GET', pattern: pattern, metric_id: dbnomics_api_hits_metric['id'], delta: 1)
  end
  api.post("services/#{economy_api['id']}/backend_usages.json", backend_api_id: dbnomics_api['id'], path: '/')

  # [OCDE API] Define the Backend API OCDE, with a 1 mapping rule and mounted at '/ocde'
  ocde_api = api.post('backend_apis.json', name: 'OCDE Database', private_endpoint: 'http://stats.oecd.org/SDMX-JSON/data')['backend_api']
  ocde_api_hits_metric = api.get("backend_apis/#{ocde_api['id']}/metrics.json")['metrics'].first['metric']
  api.post("backend_apis/#{dbnomics_api['id']}/mapping_rules.json", http_method: 'GET', pattern: '/{dataset}/{filter}/{agency}', metric_id: ocde_api_hits_metric['id'], delta: 1)
  api.post("services/#{economy_api['id']}/backend_usages.json", backend_api_id: ocde_api['id'], path: '/ocde')

  # Deploy the Economy API Product to APIcast staging environment
  api.post("/admin/api/services/#{economy_api['id']}/proxy/deploy.json")

  # Create a member user with access to manage the Economy API only
  member_user = api.post("/admin/api/users.json", username: 'member', email: 'member@provider.example.com', password: 'p')['user']
  api.put("/admin/api/users/#{member_user['id']}/activate.json")
  api.put("/admin/api/users/#{member_user['id']}/member.json")
  api.put("/admin/api/users/#{member_user['id']}/permissions.json", allowed_sections: ['partners', 'monitoring', 'plans', 'policy_registry'], allowed_service_ids: [economy_api['id']])
rescue => exception
  logger.error(exception)
  Pry.start
end
