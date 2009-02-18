require File.dirname(__FILE__) + '/../../../../test/test_helper'

class FriendshipTest < Test::Unit::TestCase
  
  def test_should_be_able_to_create_if_valid
    @f = Friendship.new({:sender_user_id => 5, :receiver_user_id => 4})
    assert_equal true, @f.save
  end
  
  def test_should_not_be_able_to_create_if_friendship_with_self
    f = Friendship.new({:sender_user_id => 5, :receiver_user_id => 5})
    assert_equal false, f.save
  end
  
  def test_should_not_be_able_to_create_if_friendship_already_exist
    test_should_be_able_to_create_if_valid
    f = Friendship.new({:sender_user_id => 5, :receiver_user_id => 4})
    assert_equal false, f.save
  end
  
  def test_find_between_should_work_both_ways
    f1 = Friendship.find_between(User.find(1), User.find(2))
    assert_not_nil f1
    assert_equal true, ((f1.receiver_user_id == 1 and f1.sender_user_id == 2) or (f1.receiver_user_id == 2 and f1.sender_user_id == 1))
    f2 = Friendship.find_between(User.find(2), User.find(1))
    assert_not_nil f2
    assert_equal true, ((f1.receiver_user_id == 1 and f1.sender_user_id == 2) or (f1.receiver_user_id == 2 and f1.sender_user_id == 1))    
  end
  
  def test_should_send_email_to_sender_after_receiver_confirms
    n = Friendship.find(3)
    assert_count_increases(ActionMailer::Base.deliveries) { n.accept }
  end
  
  def test_should_update_other_users_friendship_pending_requests_after_create
    u4 = User.find(4)
    assert_equal false, u4.has_new_friend_requests?
    test_should_be_able_to_create_if_valid
    u4.reload
    assert_equal true, u4.has_new_friend_requests?
  end
  
  def test_should_send_email_when_initiating_friendship
    assert_count_increases(ActionMailer::Base.deliveries) do
      test_should_be_able_to_create_if_valid
    end
  end
  
  def test_create_friendship_with_external_email_should_create_external_invitation_key
    f = Friendship.new({:sender_user_id => 1, :receiver_email => "fulanito@lalala.com" })
    assert_equal true, f.save
    assert_not_nil f.external_invitation_key
  end
  
  def test_should_only_accept_valid_emails
    # TODO
  end
  
  def test_should_only_create_new_friendship_if_number_of_unanswered_friendships_is_below_max
    User.db_query("DELETE FROM friendships WHERE sender_user_id = 1")
    Friendship.class_eval do
      def self.max_unanswered
        3
      end
    end
    Friendship.max_unanswered.times do |t|
      f = Friendship.new({:sender_user_id => 1, :receiver_email => "fulanito#{t}@lalala.com" })
      assert_equal true, f.save
    end
    f = Friendship.new({:sender_user_id => 1, :receiver_email => "fulanito#{Friendship.max_unanswered+1}@lalala.com" })
    assert_equal false, f.save
  end
end
