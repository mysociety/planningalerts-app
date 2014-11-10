class AuthorityStatsSummary < ActiveRecord::Base
  def self.overview
    AuthorityStatsSummary.where(:category => nil).first
  end

  def self.overview_json
    {
      :percentage_approved => overview.percentage_approved,
      :percentage_refused => overview.percentage_refused,
      :percentage_current => overview.percentage_pending
    }
  end

  def self.category(name)
    AuthorityStatsSummary.where(:category => name).first
  end

  def method_missing(name,*args,&block)
    if name =~ /^percentage_(.*)$/ and attributes.include?($1) and eval("self.#{$1}").is_a?(Numeric)
      return calculate_percentage($1)
    else
      super
    end
  end

  protected

  def calculate_percentage(attribute)
    if self.total == 0
      return nil
    else
      return (eval("self.#{attribute}").to_f / self.total * 100.0).round
    end
  end
end