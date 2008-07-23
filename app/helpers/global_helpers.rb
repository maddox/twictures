module Merb
  module GlobalHelpers
    # helpers defined here available to all views.  
    def link_to(name, url='', opts={})
      opts[:href] ||= url
      %{<a #{ opts.to_xml_attributes }>#{name}</a>}
    end
    
    def embed_html(twicture)
      snippet = <<-SNIP
<div>
<p><img src="http://twictur.es/images/#{twicture.image_path}" /></p>
<p>image provided by #{link_to "twictur.es", 'http://twictur.es'} | original tweet #{link_to "here", twicture.twitter_url}</p>
</div>
      SNIP
      tag :textarea, snippet
    end

    def form_html
      <<-html
<form action="/new" method="post">
<label for="twicture_twitter_url">Tweet URL</label>
<input type="text" class="text" name="twicture[twitter_url]" value="" id="twicture_twitter_url"/>
<button type="submit">Twicturlate</button>
</form>
      html
    end
  end
end
