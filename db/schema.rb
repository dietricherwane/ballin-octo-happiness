# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160128221336) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: true do |t|
    t.string   "msisdn",            limit: 13
    t.string   "account_number"
    t.string   "remote_ip_address"
    t.string   "password"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "salt"
  end

  create_table "bomb_logs", force: true do |t|
    t.text     "sent_url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "certified_agents", force: true do |t|
    t.string   "certified_agent_id"
    t.boolean  "published"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "account_number"
    t.string   "token"
    t.string   "sub_certified_agent_id"
    t.string   "wari_sub_agent_id"
  end

  create_table "deposit_logs", force: true do |t|
    t.string   "game_token"
    t.string   "pos_id"
    t.text     "deposit_request"
    t.text     "deposit_response"
    t.string   "session_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "deposits", force: true do |t|
    t.string   "game_token"
    t.string   "pos_id"
    t.string   "agent"
    t.string   "sub_agent"
    t.string   "paymoney_account"
    t.text     "deposit_request"
    t.text     "deposit_response"
    t.string   "deposit_day"
    t.float    "deposit_amount"
    t.string   "transaction_id"
    t.boolean  "deposit_made"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "paymoney_request"
    t.text     "paymoney_response"
  end

  create_table "fee_types", force: true do |t|
    t.string   "name"
    t.string   "token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fees", force: true do |t|
    t.integer  "fee_type_id"
    t.float    "min_value"
    t.float    "max_value"
    t.float    "fee_value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "game_tokens", force: true do |t|
    t.string   "description"
    t.string   "code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "logs", force: true do |t|
    t.string   "transaction_type"
    t.string   "phone_number",                limit: 13
    t.string   "credit_amount"
    t.string   "checkout_amount"
    t.string   "otp"
    t.string   "pin"
    t.boolean  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "error_log"
    t.text     "response_log"
    t.string   "account_number"
    t.string   "remote_ip_address"
    t.string   "agent"
    t.string   "sub_agent"
    t.string   "transaction_id"
    t.float    "fee"
    t.float    "thumb"
    t.string   "game_account_token"
    t.string   "account_token"
    t.string   "mobile_money_account_number"
    t.string   "a_account_transfer"
    t.string   "b_account_transfer"
    t.boolean  "bet_placed"
    t.datetime "bet_placed_at"
    t.boolean  "bet_validated"
    t.datetime "bet_validated_at"
    t.boolean  "bet_paid_back"
    t.datetime "bet_paid_back_at"
    t.string   "paymoney_validation_id"
  end

  create_table "parameters", force: true do |t|
    t.string   "paymoney_wallet_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "hub_front_office_url"
  end

end
