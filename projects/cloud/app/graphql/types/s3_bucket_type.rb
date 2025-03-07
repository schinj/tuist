# frozen_string_literal: true

module Types
  class S3BucketType < Types::BaseObject
    field :name, String, null: false
    field :access_key_id, String, null: false
    field :secret_access_key, String, null: true
  end
end
