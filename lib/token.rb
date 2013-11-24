require 'aws-sdk'

class Token
  POLICY_DURATION = 900.freeze
  TABLE_PREFIX = 'c_'.freeze

  def self.get_token twitter_handles
    table_name = self.get_table_name(twitter_handles)
    AWS::STS.new.new_federated_session(table_name,
        policy: sqs_policy(table_name).to_json,
        duration: Token::POLICY_DURATION
    ).credentials.merge(table_name: table_name)
  end

  def self.get_table_name twitter_handles
    TABLE_PREFIX + Digest::MD5.hexdigest(twitter_handles.sort.join('!'))[0..(30 - TABLE_PREFIX.length)]
  end

  def self.sqs_policy table_name
    {
      "Version" => "2012-10-17",
      "Statement" => [
        {
          "Sid" => SecureRandom.hex,
          "Effect" => "Allow",
          "Action" => ["dynamodb:DeleteItem", "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:CreateTable"],
          "Resource" => "arn:aws:dynamodb:us-west-1:286010418145:table/#{table_name}"
        }
      ]
    }
  end
end