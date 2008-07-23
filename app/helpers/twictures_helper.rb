module Merb
    module TwicturesHelper
      def embed_html(twicture)
        snippet = <<-SNIP
<div>
<p><img src="http://twictur.es/images/#{twicture.image_path}" /></p>
<p>image provided by #{link_to "Twictur.es", 'http://twictur.es'}</p>
</div>
        SNIP
        tag :textarea, snippet
      end

    end
end