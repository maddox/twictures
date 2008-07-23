module Merb
  module GlobalHelpers
    # helpers defined here available to all views.  
    def link_to(name, url='', opts={})
      opts[:href] ||= url
      %{<a #{ opts.to_xml_attributes }>#{name}</a>}
    end
  end
end
