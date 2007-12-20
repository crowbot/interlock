
module ActionView #:nodoc:
  module Helpers #:nodoc:
    module CacheHelper 
     
=begin rdoc     

<tt>view_cache</tt> marks a corresponding view block for caching. It accepts <tt>:tag</tt> and <tt>:ignore</tt> keys for explicit scoping, as well as a <tt>:ttl</tt> key and a <tt>:perform</tt> key. 

You can specify dependencies in <tt>view_cache</tt> if you really want to. 

== TTL

Use the <tt>:ttl</tt> key to specify a maximum time-to-live, in seconds:

  <% view_cache :ttl => 5.minutes do %>
  <% end %>

Note that the cache is not guaranteed to persist this long. An invalidation rule could trigger first, or memcached could eject the item early due to the LRU.

== View caching without action caching

It's fine to use a <tt>view_cache</tt> block without a <tt>behavior_cache</tt> block. For example, to mimic regular fragment cache behavior, but take advantage of memcached's <tt>:ttl</tt> support, call:

  <% view_cache nil, :ignore => :all, :tag => 'sidebar', :ttl => 5.minutes %>
  <% end %> 
  
Remember that <tt>nil</tt> disables invalidation rules. This is a nice trick for keeping your caching strategy unified.

== Dependencies, scoping, and other options

See ActionController::Base for explanations of the rest of the options. The <tt>view_cache</tt> and <tt>behavior_cache</tt> APIs are identical except for setting the <tt>:ttl</tt>, which can only be done in the view.

=end     
     def view_cache(*args, &block)
       conventional_class = begin; controller.controller_name.classify.constantize; rescue NameError; end
       options, dependencies = Interlock.extract_options_and_dependencies(args, conventional_class)  
       
       key = controller.caching_key(options.value_for_indifferent_key(:ignore), options.value_for_indifferent_key(:tag))      
       Interlock.register_dependencies(dependencies, key)
       
       # Interlock.say key "is rendering"
       unless options[:perform] == false
         @controller.cache_erb_fragment(
           block, 
           key, 
           :ttl => (options.value_for_indifferent_key(:ttl) or Interlock.config[:ttl])
         )
       else
         block.call
       end
     end
     
    #:stopdoc:
    alias :caching :view_cache # Deprecated
    #:startdoc:
     
    end
  end
end
