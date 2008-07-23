class Application < Merb::Controller
  def link_to(name, url='', opts={})
    opts[:href] ||= url
    %{<a #{ opts.to_xml_attributes }>#{name}</a>}
  end
end