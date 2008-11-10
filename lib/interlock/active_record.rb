
module ActiveRecord #:nodoc:
  class Base

    @@nil_sentinel = :_nil

    #
    # Convert this record to a tag string.
    #
    def to_interlock_tag
      "#{self.class.name}-#{self.id}".escape_tag_fragment
    end        

    #
    # The expiry callback.
    #
    def expire_interlock_keys
      return if Interlock.config[:disabled] or (defined? CGI::Session::ActiveRecordStore and is_a? CGI::Session::ActiveRecordStore::Session)

      # Fragments
      (CACHE.get(Interlock.dependency_key(self.class.base_class)) || {}).each do |key, scope|
        if scope == :all or (scope == :id and key.field(4) == self.to_param.to_s)
          Interlock.say key, "invalidated by rule #{self.class} -> #{scope.inspect}."
          Interlock.invalidate key
        end
      end
      
      # Models
      if Interlock.config[:with_finders]
        Interlock.invalidate(self.class.base_class.caching_key(self.id))
      end
    end
    
    before_save :expire_interlock_keys
    after_destroy :expire_interlock_keys

    #
    # Reload. Expires the cache and force reload from db.
    #
    def reload_with_interlock(options)
      self.expire_interlock_keys
      reload_without_interlock(options)
    end
    alias_method_chain :reload, :interlock
            
  end
end
