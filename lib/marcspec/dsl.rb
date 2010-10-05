module MARCSpec
  # Here's where we put a simple DSL hook for SpecSet
  
  def self.build (&blk)
    ss = SpecSet.new
    ss.instance_eval(&blk)
    return ss
  end
  
  # Re-open SpecSet to add the necessary methods
  
  class SpecSet    
    
    # create a normal field
    def field(name, &blk)
      log.debug "Creating regular field #{name}"
      sfs = SolrFieldSpec.new(:solrField=>name)
      sfs.instance_eval(&blk)
      self << sfs
      return sfs
    end
    
    # Create a constant field
    def constant(name, &blk)
      log.debug "Creating constant field #{name}"
      
      constant = ConstantSolrSpec.new(:solrField=>name)
      constant.instance_eval(&blk)
      self << constant
      return constant
    end
    
    def custom(name, &blk)
      log.debug "Creating custom field #{name}"
      custom = CustomSolrSpec.new(:solrField=>name)
      custom.instance_eval(&blk)
      
      ##### Check to make sure it's all ok in here#####
      self << custom
      return custom
    end
    
  end
  
  
  class SolrFieldSpec
    def spec(tag, &blk)
      
      subs = nil
      if tag =~ /^(...)(.+)$/
        tag = $1
        subs = $2
      end
      
      if tag.to_i == tag
        tag = '%03d' % tag
      end
      
      marcfieldspec = nil
      
      if tag == 'LDR'
        marcfieldspec = MARCSpec::LeaderSpec.new('LDR')
      elsif MARC4J4R::ControlField.control_tag? tag
        marcfieldspec = MARCSpec::ControlFieldSpec.new(tag)
      else
        marcfieldspec = MARCSpec::VariableFieldSpec.new(tag)
      end
      
      # Did we get subs? If so, add them now.
      if subs
        marcfieldspec.codes = subs
      end
      
      marcfieldspec.instance_eval(&blk) if block_given?
      
      # If we had multiple sub calls, get them from the codehistory
      if marcfieldspec.is_a? MARCSpec::VariableFieldSpec
        marcfieldspec.codehistory.uniq.compact.each do |c|
          newmfs = marcfieldspec.clone
          newmfs.codes = c
          self << newmfs
        end
      end
      
      if marcfieldspec.is_a? MARCSpec::ControlFieldSpec
        marcfieldspec.rangehistory.uniq.compact.each do |r|
          newcfs = marcfieldspec.clone
          newcfs.range = r
          self << newcfs
        end
      end
      
      self << marcfieldspec
      return marcfieldspec
    end
    
    def firstOnly val=true
      @first = val
    end
    
    def default val
      @defaultValue = val
    end
    
    def mapname str
      @_mapname = str
    end
    
    def mapMissDefault str
      @noMapKeyDefault = str
    end
    
  end
  
  class ControlFieldSpec
    def char c
      self.range = c
      return self
    end
    
    alias_method :chars, :char
  end
  
  class VariableFieldSpec
    def sub c
      self.codes = c
      return self
    end
    
    alias_method :subs, :sub
  end
    
  
  class CustomSolrSpec
    def function(name, &blk)
      self.functionSymbol = name.to_sym
      self.instance_eval(&blk)
    end
    
    def mod(constant)
      self.module = constant
    end
    
    def args(*arg_or_args)
      self.functionArgs = arg_or_args
    end
  end
  
  class ConstantSolrSpec
    def value(val)
      self.constantValue = val
    end
  end
end