require 'marcspec/controlfieldspec'

module MARCSpec
  # A LeaderSpec deals only with the leader. It's basically the same as a controlfield spec, but
  # using the string 'LDR' to identify itself
  
  class LeaderSpec < ControlFieldSpec
    
    # Built to be syntax-compatible with ControlFieldSpec, the tag must always
    # be 'LDR' (case matters)
    #
    # @param ['LDR'] tag The 'tag'; in this case, always 'LDR'
    # @param [Fixnum, Range<Fixnum>] range substring specification (either one character or a range) to return
    # instead of the whole leader.
    
    def initialize (tag, range=nil)
      unless tag == 'LDR'
        raise ArgumentError, "Tag must be 'LDR' for a LeaderSpec"
      end
      @tag = 'LDR'
      self.range = range
    end
    
    # Return the appropriate value (either the leader or a subset of it) from the
    # given record
    #
    # @param [MARC4J4R::Record] r A MARC4J4R Record
    # @return [String] the leader or substring of the leader
    def marc_values r
      if @range
        return r.leader[@range]
      else
        return r.leader
      end
    end
  end    
end