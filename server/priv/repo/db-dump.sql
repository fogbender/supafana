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
-- Name: org_stripe_customer_org_id_stripe_customer_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX org_stripe_customer_org_id_stripe_customer_id_index ON public.org_stripe_customer USING btree (org_id, stripe_customer_id);


--
-- Name: org_supabase_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX org_supabase_id_index ON public.org USING btree (supabase_id);


--
-- PostgreSQL database dump complete
--

INSERT INTO public."schema_migrations" (version) VALUES (20240710152810);
INSERT INTO public."schema_migrations" (version) VALUES (20240713193345);
