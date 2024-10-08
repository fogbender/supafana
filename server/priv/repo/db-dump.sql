--
-- PostgreSQL database dump
--

-- Dumped from database version 15.7
-- Dumped by pg_dump version 15.7

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alert; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alert (
    grafana_id uuid NOT NULL,
    supabase_id text NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    title text NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: email_alert_contact; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.email_alert_contact (
    grafana_id uuid NOT NULL,
    supabase_id text NOT NULL,
    email text NOT NULL,
    severity text DEFAULT 'critical'::text NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: grafana; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grafana (
    id uuid NOT NULL,
    supabase_id character varying(255) NOT NULL,
    org_id uuid NOT NULL,
    plan character varying(255) DEFAULT 'Trial'::character varying,
    state character varying(255) DEFAULT 'Initial'::character varying,
    password character varying(255),
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    first_start_at timestamp without time zone,
    stripe_subscription_id text,
    max_client_connections integer DEFAULT 200
);


--
-- Name: org; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org (
    id uuid NOT NULL,
    supabase_id character varying(255) NOT NULL,
    free_instances integer DEFAULT 0,
    name text,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: org_stripe_customer; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_stripe_customer (
    org_id uuid NOT NULL,
    stripe_customer_id text NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    is_default boolean DEFAULT false NOT NULL
);


--
-- Name: org_stripe_subscription; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_stripe_subscription (
    org_id uuid NOT NULL,
    stripe_customer_id text NOT NULL,
    stripe_subscription_id text NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: user_notification; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_notification (
    org_id uuid NOT NULL,
    user_id text NOT NULL,
    email text NOT NULL,
    tx_emails boolean DEFAULT false NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: grafana grafana_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grafana
    ADD CONSTRAINT grafana_pkey PRIMARY KEY (id);


--
-- Name: org org_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org
    ADD CONSTRAINT org_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: alert_grafana_id_title_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX alert_grafana_id_title_index ON public.alert USING btree (grafana_id, title);


--
-- Name: email_alert_contact_grafana_id_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX email_alert_contact_grafana_id_email_index ON public.email_alert_contact USING btree (grafana_id, email);


--
-- Name: grafana_supabase_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX grafana_supabase_id_index ON public.grafana USING btree (supabase_id);


--
-- Name: org_stripe_customer_org_id_stripe_customer_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX org_stripe_customer_org_id_stripe_customer_id_index ON public.org_stripe_customer USING btree (org_id, stripe_customer_id);


--
-- Name: org_supabase_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX org_supabase_id_index ON public.org USING btree (supabase_id);


--
-- Name: unique_is_default_per_org; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_is_default_per_org ON public.org_stripe_customer USING btree (org_id) WHERE (is_default = true);


--
-- Name: unique_user_per_org; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_user_per_org ON public.user_notification USING btree (org_id, user_id);


--
-- PostgreSQL database dump complete
--

INSERT INTO public."schema_migrations" (version) VALUES (20240710152810);
INSERT INTO public."schema_migrations" (version) VALUES (20240713193345);
INSERT INTO public."schema_migrations" (version) VALUES (20240720230903);
INSERT INTO public."schema_migrations" (version) VALUES (20240727002752);
INSERT INTO public."schema_migrations" (version) VALUES (20240804050719);
INSERT INTO public."schema_migrations" (version) VALUES (20240815015612);
INSERT INTO public."schema_migrations" (version) VALUES (20240914002713);
