CREATE SCHEMA "latitude";
--> statement-breakpoint
DO $$ BEGIN
 CREATE TYPE "latitude"."subscription_plans" AS ENUM('hobby_v1', 'hobby_v2', 'team_v1', 'enterprise_v1');
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 CREATE TYPE "latitude"."reward_types" AS ENUM('github_star', 'follow', 'post', 'github_issue', 'referral', 'signup_launch_day');
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 CREATE TYPE "latitude"."provider" AS ENUM('openai', 'anthropic', 'groq', 'mistral', 'azure', 'google', 'custom');
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 CREATE TYPE "latitude"."run_error_code_enum" AS ENUM('unknown_error', 'default_provider_exceeded_quota_error', 'document_config_error', 'missing_provider_error', 'chain_compile_error', 'ai_run_error', 'unsupported_provider_response_type_error', 'ai_provider_config_error', 'ev_run_missing_provider_log_error', 'ev_run_missing_workspace_error', 'ev_run_unsupported_result_type_error', 'ev_run_response_json_format_error', 'default_provider_invalid_model_error');
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 CREATE TYPE "latitude"."run_error_entity_enum" AS ENUM('document_log', 'evaluation_result');
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 CREATE TYPE "latitude"."log_source" AS ENUM('playground', 'api', 'evaluation', 'user', 'shared_prompt');
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 CREATE TYPE "latitude"."metadata_type" AS ENUM('llm_as_judge', 'llm_as_judge_simple', 'manual');
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 CREATE TYPE "public"."evaluation_result_types" AS ENUM('evaluation_resultable_booleans', 'evaluation_resultable_texts', 'evaluation_resultable_numbers');
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."users" (
	"id" text PRIMARY KEY NOT NULL,
	"name" text,
	"email" text NOT NULL,
	"confirmed_at" timestamp,
	"admin" boolean DEFAULT false NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "users_email_unique" UNIQUE("email")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."sessions" (
	"id" text PRIMARY KEY NOT NULL,
	"user_id" text NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."workspaces" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"name" varchar(256) NOT NULL,
	"current_subscription_id" bigint,
	"creator_id" text,
	"default_provider_id" bigint,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."subscriptions" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"workspace_id" bigint NOT NULL,
	"plan" "latitude"."subscription_plans" NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."memberships" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"workspace_id" bigint NOT NULL,
	"user_id" text NOT NULL,
	"invitation_token" uuid DEFAULT gen_random_uuid() NOT NULL,
	"confirmed_at" timestamp,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "memberships_invitation_token_unique" UNIQUE("invitation_token")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."api_keys" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"token" uuid DEFAULT gen_random_uuid() NOT NULL,
	"workspace_id" bigint NOT NULL,
	"name" varchar(256),
	"last_used_at" timestamp,
	"deleted_at" timestamp,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "api_keys_token_unique" UNIQUE("token")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."claimed_rewards" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"workspace_id" bigint NOT NULL,
	"creator_id" text,
	"reward_type" "latitude"."reward_types" NOT NULL,
	"reference" text NOT NULL,
	"value" bigint NOT NULL,
	"is_valid" boolean,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."projects" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"name" varchar(256) NOT NULL,
	"deleted_at" timestamp,
	"workspace_id" bigint NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."commits" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"uuid" uuid DEFAULT gen_random_uuid() NOT NULL,
	"title" varchar(256) NOT NULL,
	"description" text,
	"project_id" bigint NOT NULL,
	"version" bigint,
	"user_id" text NOT NULL,
	"merged_at" timestamp,
	"deleted_at" timestamp,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "commits_uuid_unique" UNIQUE("uuid")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."document_versions" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"document_uuid" uuid DEFAULT gen_random_uuid() NOT NULL,
	"path" varchar NOT NULL,
	"content" text DEFAULT '' NOT NULL,
	"resolved_content" text,
	"content_hash" text,
	"promptl_version" integer DEFAULT 0 NOT NULL,
	"commit_id" bigint NOT NULL,
	"dataset_id" bigint,
	"deleted_at" timestamp,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."provider_api_keys" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"name" varchar NOT NULL,
	"token" varchar NOT NULL,
	"provider" "latitude"."provider" NOT NULL,
	"url" varchar,
	"default_model" varchar,
	"author_id" text NOT NULL,
	"workspace_id" bigint NOT NULL,
	"last_used_at" timestamp,
	"deleted_at" timestamp,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "provider_api_keys_name_workspace_id_deleted_at_unique" UNIQUE NULLS NOT DISTINCT("name","workspace_id","deleted_at"),
	CONSTRAINT "provider_api_keys_token_provider_workspace_id_deleted_at_unique" UNIQUE NULLS NOT DISTINCT("token","provider","workspace_id","deleted_at")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."document_logs" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"uuid" uuid NOT NULL,
	"document_uuid" uuid NOT NULL,
	"commit_id" bigint NOT NULL,
	"resolved_content" text NOT NULL,
	"content_hash" text NOT NULL,
	"parameters" jsonb NOT NULL,
	"custom_identifier" text,
	"duration" bigint,
	"source" "latitude"."log_source",
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "document_logs_uuid_unique" UNIQUE("uuid")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."run_errors" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"code" "latitude"."run_error_code_enum" NOT NULL,
	"errorable_type" "latitude"."run_error_entity_enum" NOT NULL,
	"errorable_uuid" uuid NOT NULL,
	"message" text NOT NULL,
	"details" jsonb,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."provider_logs" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"workspace_id" bigint,
	"uuid" uuid NOT NULL,
	"document_log_uuid" uuid,
	"provider_id" bigint,
	"model" varchar,
	"finish_reason" varchar DEFAULT 'stop',
	"config" json,
	"messages" json NOT NULL,
	"response_object" jsonb,
	"response_text" text,
	"tool_calls" json DEFAULT '[]'::json NOT NULL,
	"tokens" bigint,
	"cost_in_millicents" integer DEFAULT 0 NOT NULL,
	"duration" bigint,
	"source" "latitude"."log_source" NOT NULL,
	"apiKeyId" bigint,
	"generated_at" timestamp,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "provider_logs_uuid_unique" UNIQUE("uuid")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."datasets" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"name" varchar(256) NOT NULL,
	"csv_delimiter" varchar(256) NOT NULL,
	"workspace_id" bigint NOT NULL,
	"author_id" text,
	"file_key" varchar(256) NOT NULL,
	"file_metadata" jsonb NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."evaluations" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"uuid" uuid DEFAULT gen_random_uuid() NOT NULL,
	"name" varchar(256) NOT NULL,
	"description" text NOT NULL,
	"metadata_type" "latitude"."metadata_type" NOT NULL,
	"metadata_id" bigint NOT NULL,
	"result_type" "evaluation_result_types",
	"result_configuration_id" bigint,
	"workspace_id" bigint NOT NULL,
	"deleted_at" timestamp,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "evaluations_uuid_unique" UNIQUE("uuid")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."llm_as_judge_evaluation_metadatas" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"prompt" text NOT NULL,
	"promptl_version" integer DEFAULT 0 NOT NULL,
	"template_id" bigint,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."evaluation_metadata_llm_as_judge_simple" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"provider_api_key_id" bigint NOT NULL,
	"model" text NOT NULL,
	"objective" text NOT NULL,
	"additional_instructions" text,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."evaluation_metadata_manuals" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."evaluation_configuration_boolean" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"false_value_description" text,
	"true_value_description" text,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."evaluation_configuration_numerical" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"min_value" bigint NOT NULL,
	"max_value" bigint NOT NULL,
	"min_value_description" text,
	"max_value_description" text,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."evaluation_configuration_text" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"value_description" text,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."connected_evaluations" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"live" boolean DEFAULT false NOT NULL,
	"document_uuid" uuid NOT NULL,
	"deleted_at" timestamp,
	"evaluation_id" bigint NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "connected_evaluations_unique_idx" UNIQUE("document_uuid","evaluation_id")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."evaluation_results" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"uuid" uuid NOT NULL,
	"evaluation_id" bigint NOT NULL,
	"document_log_id" bigint NOT NULL,
	"provider_log_id" bigint,
	"evaluated_provider_log_id" bigint,
	"evaluation_provider_log_id" bigint,
	"resultable_type" "evaluation_result_types",
	"resultable_id" bigint,
	"source" "latitude"."log_source",
	"reason" text,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "evaluation_results_uuid_unique" UNIQUE("uuid")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."evaluations_templates" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"name" varchar(256) NOT NULL,
	"description" text NOT NULL,
	"category" bigint,
	"configuration" jsonb NOT NULL,
	"prompt" text NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."evaluations_template_categories" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"name" varchar(256) NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."magic_link_tokens" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"token" uuid DEFAULT gen_random_uuid() NOT NULL,
	"expired_at" timestamp,
	"user_id" text NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "magic_link_tokens_token_unique" UNIQUE("token")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."events" (
	"id" bigserial NOT NULL,
	"workspace_id" bigint,
	"type" varchar(256) NOT NULL,
	"data" jsonb NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."evaluation_resultable_numbers" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"result" bigint NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."evaluation_resultable_texts" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"result" text NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."evaluation_resultable_booleans" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"result" boolean NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "latitude"."published_documents" (
	"uuid" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"document_uuid" uuid NOT NULL,
	"title" varchar,
	"description" text,
	"workspace_id" bigint NOT NULL,
	"project_id" bigint NOT NULL,
	"is_published" boolean DEFAULT false NOT NULL,
	"can_follow_conversation" boolean DEFAULT false NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "published_documents_uuid_unique" UNIQUE("uuid")
);
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."sessions" ADD CONSTRAINT "sessions_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "latitude"."users"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."workspaces" ADD CONSTRAINT "workspaces_current_subscription_id_subscriptions_id_fk" FOREIGN KEY ("current_subscription_id") REFERENCES "latitude"."subscriptions"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."workspaces" ADD CONSTRAINT "workspaces_creator_id_users_id_fk" FOREIGN KEY ("creator_id") REFERENCES "latitude"."users"("id") ON DELETE set null ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."workspaces" ADD CONSTRAINT "workspaces_default_provider_id_provider_api_keys_id_fk" FOREIGN KEY ("default_provider_id") REFERENCES "latitude"."provider_api_keys"("id") ON DELETE set null ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."memberships" ADD CONSTRAINT "memberships_workspace_id_workspaces_id_fk" FOREIGN KEY ("workspace_id") REFERENCES "latitude"."workspaces"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."memberships" ADD CONSTRAINT "memberships_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "latitude"."users"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."api_keys" ADD CONSTRAINT "api_keys_workspace_id_workspaces_id_fk" FOREIGN KEY ("workspace_id") REFERENCES "latitude"."workspaces"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."claimed_rewards" ADD CONSTRAINT "claimed_rewards_workspace_id_workspaces_id_fk" FOREIGN KEY ("workspace_id") REFERENCES "latitude"."workspaces"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."claimed_rewards" ADD CONSTRAINT "claimed_rewards_creator_id_users_id_fk" FOREIGN KEY ("creator_id") REFERENCES "latitude"."users"("id") ON DELETE set null ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."projects" ADD CONSTRAINT "projects_workspace_id_workspaces_id_fk" FOREIGN KEY ("workspace_id") REFERENCES "latitude"."workspaces"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."commits" ADD CONSTRAINT "commits_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "latitude"."projects"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."commits" ADD CONSTRAINT "commits_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "latitude"."users"("id") ON DELETE set null ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."document_versions" ADD CONSTRAINT "document_versions_commit_id_commits_id_fk" FOREIGN KEY ("commit_id") REFERENCES "latitude"."commits"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."document_versions" ADD CONSTRAINT "document_versions_dataset_id_datasets_id_fk" FOREIGN KEY ("dataset_id") REFERENCES "latitude"."datasets"("id") ON DELETE set null ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."provider_api_keys" ADD CONSTRAINT "provider_api_keys_author_id_users_id_fk" FOREIGN KEY ("author_id") REFERENCES "latitude"."users"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."provider_api_keys" ADD CONSTRAINT "provider_api_keys_workspace_id_workspaces_id_fk" FOREIGN KEY ("workspace_id") REFERENCES "latitude"."workspaces"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."document_logs" ADD CONSTRAINT "document_logs_commit_id_commits_id_fk" FOREIGN KEY ("commit_id") REFERENCES "latitude"."commits"("id") ON DELETE restrict ON UPDATE cascade;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."provider_logs" ADD CONSTRAINT "provider_logs_provider_id_provider_api_keys_id_fk" FOREIGN KEY ("provider_id") REFERENCES "latitude"."provider_api_keys"("id") ON DELETE restrict ON UPDATE cascade;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."provider_logs" ADD CONSTRAINT "provider_logs_apiKeyId_api_keys_id_fk" FOREIGN KEY ("apiKeyId") REFERENCES "latitude"."api_keys"("id") ON DELETE restrict ON UPDATE cascade;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."datasets" ADD CONSTRAINT "datasets_workspace_id_workspaces_id_fk" FOREIGN KEY ("workspace_id") REFERENCES "latitude"."workspaces"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."datasets" ADD CONSTRAINT "datasets_author_id_users_id_fk" FOREIGN KEY ("author_id") REFERENCES "latitude"."users"("id") ON DELETE set null ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."evaluations" ADD CONSTRAINT "evaluations_workspace_id_workspaces_id_fk" FOREIGN KEY ("workspace_id") REFERENCES "latitude"."workspaces"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."llm_as_judge_evaluation_metadatas" ADD CONSTRAINT "llm_as_judge_evaluation_metadatas_template_id_evaluations_templates_id_fk" FOREIGN KEY ("template_id") REFERENCES "latitude"."evaluations_templates"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."evaluation_metadata_llm_as_judge_simple" ADD CONSTRAINT "evaluation_metadata_llm_as_judge_simple_provider_api_key_id_provider_api_keys_id_fk" FOREIGN KEY ("provider_api_key_id") REFERENCES "latitude"."provider_api_keys"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."connected_evaluations" ADD CONSTRAINT "connected_evaluations_evaluation_id_evaluations_id_fk" FOREIGN KEY ("evaluation_id") REFERENCES "latitude"."evaluations"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."evaluation_results" ADD CONSTRAINT "evaluation_results_evaluation_id_evaluations_id_fk" FOREIGN KEY ("evaluation_id") REFERENCES "latitude"."evaluations"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."evaluation_results" ADD CONSTRAINT "evaluation_results_document_log_id_document_logs_id_fk" FOREIGN KEY ("document_log_id") REFERENCES "latitude"."document_logs"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."evaluation_results" ADD CONSTRAINT "evaluation_results_provider_log_id_provider_logs_id_fk" FOREIGN KEY ("provider_log_id") REFERENCES "latitude"."provider_logs"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."evaluation_results" ADD CONSTRAINT "evaluation_results_evaluated_provider_log_id_provider_logs_id_fk" FOREIGN KEY ("evaluated_provider_log_id") REFERENCES "latitude"."provider_logs"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."evaluation_results" ADD CONSTRAINT "evaluation_results_evaluation_provider_log_id_provider_logs_id_fk" FOREIGN KEY ("evaluation_provider_log_id") REFERENCES "latitude"."provider_logs"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."evaluations_templates" ADD CONSTRAINT "evaluations_templates_category_evaluations_template_categories_id_fk" FOREIGN KEY ("category") REFERENCES "latitude"."evaluations_template_categories"("id") ON DELETE restrict ON UPDATE cascade;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."magic_link_tokens" ADD CONSTRAINT "magic_link_tokens_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "latitude"."users"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."events" ADD CONSTRAINT "events_workspace_id_workspaces_id_fk" FOREIGN KEY ("workspace_id") REFERENCES "latitude"."workspaces"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."published_documents" ADD CONSTRAINT "published_documents_workspace_id_workspaces_id_fk" FOREIGN KEY ("workspace_id") REFERENCES "latitude"."workspaces"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "latitude"."published_documents" ADD CONSTRAINT "published_documents_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "latitude"."projects"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "subscriptions_workspace_id_index" ON "latitude"."subscriptions" USING btree ("workspace_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "subscriptions_plan_index" ON "latitude"."subscriptions" USING btree ("plan");--> statement-breakpoint
CREATE UNIQUE INDEX IF NOT EXISTS "memberships_workspace_id_user_id_index" ON "latitude"."memberships" USING btree ("workspace_id","user_id");--> statement-breakpoint
CREATE UNIQUE INDEX IF NOT EXISTS "memberships_invitation_token_index" ON "latitude"."memberships" USING btree ("invitation_token");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "workspace_id_idx" ON "latitude"."api_keys" USING btree ("workspace_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "claimed_rewards_workspace_id_idx" ON "latitude"."claimed_rewards" USING btree ("workspace_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "workspace_idx" ON "latitude"."projects" USING btree ("workspace_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "projects_deleted_at_idx" ON "latitude"."projects" USING btree ("deleted_at");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "project_commit_order_idx" ON "latitude"."commits" USING btree ("merged_at","project_id");--> statement-breakpoint
CREATE UNIQUE INDEX IF NOT EXISTS "unique_commit_version" ON "latitude"."commits" USING btree ("version","project_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "user_idx" ON "latitude"."commits" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "merged_at_idx" ON "latitude"."commits" USING btree ("merged_at");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "project_id_idx" ON "latitude"."commits" USING btree ("project_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "commits_deleted_at_indx" ON "latitude"."commits" USING btree ("deleted_at");--> statement-breakpoint
CREATE UNIQUE INDEX IF NOT EXISTS "document_versions_unique_document_uuid_commit_id" ON "latitude"."document_versions" USING btree ("document_uuid","commit_id");--> statement-breakpoint
CREATE UNIQUE INDEX IF NOT EXISTS "document_versions_unique_path_commit_id_deleted_at" ON "latitude"."document_versions" USING btree ("path","commit_id","deleted_at");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "document_versions_commit_id_idx" ON "latitude"."document_versions" USING btree ("commit_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "document_versions_deleted_at_idx" ON "latitude"."document_versions" USING btree ("deleted_at");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "document_versions_path_idx" ON "latitude"."document_versions" USING btree ("path");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "provider_apikeys_workspace_id_idx" ON "latitude"."provider_api_keys" USING btree ("workspace_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "provider_api_keys_name_workspace_id_deleted_at_index" ON "latitude"."provider_api_keys" USING btree ("name","workspace_id","deleted_at");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "provider_apikeys_user_id_idx" ON "latitude"."provider_api_keys" USING btree ("author_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "provider_api_keys_token_provider_workspace_id_deleted_at_index" ON "latitude"."provider_api_keys" USING btree ("token","provider","workspace_id","deleted_at");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "document_log_own_uuid_idx" ON "latitude"."document_logs" USING btree ("uuid");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "document_log_uuid_idx" ON "latitude"."document_logs" USING btree ("document_uuid");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "document_logs_commit_id_idx" ON "latitude"."document_logs" USING btree ("commit_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "document_logs_content_hash_idx" ON "latitude"."document_logs" USING btree ("content_hash");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "document_logs_created_at_idx" ON "latitude"."document_logs" USING btree ("created_at");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "run_errors_errorable_entity_uuid_idx" ON "latitude"."run_errors" USING btree ("errorable_uuid","errorable_type");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "provider_idx" ON "latitude"."provider_logs" USING btree ("provider_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "provider_logs_created_at_idx" ON "latitude"."provider_logs" USING btree ("created_at");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "provider_logs_workspace_id_index" ON "latitude"."provider_logs" USING btree ("workspace_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "datasets_workspace_idx" ON "latitude"."datasets" USING btree ("workspace_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "datasets_author_idx" ON "latitude"."datasets" USING btree ("author_id");--> statement-breakpoint
CREATE UNIQUE INDEX IF NOT EXISTS "datasets_workspace_id_name_index" ON "latitude"."datasets" USING btree ("workspace_id","name");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "evaluation_workspace_idx" ON "latitude"."evaluations" USING btree ("workspace_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "evaluation_metadata_idx" ON "latitude"."evaluations" USING btree ("metadata_id","metadata_type");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "evaluations_deleted_at_idx" ON "latitude"."evaluations" USING btree ("deleted_at");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "llm_as_judge_evaluation_metadatas_template_id_idx" ON "latitude"."llm_as_judge_evaluation_metadatas" USING btree ("template_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "connected_evaluations_evaluation_idx" ON "latitude"."connected_evaluations" USING btree ("evaluation_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "evaluation_idx" ON "latitude"."evaluation_results" USING btree ("evaluation_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "evaluation_provider_log_idx" ON "latitude"."evaluation_results" USING btree ("evaluation_provider_log_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "evaluated_provider_log_idx" ON "latitude"."evaluation_results" USING btree ("evaluated_provider_log_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "document_log_idx" ON "latitude"."evaluation_results" USING btree ("document_log_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "provider_log_idx" ON "latitude"."evaluation_results" USING btree ("provider_log_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "resultable_idx" ON "latitude"."evaluation_results" USING btree ("resultable_id","resultable_type");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "evaluation_results_created_at_idx" ON "latitude"."evaluation_results" USING btree ("created_at");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "event_workspace_idx" ON "latitude"."events" USING btree ("workspace_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "event_type_idx" ON "latitude"."events" USING btree ("type");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "published_doc_workspace_idx" ON "latitude"."published_documents" USING btree ("workspace_id");--> statement-breakpoint
CREATE UNIQUE INDEX IF NOT EXISTS "unique_project_document_uuid_idx" ON "latitude"."published_documents" USING btree ("project_id","document_uuid");