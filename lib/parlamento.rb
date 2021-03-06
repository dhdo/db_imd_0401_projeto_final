require_relative '../setup'

class Parlamento
  BASE_URL = "https://dadosabertos.camara.leg.br/api/v2/%s?itens=100".freeze

  def deputados
    @deputados ||= fetch_from_file_or_api('deputados')
  end

  def legislaturas
    @legislaturas ||= fetch_from_file_or_api('legislaturas')
  end

  def tipos_proposicao
    @tipos_proposicao ||= fetch_from_file_or_api('referencias/tiposProposicao')
  end

  def blocos
    @blocos ||= fetch_from_file_or_api('blocos')
  end

  def detalhes_deputados
    if File.exist?(file_path('detalhes_deputados'))
      JSON.parse(File.read(file_path('detalhes_deputados')))
    else
      results = deputados.map do |d|
        deputado(d['id']) if d.is_a? Hash
      end.compact

      File.open(file_path('detalhes_deputados'), 'w+') do |file|
        file.write(results.to_json)
      end

      results
    end
  end

  def deputado(id)
    fetch_from_file_or_api("deputados/#{id}")
  end

  private

  def fetch_from_file_or_api(resource, filename = file_path(resource))
    if File.exist?(filename)
      JSON.parse(File.read(filename))
    else
      fetch_and_save(resource, filename)
    end
  end

  def file_path(resource)
    File.join(__dir__, '..', 'data', "#{resource}.json")
  end

  def fetch_and_save(resource, filename = file_path(resource))
    results = fetch(resource)

    File.open(filename, 'w+') do |file|
      file.write(results.to_json)
    end

    results
  end

  def fetch(resource)
    page = get(format(BASE_URL, resource))
    results = page['dados']

    while page['links'] && next_url = page['links'].find { |x| x['rel'] == 'next' } do
      sleep 3
      page = get(next_url['href'])
      results << page['dados']
    end

    results
  end

  def get(url, params={})
    puts "******* GET #{url} *****"
    response = RestClient.get(url, params: params, headers: { content_type: :json, accept: :json })
    JSON.parse(response)
  end
end
