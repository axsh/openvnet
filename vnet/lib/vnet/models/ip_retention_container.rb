module Vnet::Models
  class IpRetentionContainer < Base
    taggable 'irc'

    one_to_many :ip_retentions

    def validate
      super
      errors.add(:lease_time, 'cannot be less than 0') if grace_time && grace_time < 0
      errors.add(:grace_time, 'cannot be less than 0') if grace_time && grace_time < 0
    end
  end
end
