--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5
-- Dumped by pg_dump version 17.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS '';


--
-- Name: get_competency_results(character varying, integer); Type: FUNCTION; Schema: public; Owner: ma0349
--

CREATE FUNCTION public.get_competency_results(p_username character varying, p_organization_id integer) RETURNS TABLE(competency_area text, competency_name text, user_recorded_level text, user_recorded_level_competency_indicator text, user_required_level text, user_required_level_competency_indicator text)
    LANGUAGE plpgsql
    AS $$
    BEGIN
        RETURN QUERY
        WITH recorded_competencies AS (
            SELECT sr.competency_id,
                   c.competency_area::TEXT,
                   c.competency_name::TEXT,
                   sr.score AS user_score
            FROM user_se_competency_survey_results sr
            LEFT JOIN competency c ON sr.competency_id = c.id
            WHERE sr.user_id IN (select id from app_user where username= p_username and organization_id = p_organization_id)
        ),
        required_competencies AS (
            SELECT competency_id, MAX(role_competency_value) AS max_score
            FROM role_competency_matrix
            WHERE organization_id = p_organization_id
              AND role_cluster_id IN (
                  SELECT role_cluster_id
                  FROM user_role_cluster
                  WHERE user_id IN (select id from app_user where username= p_username and organization_id = p_organization_id)
              )
            GROUP BY competency_id
        ),
        required_vs_recorded AS (
            SELECT rec.*, req.max_score
            FROM recorded_competencies rec
            LEFT JOIN required_competencies req ON rec.competency_id = req.competency_id
        ),
        competency_indicators_with_score AS (
            SELECT competency_id, "level",
                   CASE
                       WHEN "level" = 'kennen' THEN 1
                       WHEN "level" = 'verstehen' THEN 2
                       WHEN "level" = 'anwenden' THEN 4
                       WHEN "level" = 'beherrschen' THEN 6
                   END AS level_assigned_score,
                   STRING_AGG(indicator_en, '. ') AS indicator_en
            FROM competency_indicators
            GROUP BY competency_id, "level"
        ),
        required_vs_recorded_with_indicators_joined_by_req AS (
            SELECT rr.*, i.level AS recorded_level, i.indicator_en AS recorded_level_indicators
            FROM required_vs_recorded rr
            LEFT JOIN competency_indicators_with_score i
                ON rr.competency_id = i.competency_id
                AND rr.user_score = i.level_assigned_score
        ),
        required_vs_recorded_with_indicators_joined_by_req_joined_by_rec AS (
            SELECT rr.*, i.level AS required_level, i.indicator_en AS required_level_indicators
            FROM required_vs_recorded_with_indicators_joined_by_req rr
            LEFT JOIN competency_indicators_with_score i
                ON rr.competency_id = i.competency_id
                AND rr.max_score = i.level_assigned_score
        )
        SELECT rrw.competency_area::TEXT,
               rrw.competency_name::TEXT,
               COALESCE(rrw.recorded_level, 'unwissend')::TEXT AS user_recorded_level,
               COALESCE(rrw.recorded_level_indicators, 'You are unaware or lacks knowledge in this competency area')::TEXT AS user_recorded_level_competency_indicator,
               rrw.required_level::TEXT AS user_required_level,
               rrw.required_level_indicators::TEXT AS user_required_level_competency_indicator
        FROM required_vs_recorded_with_indicators_joined_by_req_joined_by_rec rrw
        ORDER BY rrw.competency_area;
    END;
    $$;


ALTER FUNCTION public.get_competency_results(p_username character varying, p_organization_id integer) OWNER TO ma0349;

--
-- Name: get_unknown_role_competency_results(character varying, integer); Type: FUNCTION; Schema: public; Owner: ma0349
--

CREATE FUNCTION public.get_unknown_role_competency_results(p_username character varying, p_organization_id integer) RETURNS TABLE(competency_area text, competency_name text, user_recorded_level text, user_recorded_level_competency_indicator text, user_required_level text, user_required_level_competency_indicator text)
    LANGUAGE plpgsql
    AS $$
    BEGIN
        RETURN QUERY
        WITH recorded_competencies AS (
            SELECT sr.competency_id,
                   c.competency_area::TEXT,
                   c.competency_name::TEXT,
                   sr.score AS user_score
            FROM user_se_competency_survey_results sr
            LEFT JOIN competency c ON sr.competency_id = c.id
            WHERE sr.user_id IN (select id from app_user where username= p_username and organization_id = p_organization_id)
        ),
        required_competencies AS (
            SELECT competency_id, role_competency_value as max_score
            FROM unknown_role_competency_matrix urcm
            WHERE user_name = p_username AND organization_id = p_organization_id
        ),
        required_vs_recorded AS (
            SELECT rec.*, req.max_score
            FROM recorded_competencies rec
            LEFT JOIN required_competencies req ON rec.competency_id = req.competency_id
        ),
        competency_indicators_with_score AS (
            SELECT competency_id, "level",
                   CASE
                       WHEN "level" = 'kennen' THEN 1
                       WHEN "level" = 'verstehen' THEN 2
                       WHEN "level" = 'anwenden' THEN 4
                       WHEN "level" = 'beherrschen' THEN 6
                   END AS level_assigned_score,
                   STRING_AGG(indicator_en, '. ') AS indicator_en
            FROM competency_indicators
            GROUP BY competency_id, "level"
        ),
        required_vs_recorded_with_indicators_joined_by_req AS (
            SELECT rr.*, i.level AS recorded_level, i.indicator_en AS recorded_level_indicators
            FROM required_vs_recorded rr
            LEFT JOIN competency_indicators_with_score i
                ON rr.competency_id = i.competency_id
                AND rr.user_score = i.level_assigned_score
        ),
        required_vs_recorded_with_indicators_joined_by_req_joined_by_rec AS (
            SELECT rr.*, i.level AS required_level, i.indicator_en AS required_level_indicators
            FROM required_vs_recorded_with_indicators_joined_by_req rr
            LEFT JOIN competency_indicators_with_score i
                ON rr.competency_id = i.competency_id
                AND rr.max_score = i.level_assigned_score
        )
        SELECT rrw.competency_area::TEXT,
               rrw.competency_name::TEXT,
               COALESCE(rrw.recorded_level, 'unwissend')::TEXT AS user_recorded_level,
               COALESCE(rrw.recorded_level_indicators, 'You are unaware or lacks knowledge in this competency area')::TEXT AS user_recorded_level_competency_indicator,
               rrw.required_level::TEXT AS user_required_level,
               rrw.required_level_indicators::TEXT AS user_required_level_competency_indicator
        FROM required_vs_recorded_with_indicators_joined_by_req_joined_by_rec rrw
        ORDER BY rrw.competency_area;
    END;
    $$;


ALTER FUNCTION public.get_unknown_role_competency_results(p_username character varying, p_organization_id integer) OWNER TO ma0349;

--
-- Name: insert_new_org_default_role_competency_matrix(integer); Type: PROCEDURE; Schema: public; Owner: ma0349
--

CREATE PROCEDURE public.insert_new_org_default_role_competency_matrix(IN _organization_id integer)
    LANGUAGE plpgsql
    AS $$
        BEGIN
            -- This copies pre-existing role-competency data from org_id=1
            -- Note: Normally you would call update_role_competency_matrix instead
            -- to calculate from role_process + process_competency matrices
            INSERT INTO public.role_competency_matrix (role_cluster_id, competency_id, role_competency_value, organization_id)
            SELECT
                role_cluster_id,
                competency_id,
                role_competency_value,
                _organization_id
            FROM public.role_competency_matrix
            WHERE organization_id = 1;

            RAISE NOTICE 'Rows copied into role_competency_matrix with organization_id %', _organization_id;
        END;
        $$;


ALTER PROCEDURE public.insert_new_org_default_role_competency_matrix(IN _organization_id integer) OWNER TO ma0349;

--
-- Name: insert_new_org_default_role_process_matrix(integer); Type: PROCEDURE; Schema: public; Owner: ma0349
--

CREATE PROCEDURE public.insert_new_org_default_role_process_matrix(IN _organization_id integer)
    LANGUAGE plpgsql
    AS $$
        BEGIN
            -- Insert rows into role_process_matrix where organization_id is 1
            INSERT INTO public.role_process_matrix (role_cluster_id, iso_process_id, role_process_value, organization_id)
            SELECT
                role_cluster_id,
                iso_process_id,
                role_process_value,
                _organization_id  -- Use the new organization_id
            FROM public.role_process_matrix
            WHERE organization_id = 1;

            RAISE NOTICE 'Rows successfully inserted into role_process_matrix with organization_id %', _organization_id;
        END;
        $$;


ALTER PROCEDURE public.insert_new_org_default_role_process_matrix(IN _organization_id integer) OWNER TO ma0349;

--
-- Name: set_username(); Type: FUNCTION; Schema: public; Owner: ma0349
--

CREATE FUNCTION public.set_username() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN IF NEW.id IS NULL THEN NEW.id := nextval(pg_get_serial_sequence('new_survey_user', 'id')); END IF; IF NEW.username IS NULL OR NEW.username = '' THEN NEW.username := 'se_survey_user_' || NEW.id; END IF; RETURN NEW; END; $$;


ALTER FUNCTION public.set_username() OWNER TO ma0349;

--
-- Name: update_role_competency_matrix(integer); Type: PROCEDURE; Schema: public; Owner: ma0349
--

CREATE PROCEDURE public.update_role_competency_matrix(IN _organization_id integer)
    LANGUAGE plpgsql
    AS $$
        BEGIN
            -- Step 1: Delete existing entries for the given organization_id
            DELETE FROM public.role_competency_matrix
            WHERE organization_id = _organization_id;

            -- Step 2: Calculate and insert role-competency relationships
            -- Formula: role_competency_value = role_process_value * process_competency_value
            INSERT INTO public.role_competency_matrix (role_cluster_id, competency_id, role_competency_value, organization_id)
            SELECT
                rpm.role_cluster_id,
                pcm.competency_id,
                MAX(
                    CASE
                        -- Multiply role_process_value and process_competency_value
                        WHEN rpm.role_process_value * pcm.process_competency_value = 0 THEN 0
                        WHEN rpm.role_process_value * pcm.process_competency_value = 1 THEN 1
                        WHEN rpm.role_process_value * pcm.process_competency_value = 2 THEN 2
                        WHEN rpm.role_process_value * pcm.process_competency_value = 3 THEN 3
                        WHEN rpm.role_process_value * pcm.process_competency_value = 4 THEN 4
                        WHEN rpm.role_process_value * pcm.process_competency_value = 6 THEN 6
                        ELSE -100  -- Invalid combination
                    END
                ) AS role_competency_value,
                _organization_id
            FROM
                public.role_process_matrix rpm
            JOIN
                public.process_competency_matrix pcm
            ON
                rpm.iso_process_id = pcm.iso_process_id
            WHERE
                rpm.organization_id = _organization_id
            GROUP BY
                rpm.role_cluster_id, pcm.competency_id;

            RAISE NOTICE 'Role-Competency matrix recalculated for organization_id %', _organization_id;
        END;
        $$;


ALTER PROCEDURE public.update_role_competency_matrix(IN _organization_id integer) OWNER TO ma0349;

--
-- Name: update_unknown_role_competency_values(text, integer); Type: PROCEDURE; Schema: public; Owner: ma0349
--

CREATE PROCEDURE public.update_unknown_role_competency_values(IN input_user_name text, IN input_organization_id integer)
    LANGUAGE plpgsql
    AS $$
        BEGIN
            -- Delete existing entries for the user and organization
            DELETE FROM unknown_role_competency_matrix
            WHERE user_name = input_user_name
              AND organization_id = input_organization_id;

            -- Calculate competency requirements from process involvement
            -- Formula: role_competency_value = role_process_value * process_competency_value
            INSERT INTO unknown_role_competency_matrix (user_name, competency_id, role_competency_value, organization_id)
            SELECT
                urpm.user_name::VARCHAR(50),
                pcm.competency_id,
                MAX(
                    CASE
                        WHEN urpm.role_process_value * pcm.process_competency_value = 0 THEN 0
                        WHEN urpm.role_process_value * pcm.process_competency_value = 1 THEN 1
                        WHEN urpm.role_process_value * pcm.process_competency_value = 2 THEN 2
                        WHEN urpm.role_process_value * pcm.process_competency_value = 3 THEN 3
                        WHEN urpm.role_process_value * pcm.process_competency_value = 4 THEN 4
                        WHEN urpm.role_process_value * pcm.process_competency_value = 6 THEN 6
                        ELSE -100
                    END
                ) AS role_competency_value,
                input_organization_id AS organization_id
            FROM public.unknown_role_process_matrix urpm
            JOIN public.process_competency_matrix pcm
            ON urpm.iso_process_id = pcm.iso_process_id
            WHERE urpm.organization_id = input_organization_id
              AND urpm.user_name = input_user_name
            GROUP BY urpm.user_name, pcm.competency_id;

            RAISE NOTICE 'Unknown role competency values updated for user % in organization %', input_user_name, input_organization_id;
        END;
        $$;


ALTER PROCEDURE public.update_unknown_role_competency_values(IN input_user_name text, IN input_organization_id integer) OWNER TO ma0349;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: app_user; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.app_user (
    id integer NOT NULL,
    username character varying(255),
    organization_id integer,
    name character varying(255) DEFAULT 'Survey User'::character varying NOT NULL,
    tasks_responsibilities jsonb DEFAULT '{}'::jsonb NOT NULL
);


ALTER TABLE public.app_user OWNER TO ma0349;

--
-- Name: app_user_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.app_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.app_user_id_seq OWNER TO ma0349;

--
-- Name: app_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.app_user_id_seq OWNED BY public.app_user.id;


--
-- Name: assessments; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.assessments (
    id integer NOT NULL,
    uuid character varying(36),
    user_id integer NOT NULL,
    phase integer,
    assessment_type character varying(50),
    title character varying(200),
    description text,
    status character varying(20),
    score double precision,
    max_score double precision,
    completion_time_minutes integer,
    results text,
    selected_archetype_id integer,
    created_at timestamp without time zone,
    completed_at timestamp without time zone
);


ALTER TABLE public.assessments OWNER TO ma0349;

--
-- Name: assessments_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.assessments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.assessments_id_seq OWNER TO ma0349;

--
-- Name: assessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.assessments_id_seq OWNED BY public.assessments.id;


--
-- Name: company_contexts; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.company_contexts (
    id integer NOT NULL,
    name character varying(200),
    industry character varying(100),
    size character varying(50),
    domain character varying(100),
    processes text,
    methods text,
    tools text,
    standards text,
    project_types text,
    organizational_structure text,
    quality_score double precision,
    extraction_metadata text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.company_contexts OWNER TO ma0349;

--
-- Name: company_contexts_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.company_contexts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.company_contexts_id_seq OWNER TO ma0349;

--
-- Name: company_contexts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.company_contexts_id_seq OWNED BY public.company_contexts.id;


--
-- Name: competency; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.competency (
    id integer NOT NULL,
    competency_name character varying(255) NOT NULL,
    competency_area character varying(50),
    description text,
    why_it_matters text
);


ALTER TABLE public.competency OWNER TO ma0349;

--
-- Name: competency_assessment_results; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.competency_assessment_results (
    id integer NOT NULL,
    assessment_id integer NOT NULL,
    competency_id integer NOT NULL,
    current_level integer,
    target_level integer,
    score double precision,
    confidence_score double precision,
    gap_analysis text,
    recommendations text
);


ALTER TABLE public.competency_assessment_results OWNER TO ma0349;

--
-- Name: competency_assessment_results_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.competency_assessment_results_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.competency_assessment_results_id_seq OWNER TO ma0349;

--
-- Name: competency_assessment_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.competency_assessment_results_id_seq OWNED BY public.competency_assessment_results.id;


--
-- Name: competency_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.competency_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.competency_id_seq OWNER TO ma0349;

--
-- Name: competency_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.competency_id_seq OWNED BY public.competency.id;


--
-- Name: competency_indicators; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.competency_indicators (
    id integer NOT NULL,
    competency_id integer,
    level character varying(50),
    indicator_en text,
    indicator_de text
);


ALTER TABLE public.competency_indicators OWNER TO ma0349;

--
-- Name: competency_indicators_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.competency_indicators_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.competency_indicators_id_seq OWNER TO ma0349;

--
-- Name: competency_indicators_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.competency_indicators_id_seq OWNED BY public.competency_indicators.id;


--
-- Name: iso_activities; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.iso_activities (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    process_id integer
);


ALTER TABLE public.iso_activities OWNER TO ma0349;

--
-- Name: iso_activities_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.iso_activities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.iso_activities_id_seq OWNER TO ma0349;

--
-- Name: iso_activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.iso_activities_id_seq OWNED BY public.iso_activities.id;


--
-- Name: iso_processes; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.iso_processes (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    life_cycle_process_id integer
);


ALTER TABLE public.iso_processes OWNER TO ma0349;

--
-- Name: iso_processes_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.iso_processes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.iso_processes_id_seq OWNER TO ma0349;

--
-- Name: iso_processes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.iso_processes_id_seq OWNED BY public.iso_processes.id;


--
-- Name: iso_system_life_cycle_processes; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.iso_system_life_cycle_processes (
    id integer NOT NULL,
    name character varying(255) NOT NULL
);


ALTER TABLE public.iso_system_life_cycle_processes OWNER TO ma0349;

--
-- Name: iso_system_life_cycle_processes_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.iso_system_life_cycle_processes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.iso_system_life_cycle_processes_id_seq OWNER TO ma0349;

--
-- Name: iso_system_life_cycle_processes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.iso_system_life_cycle_processes_id_seq OWNED BY public.iso_system_life_cycle_processes.id;


--
-- Name: iso_tasks; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.iso_tasks (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    activity_id integer
);


ALTER TABLE public.iso_tasks OWNER TO ma0349;

--
-- Name: iso_tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.iso_tasks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.iso_tasks_id_seq OWNER TO ma0349;

--
-- Name: iso_tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.iso_tasks_id_seq OWNED BY public.iso_tasks.id;


--
-- Name: learning_modules; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.learning_modules (
    id integer NOT NULL,
    uuid character varying(36),
    module_code character varying(10) NOT NULL,
    name character varying(200) NOT NULL,
    category character varying(50) NOT NULL,
    competency_id integer,
    definition text,
    overview text,
    industry_relevance text,
    level_1_content text,
    level_2_content text,
    level_3_4_content text,
    level_5_6_content text,
    prerequisites text,
    dependencies text,
    industry_adaptations text,
    total_duration_hours integer,
    difficulty_level character varying(20),
    version character varying(10),
    is_active boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.learning_modules OWNER TO ma0349;

--
-- Name: learning_modules_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.learning_modules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.learning_modules_id_seq OWNER TO ma0349;

--
-- Name: learning_modules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.learning_modules_id_seq OWNED BY public.learning_modules.id;


--
-- Name: learning_objectives; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.learning_objectives (
    id integer NOT NULL,
    uuid character varying(36),
    user_id integer,
    competency_id integer NOT NULL,
    text text NOT NULL,
    type character varying(50),
    priority character varying(20),
    smart_score double precision,
    smart_analysis text,
    context_relevance double precision,
    validation_status character varying(20),
    rag_sources text,
    generation_metadata text,
    created_at timestamp without time zone
);


ALTER TABLE public.learning_objectives OWNER TO ma0349;

--
-- Name: learning_objectives_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.learning_objectives_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.learning_objectives_id_seq OWNER TO ma0349;

--
-- Name: learning_objectives_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.learning_objectives_id_seq OWNED BY public.learning_objectives.id;


--
-- Name: learning_paths; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.learning_paths (
    id integer NOT NULL,
    uuid character varying(36),
    name character varying(200) NOT NULL,
    description text,
    path_type character varying(50),
    target_audience character varying(200),
    module_sequence text,
    estimated_duration_weeks integer,
    difficulty_progression text,
    industry_focus character varying(100),
    role_focus character varying(100),
    experience_level character varying(50),
    completion_criteria text,
    assessment_strategy text,
    is_active boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.learning_paths OWNER TO ma0349;

--
-- Name: learning_paths_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.learning_paths_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.learning_paths_id_seq OWNER TO ma0349;

--
-- Name: learning_paths_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.learning_paths_id_seq OWNED BY public.learning_paths.id;


--
-- Name: learning_plans; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.learning_plans (
    id character varying(36) NOT NULL,
    user_id integer NOT NULL,
    organization_id integer NOT NULL,
    objectives text NOT NULL,
    recommended_modules text,
    estimated_duration_weeks integer,
    archetype_used character varying(100),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.learning_plans OWNER TO ma0349;

--
-- Name: learning_resources; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.learning_resources (
    id integer NOT NULL,
    uuid character varying(36),
    module_id integer NOT NULL,
    title character varying(300) NOT NULL,
    resource_type character varying(50),
    format character varying(20),
    description text,
    url character varying(500),
    file_path character varying(500),
    content_data text,
    target_levels character varying(20),
    prerequisites text,
    difficulty_rating double precision,
    quality_rating double precision,
    usage_count integer,
    average_completion_time integer,
    author character varying(200),
    source character varying(200),
    language character varying(10),
    last_updated timestamp without time zone,
    is_active boolean,
    created_at timestamp without time zone
);


ALTER TABLE public.learning_resources OWNER TO ma0349;

--
-- Name: learning_resources_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.learning_resources_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.learning_resources_id_seq OWNER TO ma0349;

--
-- Name: learning_resources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.learning_resources_id_seq OWNED BY public.learning_resources.id;


--
-- Name: maturity_assessments; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.maturity_assessments (
    id character varying(36) NOT NULL,
    organization_id integer NOT NULL,
    scope_score double precision NOT NULL,
    process_score double precision NOT NULL,
    overall_maturity character varying(20) NOT NULL,
    overall_score double precision NOT NULL,
    responses text,
    completed_at timestamp without time zone
);


ALTER TABLE public.maturity_assessments OWNER TO ma0349;

--
-- Name: module_assessments; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.module_assessments (
    id integer NOT NULL,
    uuid character varying(36),
    enrollment_id integer NOT NULL,
    assessment_type character varying(50),
    level_assessed integer,
    score double precision,
    max_score double precision,
    pass_threshold double precision,
    passed boolean,
    questions_data text,
    responses_data text,
    feedback text,
    time_taken_minutes integer,
    attempt_number integer,
    competency_demonstration text,
    started_at timestamp without time zone,
    completed_at timestamp without time zone
);


ALTER TABLE public.module_assessments OWNER TO ma0349;

--
-- Name: module_assessments_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.module_assessments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.module_assessments_id_seq OWNER TO ma0349;

--
-- Name: module_assessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.module_assessments_id_seq OWNED BY public.module_assessments.id;


--
-- Name: module_enrollments; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.module_enrollments (
    id integer NOT NULL,
    uuid character varying(36),
    user_id integer NOT NULL,
    module_id integer NOT NULL,
    target_level integer,
    current_level integer,
    status character varying(20),
    progress_percentage double precision,
    time_spent_hours double precision,
    learning_style_preference character varying(50),
    engagement_score double precision,
    completion_quality double precision,
    enrolled_at timestamp without time zone,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    last_accessed_at timestamp without time zone
);


ALTER TABLE public.module_enrollments OWNER TO ma0349;

--
-- Name: module_enrollments_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.module_enrollments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.module_enrollments_id_seq OWNER TO ma0349;

--
-- Name: module_enrollments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.module_enrollments_id_seq OWNED BY public.module_enrollments.id;


--
-- Name: new_survey_user; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.new_survey_user (
    id integer NOT NULL,
    username character varying(255) NOT NULL,
    created_at timestamp without time zone,
    survey_completion_status boolean NOT NULL
);


ALTER TABLE public.new_survey_user OWNER TO ma0349;

--
-- Name: new_survey_user_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.new_survey_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.new_survey_user_id_seq OWNER TO ma0349;

--
-- Name: new_survey_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.new_survey_user_id_seq OWNED BY public.new_survey_user.id;


--
-- Name: organization; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.organization (
    id integer NOT NULL,
    organization_name character varying(255) NOT NULL,
    organization_public_key character varying(50) NOT NULL,
    size character varying(20),
    maturity_score double precision,
    selected_archetype character varying(100),
    phase1_completed boolean,
    created_at timestamp without time zone
);


ALTER TABLE public.organization OWNER TO ma0349;

--
-- Name: organization_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.organization_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.organization_id_seq OWNER TO ma0349;

--
-- Name: organization_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.organization_id_seq OWNED BY public.organization.id;


--
-- Name: phase_questionnaire_responses; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.phase_questionnaire_responses (
    id character varying(36) NOT NULL,
    user_id integer NOT NULL,
    organization_id integer NOT NULL,
    questionnaire_type character varying(50) NOT NULL,
    phase integer NOT NULL,
    responses text NOT NULL,
    computed_scores text,
    completed_at timestamp without time zone
);


ALTER TABLE public.phase_questionnaire_responses OWNER TO ma0349;

--
-- Name: process_competency_matrix; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.process_competency_matrix (
    id integer NOT NULL,
    iso_process_id integer NOT NULL,
    competency_id integer NOT NULL,
    process_competency_value integer NOT NULL
);


ALTER TABLE public.process_competency_matrix OWNER TO ma0349;

--
-- Name: process_competency_matrix_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.process_competency_matrix_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.process_competency_matrix_id_seq OWNER TO ma0349;

--
-- Name: process_competency_matrix_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.process_competency_matrix_id_seq OWNED BY public.process_competency_matrix.id;


--
-- Name: qualification_archetypes; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.qualification_archetypes (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    typical_duration character varying(50),
    learning_format character varying(100),
    target_audience character varying(200),
    focus_area character varying(100),
    delivery_method character varying(100),
    strategy character varying(100),
    is_active boolean,
    created_at timestamp without time zone
);


ALTER TABLE public.qualification_archetypes OWNER TO ma0349;

--
-- Name: qualification_archetypes_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.qualification_archetypes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.qualification_archetypes_id_seq OWNER TO ma0349;

--
-- Name: qualification_archetypes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.qualification_archetypes_id_seq OWNED BY public.qualification_archetypes.id;


--
-- Name: qualification_plans; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.qualification_plans (
    id integer NOT NULL,
    uuid character varying(36),
    user_id integer NOT NULL,
    name character varying(200),
    description text,
    target_role character varying(100),
    archetype_id integer,
    estimated_duration_weeks integer,
    modules text,
    learning_path text,
    progress_tracking text,
    status character varying(20),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.qualification_plans OWNER TO ma0349;

--
-- Name: qualification_plans_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.qualification_plans_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.qualification_plans_id_seq OWNER TO ma0349;

--
-- Name: qualification_plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.qualification_plans_id_seq OWNED BY public.qualification_plans.id;


--
-- Name: question_options; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.question_options (
    id integer NOT NULL,
    question_id integer NOT NULL,
    option_text text NOT NULL,
    option_value character varying(10),
    score_value double precision,
    sort_order integer,
    is_correct boolean,
    additional_data text
);


ALTER TABLE public.question_options OWNER TO ma0349;

--
-- Name: question_options_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.question_options_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.question_options_id_seq OWNER TO ma0349;

--
-- Name: question_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.question_options_id_seq OWNED BY public.question_options.id;


--
-- Name: question_responses; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.question_responses (
    id integer NOT NULL,
    questionnaire_response_id integer NOT NULL,
    question_id integer NOT NULL,
    response_value text,
    selected_option_id integer,
    score double precision,
    confidence_level integer,
    time_spent_seconds integer,
    revision_count integer,
    responded_at timestamp without time zone,
    last_modified_at timestamp without time zone
);


ALTER TABLE public.question_responses OWNER TO ma0349;

--
-- Name: question_responses_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.question_responses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.question_responses_id_seq OWNER TO ma0349;

--
-- Name: question_responses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.question_responses_id_seq OWNED BY public.question_responses.id;


--
-- Name: questionnaire_responses; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.questionnaire_responses (
    id integer NOT NULL,
    uuid character varying(36),
    user_id integer NOT NULL,
    questionnaire_id integer NOT NULL,
    status character varying(20),
    completion_percentage double precision,
    total_score double precision,
    max_possible_score double precision,
    score_percentage double precision,
    section_scores text,
    results_summary text,
    recommendations text,
    computed_archetype text,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    duration_minutes integer
);


ALTER TABLE public.questionnaire_responses OWNER TO ma0349;

--
-- Name: questionnaire_responses_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.questionnaire_responses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.questionnaire_responses_id_seq OWNER TO ma0349;

--
-- Name: questionnaire_responses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.questionnaire_responses_id_seq OWNED BY public.questionnaire_responses.id;


--
-- Name: questionnaires; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.questionnaires (
    id integer NOT NULL,
    name character varying(200) NOT NULL,
    title character varying(500),
    description text,
    questionnaire_type character varying(50),
    phase integer,
    is_active boolean,
    sort_order integer,
    estimated_duration_minutes integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.questionnaires OWNER TO ma0349;

--
-- Name: questionnaires_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.questionnaires_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.questionnaires_id_seq OWNER TO ma0349;

--
-- Name: questionnaires_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.questionnaires_id_seq OWNED BY public.questionnaires.id;


--
-- Name: questions; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.questions (
    id integer NOT NULL,
    questionnaire_id integer NOT NULL,
    question_number character varying(10),
    question_text text NOT NULL,
    question_type character varying(20),
    section character varying(100),
    weight double precision,
    max_score double precision,
    scoring_method character varying(50),
    is_required boolean,
    sort_order integer,
    help_text text,
    validation_rules text,
    created_at timestamp without time zone
);


ALTER TABLE public.questions OWNER TO ma0349;

--
-- Name: questions_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.questions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.questions_id_seq OWNER TO ma0349;

--
-- Name: questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.questions_id_seq OWNED BY public.questions.id;


--
-- Name: rag_templates; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.rag_templates (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    category character varying(50),
    competency_focus character varying(100),
    industry_context character varying(100),
    template_text text NOT NULL,
    variables text,
    success_criteria text,
    usage_count integer,
    average_quality_score double precision,
    template_metadata text,
    is_active boolean,
    created_at timestamp without time zone
);


ALTER TABLE public.rag_templates OWNER TO ma0349;

--
-- Name: rag_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.rag_templates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rag_templates_id_seq OWNER TO ma0349;

--
-- Name: rag_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.rag_templates_id_seq OWNED BY public.rag_templates.id;


--
-- Name: role_cluster; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.role_cluster (
    id integer NOT NULL,
    role_cluster_name character varying(255) NOT NULL,
    role_cluster_description text NOT NULL
);


ALTER TABLE public.role_cluster OWNER TO ma0349;

--
-- Name: role_cluster_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.role_cluster_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.role_cluster_id_seq OWNER TO ma0349;

--
-- Name: role_cluster_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.role_cluster_id_seq OWNED BY public.role_cluster.id;


--
-- Name: role_competency_matrix; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.role_competency_matrix (
    id integer NOT NULL,
    role_cluster_id integer NOT NULL,
    competency_id integer NOT NULL,
    role_competency_value integer DEFAULT '-100'::integer NOT NULL,
    organization_id integer NOT NULL,
    CONSTRAINT role_competency_matrix_role_competency_value_check CHECK ((role_competency_value = ANY (ARRAY['-100'::integer, 0, 1, 2, 3, 4, 6])))
);


ALTER TABLE public.role_competency_matrix OWNER TO ma0349;

--
-- Name: role_competency_matrix_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.role_competency_matrix_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.role_competency_matrix_id_seq OWNER TO ma0349;

--
-- Name: role_competency_matrix_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.role_competency_matrix_id_seq OWNED BY public.role_competency_matrix.id;


--
-- Name: role_process_matrix; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.role_process_matrix (
    id integer NOT NULL,
    role_cluster_id integer NOT NULL,
    iso_process_id integer NOT NULL,
    role_process_value integer NOT NULL,
    organization_id integer NOT NULL
);


ALTER TABLE public.role_process_matrix OWNER TO ma0349;

--
-- Name: role_process_matrix_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.role_process_matrix_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.role_process_matrix_id_seq OWNER TO ma0349;

--
-- Name: role_process_matrix_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.role_process_matrix_id_seq OWNED BY public.role_process_matrix.id;


--
-- Name: unknown_role_competency_matrix; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.unknown_role_competency_matrix (
    id integer NOT NULL,
    user_name character varying(50) NOT NULL,
    competency_id integer NOT NULL,
    role_competency_value integer NOT NULL,
    organization_id integer NOT NULL,
    CONSTRAINT unknown_role_competency_matrix_role_competency_value_check CHECK ((role_competency_value = ANY (ARRAY['-100'::integer, 0, 1, 2, 3, 4, 6])))
);


ALTER TABLE public.unknown_role_competency_matrix OWNER TO ma0349;

--
-- Name: unknown_role_competency_matrix_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.unknown_role_competency_matrix_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.unknown_role_competency_matrix_id_seq OWNER TO ma0349;

--
-- Name: unknown_role_competency_matrix_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.unknown_role_competency_matrix_id_seq OWNED BY public.unknown_role_competency_matrix.id;


--
-- Name: unknown_role_process_matrix; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.unknown_role_process_matrix (
    id integer NOT NULL,
    user_name character varying(50) NOT NULL,
    iso_process_id integer NOT NULL,
    role_process_value integer,
    organization_id integer NOT NULL,
    CONSTRAINT unknown_role_process_matrix_role_process_value_check CHECK ((role_process_value = ANY (ARRAY['-100'::integer, 0, 1, 2, 4])))
);


ALTER TABLE public.unknown_role_process_matrix OWNER TO ma0349;

--
-- Name: unknown_role_process_matrix_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.unknown_role_process_matrix_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.unknown_role_process_matrix_id_seq OWNER TO ma0349;

--
-- Name: unknown_role_process_matrix_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.unknown_role_process_matrix_id_seq OWNED BY public.unknown_role_process_matrix.id;


--
-- Name: user_competency_survey_feedback; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.user_competency_survey_feedback (
    id integer NOT NULL,
    user_id integer NOT NULL,
    organization_id integer NOT NULL,
    feedback jsonb NOT NULL
);


ALTER TABLE public.user_competency_survey_feedback OWNER TO ma0349;

--
-- Name: user_competency_survey_feedback_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.user_competency_survey_feedback_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_competency_survey_feedback_id_seq OWNER TO ma0349;

--
-- Name: user_competency_survey_feedback_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.user_competency_survey_feedback_id_seq OWNED BY public.user_competency_survey_feedback.id;


--
-- Name: user_role_cluster; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.user_role_cluster (
    user_id integer NOT NULL,
    role_cluster_id integer NOT NULL
);


ALTER TABLE public.user_role_cluster OWNER TO ma0349;

--
-- Name: user_se_competency_survey_results; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.user_se_competency_survey_results (
    id integer NOT NULL,
    user_id integer,
    organization_id integer,
    competency_id integer,
    score integer NOT NULL,
    submitted_at timestamp without time zone,
    target_level integer,
    gap_size integer,
    archetype_source character varying(100),
    learning_plan_id character varying(36)
);


ALTER TABLE public.user_se_competency_survey_results OWNER TO ma0349;

--
-- Name: user_se_competency_survey_results_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.user_se_competency_survey_results_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_se_competency_survey_results_id_seq OWNER TO ma0349;

--
-- Name: user_se_competency_survey_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.user_se_competency_survey_results_id_seq OWNED BY public.user_se_competency_survey_results.id;


--
-- Name: user_survey_type; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.user_survey_type (
    id integer NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    survey_type character varying(50) NOT NULL
);


ALTER TABLE public.user_survey_type OWNER TO ma0349;

--
-- Name: user_survey_type_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.user_survey_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_survey_type_id_seq OWNER TO ma0349;

--
-- Name: user_survey_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.user_survey_type_id_seq OWNED BY public.user_survey_type.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: ma0349
--

CREATE TABLE public.users (
    id integer NOT NULL,
    uuid character varying(36),
    username character varying(80) NOT NULL,
    email character varying(120),
    password_hash character varying(255) NOT NULL,
    first_name character varying(50),
    last_name character varying(50),
    organization_id integer,
    organization character varying(200),
    joined_via_code character varying(32),
    role character varying(100),
    user_type character varying(20),
    is_active boolean,
    is_verified boolean,
    created_at timestamp without time zone,
    last_login timestamp without time zone
);


ALTER TABLE public.users OWNER TO ma0349;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: ma0349
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO ma0349;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ma0349
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: app_user id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.app_user ALTER COLUMN id SET DEFAULT nextval('public.app_user_id_seq'::regclass);


--
-- Name: assessments id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.assessments ALTER COLUMN id SET DEFAULT nextval('public.assessments_id_seq'::regclass);


--
-- Name: company_contexts id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.company_contexts ALTER COLUMN id SET DEFAULT nextval('public.company_contexts_id_seq'::regclass);


--
-- Name: competency id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.competency ALTER COLUMN id SET DEFAULT nextval('public.competency_id_seq'::regclass);


--
-- Name: competency_assessment_results id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.competency_assessment_results ALTER COLUMN id SET DEFAULT nextval('public.competency_assessment_results_id_seq'::regclass);


--
-- Name: competency_indicators id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.competency_indicators ALTER COLUMN id SET DEFAULT nextval('public.competency_indicators_id_seq'::regclass);


--
-- Name: iso_activities id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.iso_activities ALTER COLUMN id SET DEFAULT nextval('public.iso_activities_id_seq'::regclass);


--
-- Name: iso_processes id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.iso_processes ALTER COLUMN id SET DEFAULT nextval('public.iso_processes_id_seq'::regclass);


--
-- Name: iso_system_life_cycle_processes id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.iso_system_life_cycle_processes ALTER COLUMN id SET DEFAULT nextval('public.iso_system_life_cycle_processes_id_seq'::regclass);


--
-- Name: iso_tasks id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.iso_tasks ALTER COLUMN id SET DEFAULT nextval('public.iso_tasks_id_seq'::regclass);


--
-- Name: learning_modules id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.learning_modules ALTER COLUMN id SET DEFAULT nextval('public.learning_modules_id_seq'::regclass);


--
-- Name: learning_objectives id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.learning_objectives ALTER COLUMN id SET DEFAULT nextval('public.learning_objectives_id_seq'::regclass);


--
-- Name: learning_paths id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.learning_paths ALTER COLUMN id SET DEFAULT nextval('public.learning_paths_id_seq'::regclass);


--
-- Name: learning_resources id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.learning_resources ALTER COLUMN id SET DEFAULT nextval('public.learning_resources_id_seq'::regclass);


--
-- Name: module_assessments id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.module_assessments ALTER COLUMN id SET DEFAULT nextval('public.module_assessments_id_seq'::regclass);


--
-- Name: module_enrollments id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.module_enrollments ALTER COLUMN id SET DEFAULT nextval('public.module_enrollments_id_seq'::regclass);


--
-- Name: new_survey_user id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.new_survey_user ALTER COLUMN id SET DEFAULT nextval('public.new_survey_user_id_seq'::regclass);


--
-- Name: organization id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.organization ALTER COLUMN id SET DEFAULT nextval('public.organization_id_seq'::regclass);


--
-- Name: process_competency_matrix id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.process_competency_matrix ALTER COLUMN id SET DEFAULT nextval('public.process_competency_matrix_id_seq'::regclass);


--
-- Name: qualification_archetypes id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.qualification_archetypes ALTER COLUMN id SET DEFAULT nextval('public.qualification_archetypes_id_seq'::regclass);


--
-- Name: qualification_plans id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.qualification_plans ALTER COLUMN id SET DEFAULT nextval('public.qualification_plans_id_seq'::regclass);


--
-- Name: question_options id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.question_options ALTER COLUMN id SET DEFAULT nextval('public.question_options_id_seq'::regclass);


--
-- Name: question_responses id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.question_responses ALTER COLUMN id SET DEFAULT nextval('public.question_responses_id_seq'::regclass);


--
-- Name: questionnaire_responses id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.questionnaire_responses ALTER COLUMN id SET DEFAULT nextval('public.questionnaire_responses_id_seq'::regclass);


--
-- Name: questionnaires id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.questionnaires ALTER COLUMN id SET DEFAULT nextval('public.questionnaires_id_seq'::regclass);


--
-- Name: questions id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.questions ALTER COLUMN id SET DEFAULT nextval('public.questions_id_seq'::regclass);


--
-- Name: rag_templates id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.rag_templates ALTER COLUMN id SET DEFAULT nextval('public.rag_templates_id_seq'::regclass);


--
-- Name: role_cluster id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.role_cluster ALTER COLUMN id SET DEFAULT nextval('public.role_cluster_id_seq'::regclass);


--
-- Name: role_competency_matrix id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.role_competency_matrix ALTER COLUMN id SET DEFAULT nextval('public.role_competency_matrix_id_seq'::regclass);


--
-- Name: role_process_matrix id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.role_process_matrix ALTER COLUMN id SET DEFAULT nextval('public.role_process_matrix_id_seq'::regclass);


--
-- Name: unknown_role_competency_matrix id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.unknown_role_competency_matrix ALTER COLUMN id SET DEFAULT nextval('public.unknown_role_competency_matrix_id_seq'::regclass);


--
-- Name: unknown_role_process_matrix id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.unknown_role_process_matrix ALTER COLUMN id SET DEFAULT nextval('public.unknown_role_process_matrix_id_seq'::regclass);


--
-- Name: user_competency_survey_feedback id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.user_competency_survey_feedback ALTER COLUMN id SET DEFAULT nextval('public.user_competency_survey_feedback_id_seq'::regclass);


--
-- Name: user_se_competency_survey_results id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.user_se_competency_survey_results ALTER COLUMN id SET DEFAULT nextval('public.user_se_competency_survey_results_id_seq'::regclass);


--
-- Name: user_survey_type id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.user_survey_type ALTER COLUMN id SET DEFAULT nextval('public.user_survey_type_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: app_user; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.app_user (id, username, organization_id, name, tasks_responsibilities) FROM stdin;
1	se_survey_user_4	19	imbatman	"\\"SE-QPT Assessment\\""
2	se_survey_user_5	19	imbatman	"\\"SE-QPT Assessment\\""
3	se_survey_user_6	19	imbatman	"\\"SE-QPT Assessment\\""
4	se_survey_user_7	19	imbatman	"\\"SE-QPT Assessment\\""
5	se_survey_user_8	19	imbatman	"\\"SE-QPT Assessment\\""
6	se_survey_user_9	20	reeguy	"\\"SE-QPT Assessment\\""
7	se_survey_user_10	20	reeguy1	"\\"SE-QPT Assessment\\""
8	se_survey_user_11	20	reeguy1	"\\"SE-QPT Assessment\\""
\.


--
-- Data for Name: assessments; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.assessments (id, uuid, user_id, phase, assessment_type, title, description, status, score, max_score, completion_time_minutes, results, selected_archetype_id, created_at, completed_at) FROM stdin;
\.


--
-- Data for Name: company_contexts; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.company_contexts (id, name, industry, size, domain, processes, methods, tools, standards, project_types, organizational_structure, quality_score, extraction_metadata, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: competency; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.competency (id, competency_name, competency_area, description, why_it_matters) FROM stdin;
1	Systems Thinking	Core	The application of the fundamental concepts of systems thinking to Systems Engineering...	Systems thinking is a way of dealing with increasing complexity...
4	Lifecycle Consideration	Core		
5	Customer / Value Orientation	Core		
6	Systems Modeling and Analysis	Core		
7	Communication	Social / Personal		
8	Leadership	Social / Personal		
9	Self-Organization	Social / Personal		
10	Project Management	Management		
11	Decision Management	Management		
12	Information Management	Management		
13	Configuration Management	Management		
14	Requirements Definition	Technical		
15	System Architecting	Technical		
16	Integration, Verification, Validation	Technical		
17	Operation and Support	Technical		
18	Agile Methods	Technical		
\.


--
-- Data for Name: competency_assessment_results; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.competency_assessment_results (id, assessment_id, competency_id, current_level, target_level, score, confidence_score, gap_analysis, recommendations) FROM stdin;
\.


--
-- Data for Name: competency_indicators; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.competency_indicators (id, competency_id, level, indicator_en, indicator_de) FROM stdin;
1	1	1	You are able to recognise the interrelationships of your system and its boundaries.	\N
2	1	2	You understand the interaction of the individual components that make up the system.	\N
3	1	3	You are able to analyze your present system and derive continuous improvements from it.	\N
4	1	4	You are able to carry systemic thinking into the company and inspire others for it.	\N
5	4	1	You are able to identify the lifecycle phases of your system.	\N
6	4	2	You understand why and how all lifecycle phases need to be considered during development.	\N
7	4	3	You are able to identify, consider, and assess all lifecycle phases relevant to your scope.	\N
8	4	4	You are able to evaluate concepts regarding the consideration of all lifecycle phases.	\N
9	5	1	You are able to identify the fundamental principles of agile thinking.	\N
10	5	2	You understand how to integrate agile thinking into daily work.	\N
11	5	3	You are able to develop a system using agile methodologies and focus on customer benefit.	\N
12	5	4	You are able to promote agile thinking within the organization and inspire others.	\N
13	8	1	You are aware of the necessity of Leadership competencies.	\N
14	8	2	You understand the relevance of defining objectives for a system and can articulate these objectives clearly to the entire team.	\N
15	8	3	You are able to negotiate objectives with your team and find an efficient path to achieve them.	\N
16	8	4	You are able to strategically develop team members so that they evolve in their problem-solving capabilities.	\N
17	7	1	You are aware of the necessity of Communication competencies.	\N
18	7	2	You recognize and understand the relevance of Communication competency, especially in terms of its application in systems engineering.	\N
19	7	3	You are able to communicate constructively and efficiently while being empathetic towards your communication partner.	\N
20	7	4	You are able to sustain and fairly manage your relationships with colleagues and supervisors.	\N
21	9	1	You are aware of the concepts of self-organization.	\N
22	9	2	You understand how self-organization concepts can influence your daily work.	\N
23	9	3	You are able to independently manage projects, processes, and tasks using self-organization skills.	\N
24	9	4	You can masterfully manage and optimize complex projects and processes through self-organization.	\N
25	10	1	You are able to identify your activities within a project plan. You are familiar with common project management methods.	\N
26	10	2	You understand the project mandate and can contextualize project management within systems engineering. You can create relevant project plans and generate corresponding status reports independently.	\N
27	10	3	You are able to define a project mandate, establish conditions, create complex project plans, and produce meaningful reports. You are skilled in communicating with stakeholders.	\N
28	10	4	You can identify inadequacies in the process and suggest improvements. You can successfully communicate reports, plans, and mandates to all stakeholders.	\N
29	11	1	You are aware of the main decision-making bodies and understand how decisions are made.	\N
30	11	2	You understand decision support methods and know which decisions you can make yourself and which are made by committees.	\N
31	11	3	You are able to prepare or make decisions for your relevant scopes and document them accordingly. You can apply decision support methods, such as utility analysis.	\N
32	11	4	You can evaluate decisions and are able to define and establish overarching decision-making bodies. You can define good guidelines for making decisions.	\N
33	12	1	You are aware of the benefits of established information and knowledge management.	\N
34	12	2	You understand the key platforms for knowledge transfer and know which information needs to be shared with whom.	\N
35	12	3	You are able to define storage structures and documentation guidelines for projects, and can provide relevant information at the right place.	\N
36	12	4	You can define a comprehensive information management process.	\N
37	13	1	You are aware of the necessity of configuration management. You know which tools are used to create configurations.	\N
38	13	2	You understand the process of defining configuration items and can identify those relevant to you. You are able to use the tools necessary to create configurations for your scopes.	\N
39	13	3	You can define sensible configuration items and recognize those relevant to you. You are capable of using tools to define configuration items and create configurations for your scopes.	\N
40	13	4	You are able to recognize all relevant configuration items and create a comprehensive configuration across all items. You can identify improvements, propose solutions, and assist others in configuration management.	\N
41	14	1	You are able to distinguish between needs, stakeholder requirements, system requirements, and system element requirements. You understand the importance of traceability and why tools are necessary for it. You know the basic process of requirement management including identifying, formulating, deriving and analyzing requirements.	\N
42	14	2	You understand how to identify sources of requirements, derive and write them. You know the different types and levels of requirements. You can read requirement documents or models (links, etc.). You can read and understand context descriptions and interface specifications.	\N
43	14	3	You can independently identify sources of requirements, derive, write, and document requirements in documents or models, link, derive, and analyze them. You can independently document, link, and analyze requirement documents or models. You can create and analyze context descriptions and interface specifications.	\N
44	14	4	You are able to recognize deficiencies in the process and develop suggestions for improvement. You can create context and interface descriptions and discuss these with stakeholders.	\N
45	15	1	You are aware of the purpose of architectural models and can broadly categorize them in the development process. You know that there is a dedicated methodology and modelling language for architectural modelling.	\N
46	15	2	You understand why architectural models are relevant as inputs and outputs of the development process. You can read architectural models and extract relevant information from them.	\N
47	15	3	You know the relevant process steps for architectural models, where their inputs come from, and the outputs they produce within the development process. You can create architectural models of average complexity, ensuring the information is reproducible and aligned with the methodology and modeling language.	\N
48	15	4	You can identify shortcomings in the process and develop suggestions for improvement. You are capable of creating and managing highly complex models, recognizing deficiencies in the method or modeling language, and suggesting improvements.	\N
49	17	1	You are familiar with the stages of operation, service, and maintenance phases. You understand these are considered during development and involve activities in each phase.	\N
50	17	2	You understand how the operation, service, and maintenance phases are integrated into the development. You are able to list the activities required throughout the lifecycle.	\N
51	17	3	You can execute the operation, service, and maintenance phases and identify improvements for future projects.	\N
52	17	4	You are able to define organizational processes for operation, maintenance, and servicing.	\N
53	18	1	You are able to recognize and list the Agile values and relevant Agile methods. You are aware of the basic principles of Agile methodologies.	\N
54	18	2	You understand the fundamentals of Agile workflows and how to apply Agile methods within a development process. You are able to explain the impact of Agile practices on project success.	\N
55	18	3	You can effectively work in an Agile environment and apply the necessary methods. You are able to adapt Agile techniques to various project scenarios.	\N
56	18	4	You can define and implement the relevant Agile methods for a project, and are convinced of the benefits of using Agile methods. You can motivate others to adopt Agile methods and lead Agile teams successfully.	\N
57	6	1	You are familiar with the basics of modelling and its benefits.	\N
58	6	2	You understand how models support your work and are able to read simple models.	\N
59	6	3	You are able to define your own system models for the relevant scope independently and can differentiate between cross-domain and domain-specific models.	\N
60	6	4	You can set guidelines for necessary models and write guidelines for good modelling practices.	\N
61	16	1	You are aware of the objectives of verification and validation and know various types and approaches of V&V.	\N
62	16	2	You can read and understand test plans, test cases, and results.	\N
63	16	3	You can create test plans and are capable of conducting and documenting tests and simulations.	\N
64	16	4	You are able to independently and proactively set up a testing strategy and an experimental plan. Based on requirements and verification/validation criteria, you can derive necessary test cases and orchestrate and document the tests and simulations.	\N
\.


--
-- Data for Name: iso_activities; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.iso_activities (id, name, process_id) FROM stdin;
\.


--
-- Data for Name: iso_processes; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.iso_processes (id, name, description, life_cycle_process_id) FROM stdin;
1	Acquisition	Acquire products or services	1
2	Supply	Provide products or services	1
3	Life Cycle Model Management	Define and manage life cycle models	2
4	Infrastructure Management	Provide infrastructure for projects	2
5	Portfolio Management	Manage organizational portfolio	2
6	Human Resource Management	Provide qualified human resources	2
7	Quality Management	Ensure quality objectives are achieved	2
8	Project Planning	Plan and schedule project activities	3
9	Project Assessment and Control	Assess and control project progress	3
10	Decision Management	Make informed decisions	3
11	Risk Management	Identify and manage risks	3
12	Configuration Management	Manage system configurations	3
13	Information Management	Manage project information	3
14	Measurement	Measure products and processes	3
15	Business or Mission Analysis	Define business or mission problem/opportunity	4
16	Stakeholder Needs and Requirements Definition	Define stakeholder requirements	4
17	System Requirements Definition	Transform stakeholder requirements into technical requirements	4
18	System Architecture Definition	Define system architecture and design	4
19	Design Definition	Create detailed system design	4
20	System Analysis	Analyze system to support decisions	4
21	Implementation	Realize system elements	4
22	Integration	Combine system elements into complete system	4
23	Verification	Confirm requirements are fulfilled	4
24	Transition	Establish capability to provide services	4
25	Validation	Confirm system fulfills intended use	4
26	Operation	Use system to deliver services	4
27	Maintenance	Sustain system capability	4
28	Disposal	End system existence	4
29	Maintenance process		4
30	Disposal process		4
\.


--
-- Data for Name: iso_system_life_cycle_processes; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.iso_system_life_cycle_processes (id, name) FROM stdin;
1	Agreement Processes
2	Organizational Project-Enabling Processes
3	Technical Management Processes
4	Technical Processes
\.


--
-- Data for Name: iso_tasks; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.iso_tasks (id, name, activity_id) FROM stdin;
\.


--
-- Data for Name: learning_modules; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.learning_modules (id, uuid, module_code, name, category, competency_id, definition, overview, industry_relevance, level_1_content, level_2_content, level_3_4_content, level_5_6_content, prerequisites, dependencies, industry_adaptations, total_duration_hours, difficulty_level, version, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: learning_objectives; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.learning_objectives (id, uuid, user_id, competency_id, text, type, priority, smart_score, smart_analysis, context_relevance, validation_status, rag_sources, generation_metadata, created_at) FROM stdin;
\.


--
-- Data for Name: learning_paths; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.learning_paths (id, uuid, name, description, path_type, target_audience, module_sequence, estimated_duration_weeks, difficulty_progression, industry_focus, role_focus, experience_level, completion_criteria, assessment_strategy, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: learning_plans; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.learning_plans (id, user_id, organization_id, objectives, recommended_modules, estimated_duration_weeks, archetype_used, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: learning_resources; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.learning_resources (id, uuid, module_id, title, resource_type, format, description, url, file_path, content_data, target_levels, prerequisites, difficulty_rating, quality_rating, usage_count, average_completion_time, author, source, language, last_updated, is_active, created_at) FROM stdin;
\.


--
-- Data for Name: maturity_assessments; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.maturity_assessments (id, organization_id, scope_score, process_score, overall_maturity, overall_score, responses, completed_at) FROM stdin;
\.


--
-- Data for Name: module_assessments; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.module_assessments (id, uuid, enrollment_id, assessment_type, level_assessed, score, max_score, pass_threshold, passed, questions_data, responses_data, feedback, time_taken_minutes, attempt_number, competency_demonstration, started_at, completed_at) FROM stdin;
\.


--
-- Data for Name: module_enrollments; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.module_enrollments (id, uuid, user_id, module_id, target_level, current_level, status, progress_percentage, time_spent_hours, learning_style_preference, engagement_score, completion_quality, enrolled_at, started_at, completed_at, last_accessed_at) FROM stdin;
\.


--
-- Data for Name: new_survey_user; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.new_survey_user (id, username, created_at, survey_completion_status) FROM stdin;
2	se_survey_user_2	2025-10-23 00:06:33.723174	t
3	se_survey_user_3	2025-10-23 00:07:25.077833	t
4	se_survey_user_4	2025-10-23 00:09:23.456921	t
5	se_survey_user_5	2025-10-23 00:13:49.930227	t
6	se_survey_user_6	2025-10-23 00:24:47.854237	t
7	se_survey_user_7	2025-10-23 00:48:34.810255	t
8	se_survey_user_8	2025-10-23 01:04:54.391305	t
9	se_survey_user_9	2025-10-23 01:40:11.127868	t
10	se_survey_user_10	2025-10-23 02:03:44.673426	t
11	se_survey_user_11	2025-10-23 02:25:52.106269	t
\.


--
-- Data for Name: organization; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.organization (id, organization_name, organization_public_key, size, maturity_score, selected_archetype, phase1_completed, created_at) FROM stdin;
1	Test Org	D0E45A175B205355	10-50	\N	\N	f	2025-10-20 23:53:06.863343
2	admin_user Gmbh	548EC388A22CB85C	medium	\N	\N	f	2025-10-20 23:57:12.300137
3	Test Organization	038EBCB6F8AE3921	10-50	\N	\N	f	2025-10-21 00:03:13.167785
4	admin_tester gmbh	14A988CC4CB19886	large	\N	\N	f	2025-10-21 00:05:08.389405
5	admin_tests	FD238304CD9E1618	medium	\N	\N	f	2025-10-21 00:06:30.340678
6	yoloman gmbh	E34D70C7CD9A121E	small	\N	\N	f	2025-10-21 00:07:22.969679
7	hopethisworks	DABBB1696ECECE72	large	\N	\N	f	2025-10-21 00:08:57.192841
8	goofyman gmbh	34298DE867C7AFCB	medium	\N	\N	f	2025-10-21 00:11:50.753387
9	qwerty1 gmbh	7CAEE398AC3984FF	large	\N	\N	f	2025-10-21 00:16:02.336821
10	someoneuser	6C2B24C3661580D1	large	\N	\N	f	2025-10-21 00:22:40.212966
11	testtest gmbh	94D77D50D6753BA3	large	\N	\N	f	2025-10-21 00:28:01.112229
12	batman1 Gmbh	F8CE7400F3ADFDCE	large	\N	\N	f	2025-10-21 00:58:34.983957
15	spartacus orgs	B82AF8AE8E385FCC	small	\N	\N	f	2025-10-21 03:52:44.464674
16	testtester Gmbh	BEAEC7DBAE6F72C3	large	\N	\N	f	2025-10-21 14:23:54.364055
17	somerandomguy's people	A06E62CF9F0CDC71	large	\N	\N	f	2025-10-21 22:01:33.869012
18	welpme folks	D14016B870976956	enterprise	39.9	\N	t	2025-10-21 22:45:52.399301
19	imbatman people	7287EF86B6ECFA5E	small	39.9	\N	t	2025-10-22 00:15:17.354765
20	reeguy peeps	F2EBFCBBABF9895B	small	39.9	\N	t	2025-10-23 01:33:07.942871
\.


--
-- Data for Name: phase_questionnaire_responses; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.phase_questionnaire_responses (id, user_id, organization_id, questionnaire_type, phase, responses, computed_scores, completed_at) FROM stdin;
18a48e51-9dd4-4914-a972-6e5c007a51e2	13	11	maturity	1	{"rolloutScope": 2, "seRolesProcesses": 2, "seMindset": 4, "knowledgeBase": 3}	{"rawScore": 64, "balancePenalty": 2.3, "finalScore": 61.7, "maturityLevel": 4, "maturityName": "Managed", "maturityColor": "#10B981", "maturityDescription": "SE is systematically implemented company-wide with quantitative management.", "balanceScore": 76.7, "profileType": "Culture-Centric", "fieldScores": {"rolloutScope": 50, "seRolesProcesses": 40, "seMindset": 100, "knowledgeBase": 75}, "weakestField": {"field": "SE Processes & Roles", "value": 40}, "strongestField": {"field": "SE Mindset", "value": 100}, "normalizedValues": {"rolloutScope": 0.5, "seRolesProcesses": 0.4, "seMindset": 1, "knowledgeBase": 0.75}, "strategyInputs": {"seProcessesValue": 2, "rolloutScopeValue": 2, "seMindsetValue": 4, "knowledgeBaseValue": 3}}	2025-10-21 01:31:47.3842
60e7f27a-77b3-4d3f-8c23-8268d48ed423	13	11	maturity	1	{"rolloutScope": 0, "seRolesProcesses": 2, "seMindset": 3, "knowledgeBase": 0}	{"rawScore": 32.8, "balancePenalty": 3.1, "finalScore": 29.6, "maturityLevel": 2, "maturityName": "Developing", "maturityColor": "#F59E0B", "maturityDescription": "Organization is beginning to adopt SE practices in isolated areas.", "balanceScore": 68.7, "profileType": "Unbalanced Development", "fieldScores": {"rolloutScope": 0, "seRolesProcesses": 40, "seMindset": 75, "knowledgeBase": 0}, "weakestField": {"field": "Rollout Scope", "value": 0}, "strongestField": {"field": "SE Mindset", "value": 75}, "normalizedValues": {"rolloutScope": 0, "seRolesProcesses": 0.4, "seMindset": 0.75, "knowledgeBase": 0}, "strategyInputs": {"seProcessesValue": 2, "rolloutScopeValue": 0, "seMindsetValue": 3, "knowledgeBaseValue": 0}}	2025-10-21 02:18:21.735726
ad5da7b1-d66a-4e4e-9abb-2d61c9acbf21	13	11	maturity	1	{"rolloutScope": 4, "seRolesProcesses": 4, "seMindset": 3, "knowledgeBase": 4}	{"rawScore": 86.8, "balancePenalty": 1.1, "finalScore": 85.6, "maturityLevel": 5, "maturityName": "Optimized", "maturityColor": "#059669", "maturityDescription": "SE excellence achieved with continuous optimization.", "balanceScore": 88.6, "profileType": "Balanced Development", "fieldScores": {"rolloutScope": 100, "seRolesProcesses": 80, "seMindset": 75, "knowledgeBase": 100}, "weakestField": {"field": "SE Mindset", "value": 75}, "strongestField": {"field": "Knowledge Base", "value": 100}, "normalizedValues": {"rolloutScope": 1, "seRolesProcesses": 0.8, "seMindset": 0.75, "knowledgeBase": 1}, "strategyInputs": {"seProcessesValue": 4, "rolloutScopeValue": 4, "seMindsetValue": 3, "knowledgeBaseValue": 4}}	2025-10-21 02:18:30.891672
6309b81a-ffc2-4f9d-acc6-62407ff9efc8	13	11	maturity	1	{"rolloutScope": 4, "seRolesProcesses": 2, "seMindset": 3, "knowledgeBase": 4}	{"rawScore": 72.8, "balancePenalty": 2.5, "finalScore": 70.3, "maturityLevel": 4, "maturityName": "Managed", "maturityColor": "#10B981", "maturityDescription": "SE is systematically implemented company-wide with quantitative management.", "balanceScore": 75.4, "profileType": "Deployment-Focused", "fieldScores": {"rolloutScope": 100, "seRolesProcesses": 40, "seMindset": 75, "knowledgeBase": 100}, "weakestField": {"field": "SE Processes & Roles", "value": 40}, "strongestField": {"field": "Knowledge Base", "value": 100}, "normalizedValues": {"rolloutScope": 1, "seRolesProcesses": 0.4, "seMindset": 0.75, "knowledgeBase": 1}, "strategyInputs": {"seProcessesValue": 2, "rolloutScopeValue": 4, "seMindsetValue": 3, "knowledgeBaseValue": 4}}	2025-10-21 02:18:46.091338
b764c6c8-2b60-4fec-88a5-9f279962eba2	13	11	maturity	1	{"rolloutScope": 0, "seRolesProcesses": 0, "seMindset": 3, "knowledgeBase": 1}	{"rawScore": 23.8, "balancePenalty": 3.1, "finalScore": 20.7, "maturityLevel": 2, "maturityName": "Developing", "maturityColor": "#F59E0B", "maturityDescription": "Organization is beginning to adopt SE practices in isolated areas.", "balanceScore": 69.4, "profileType": "Unbalanced Development", "fieldScores": {"rolloutScope": 0, "seRolesProcesses": 0, "seMindset": 75, "knowledgeBase": 25}, "weakestField": {"field": "Rollout Scope", "value": 0}, "strongestField": {"field": "SE Mindset", "value": 75}, "normalizedValues": {"rolloutScope": 0, "seRolesProcesses": 0, "seMindset": 0.75, "knowledgeBase": 0.25}, "strategyInputs": {"seProcessesValue": 0, "rolloutScopeValue": 0, "seMindsetValue": 3, "knowledgeBaseValue": 1}}	2025-10-21 02:18:55.105265
9dbe2063-e891-496f-88c2-fad8c7054ff0	21	18	roles	1	{"roles": [{"standardRoleId": 2, "standardRoleName": "Customer Representative", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}], "identification_method": "STANDARD"}	\N	2025-10-21 23:10:32.564667
ede61ebb-416b-4d0c-a54e-5fa610034cbd	21	18	target_group	1	{"id": "small", "range": "< 20", "category": "SMALL", "label": "Less than 20 people", "description": "Small group - suitable for intensive workshops", "value": 10, "implications": {"formats": ["Workshop", "Coaching", "Mentoring"], "approach": "Direct intensive training", "trainTheTrainer": false}}	\N	2025-10-21 23:10:35.55573
a4b04d6f-a911-46a7-a8b8-fa006615055e	13	11	maturity	1	{"rolloutScope": 2, "seRolesProcesses": 2, "seMindset": 2, "knowledgeBase": 2}	{"rawScore": 46.5, "balancePenalty": 0.4, "finalScore": 46.1, "maturityLevel": 3, "maturityName": "Defined", "maturityColor": "#EAB308", "maturityDescription": "SE processes and roles are formally defined and documented.", "balanceScore": 95.7, "profileType": "Balanced Development", "fieldScores": {"rolloutScope": 50, "seRolesProcesses": 40, "seMindset": 50, "knowledgeBase": 50}, "weakestField": {"field": "SE Processes & Roles", "value": 40}, "strongestField": {"field": "Knowledge Base", "value": 50}, "normalizedValues": {"rolloutScope": 0.5, "seRolesProcesses": 0.4, "seMindset": 0.5, "knowledgeBase": 0.5}, "strategyInputs": {"seProcessesValue": 2, "rolloutScopeValue": 2, "seMindsetValue": 2, "knowledgeBaseValue": 2}}	2025-10-21 02:21:18.852676
89c1f486-371b-4065-ac95-13a5a2f0be21	13	11	maturity	1	{"rolloutScope": 2, "seRolesProcesses": 2, "seMindset": 0, "knowledgeBase": 0}	{"rawScore": 24, "balancePenalty": 2.3, "finalScore": 21.7, "maturityLevel": 2, "maturityName": "Developing", "maturityColor": "#F59E0B", "maturityDescription": "Organization is beginning to adopt SE practices in isolated areas.", "balanceScore": 77.2, "profileType": "Balanced Development", "fieldScores": {"rolloutScope": 50, "seRolesProcesses": 40, "seMindset": 0, "knowledgeBase": 0}, "weakestField": {"field": "SE Mindset", "value": 0}, "strongestField": {"field": "Rollout Scope", "value": 50}, "normalizedValues": {"rolloutScope": 0.5, "seRolesProcesses": 0.4, "seMindset": 0, "knowledgeBase": 0}, "strategyInputs": {"seProcessesValue": 2, "rolloutScopeValue": 2, "seMindsetValue": 0, "knowledgeBaseValue": 0}}	2025-10-21 02:28:35.442322
21480011-2da8-408b-bd5f-1d9da0e60104	13	11	maturity	1	{"rolloutScope": 1, "seRolesProcesses": 1, "seMindset": 1, "knowledgeBase": 0}	{"rawScore": 18.3, "balancePenalty": 1, "finalScore": 17.2, "maturityLevel": 1, "maturityName": "Initial", "maturityColor": "#DC2626", "maturityDescription": "Organization has minimal or no Systems Engineering capability.", "balanceScore": 89.7, "profileType": "Balanced Development", "fieldScores": {"rolloutScope": 25, "seRolesProcesses": 20, "seMindset": 25, "knowledgeBase": 0}, "weakestField": {"field": "Knowledge Base", "value": 0}, "strongestField": {"field": "SE Mindset", "value": 25}, "normalizedValues": {"rolloutScope": 0.25, "seRolesProcesses": 0.2, "seMindset": 0.25, "knowledgeBase": 0}, "strategyInputs": {"seProcessesValue": 1, "rolloutScopeValue": 1, "seMindsetValue": 1, "knowledgeBaseValue": 0}}	2025-10-21 02:29:24.271521
b73b8d36-ec5c-4490-882f-5b76aa21c1ec	13	11	maturity	1	{"rolloutScope": 0, "seRolesProcesses": 2, "seMindset": 2, "knowledgeBase": 4}	{"rawScore": 46.5, "balancePenalty": 3.6, "finalScore": 39.9, "maturityLevel": 2, "maturityName": "Developing", "maturityColor": "#F59E0B", "maturityDescription": "Organization is beginning to adopt SE practices in isolated areas.", "balanceScore": 64.4, "profileType": "Unbalanced Development", "fieldScores": {"rolloutScope": 0, "seRolesProcesses": 40, "seMindset": 50, "knowledgeBase": 100}, "weakestField": {"field": "Rollout Scope", "value": 0}, "strongestField": {"field": "Knowledge Base", "value": 100}, "normalizedValues": {"rolloutScope": 0, "seRolesProcesses": 0.4, "seMindset": 0.5, "knowledgeBase": 1}, "strategyInputs": {"seProcessesValue": 2, "rolloutScopeValue": 0, "seMindsetValue": 2, "knowledgeBaseValue": 4}}	2025-10-21 02:35:42.728202
edc19515-3e57-46cb-ac0d-8851382a8c10	13	11	maturity	1	{"rolloutScope": 1, "seRolesProcesses": 1, "seMindset": 2, "knowledgeBase": 3}	{"rawScore": 39.5, "balancePenalty": 2.2, "finalScore": 37.3, "maturityLevel": 2, "maturityName": "Developing", "maturityColor": "#F59E0B", "maturityDescription": "Organization is beginning to adopt SE practices in isolated areas.", "balanceScore": 78.1, "profileType": "Knowledge-Focused", "fieldScores": {"rolloutScope": 25, "seRolesProcesses": 20, "seMindset": 50, "knowledgeBase": 75}, "weakestField": {"field": "SE Processes & Roles", "value": 20}, "strongestField": {"field": "Knowledge Base", "value": 75}, "normalizedValues": {"rolloutScope": 0.25, "seRolesProcesses": 0.2, "seMindset": 0.5, "knowledgeBase": 0.75}, "strategyInputs": {"seProcessesValue": 1, "rolloutScopeValue": 1, "seMindsetValue": 2, "knowledgeBaseValue": 3}}	2025-10-21 02:37:59.580048
6af3b2b8-3eb4-455c-ab90-b10a17174c49	1	11	task_process_mapping	1	{"username": "test_user", "tasks": {"responsible_for": ["Writing software code", "Testing applications"], "supporting": ["Code reviews"], "designing": ["Software architecture"]}, "processes": [{"process_name": "System Architecture Definition", "involvement": "Designing"}, {"process_name": "Design Definition", "involvement": "Responsible"}, {"process_name": "Implementation", "involvement": "Responsible"}, {"process_name": "Verification", "involvement": "Supporting"}, {"process_name": "Validation", "involvement": "Supporting"}]}	\N	2025-10-21 03:04:35.175789
0f1384f7-070c-451f-9cd0-da48948a3f52	13	11	maturity	1	{"rolloutScope": 2, "seRolesProcesses": 2, "seMindset": 2, "knowledgeBase": 2}	{"rawScore": 46.5, "balancePenalty": 0.4, "finalScore": 46.1, "maturityLevel": 3, "maturityName": "Defined", "maturityColor": "#EAB308", "maturityDescription": "SE processes and roles are formally defined and documented.", "balanceScore": 95.7, "profileType": "Balanced Development", "fieldScores": {"rolloutScope": 50, "seRolesProcesses": 40, "seMindset": 50, "knowledgeBase": 50}, "weakestField": {"field": "SE Processes & Roles", "value": 40}, "strongestField": {"field": "Knowledge Base", "value": 50}, "normalizedValues": {"rolloutScope": 0.5, "seRolesProcesses": 0.4, "seMindset": 0.5, "knowledgeBase": 0.5}, "strategyInputs": {"seProcessesValue": 2, "rolloutScopeValue": 2, "seMindsetValue": 2, "knowledgeBaseValue": 2}}	2025-10-21 03:07:42.989223
42e42e7f-b6a3-4187-80bc-6c99109c808d	1	11	task_process_mapping	1	{"username": "phase1_temp_1761016195600_yy19gun0r", "tasks": {"responsible_for": ["Developing embedded software modules for automotive control systems", "Writing unit tests and integration tests for software components", "Creating technical documentation for software designs", "Implementing software modules according to system specifications", "Debugging and fixing software defects"], "supporting": ["Code reviews for junior developers", "Helping team members troubleshoot technical issues", "Mentoring junior engineers in software best practices", "Supporting integration testing activities"], "designing": ["Software architecture for control modules", "Design patterns and coding standards", "Software development processes and workflows", "Continuous integration and deployment pipelines"]}, "processes": [{"process_name": "System Architecture Definition", "involvement": "Designing"}, {"process_name": "Design Definition", "involvement": "Designing"}, {"process_name": "Implementation", "involvement": "Responsible"}, {"process_name": "Integration", "involvement": "Supporting"}, {"process_name": "Verification", "involvement": "Supporting"}, {"process_name": "Validation", "involvement": "Supporting"}, {"process_name": "Maintenance", "involvement": "Supporting"}]}	\N	2025-10-21 03:10:00.611822
8d70d967-77e3-490a-ba30-56372aaeeed7	21	18	target_group	1	{"id": "xlarge", "range": "500-1500", "category": "VERY_LARGE", "label": "500 - 1500 people", "description": "Very large group - phased rollout recommended", "value": 1000, "implications": {"formats": ["E-Learning", "Train-the-Trainer", "Self-paced"], "approach": "Phased rollout with trainers", "trainTheTrainer": true}}	\N	2025-10-21 23:50:11.43052
8c269b74-3972-4d8d-82f7-209810d43a7d	1	11	task_process_mapping	1	{"username": "phase1_temp_1761016200940_mzdlnarpi", "tasks": {"responsible_for": ["Integrating software and hardware components into complete systems", "Coordinating interfaces between different system modules", "Defining integration test procedures and executing tests", "Managing system-level requirements and specifications", "Ensuring compatibility across system boundaries"], "supporting": ["System architecture reviews", "Requirements analysis and decomposition", "Stakeholder communication and coordination", "Risk assessment for integration activities"], "designing": ["System integration strategies and approaches", "Interface specifications between components", "Integration testing frameworks", "System verification procedures"]}, "processes": [{"process_name": "Risk Management", "involvement": "Supporting"}, {"process_name": "Stakeholder Needs and Requirements Definition", "involvement": "Responsible"}, {"process_name": "System Requirements Definition", "involvement": "Responsible"}, {"process_name": "System Architecture Definition", "involvement": "Supporting"}, {"process_name": "Design Definition", "involvement": "Designing"}, {"process_name": "Integration", "involvement": "Responsible"}, {"process_name": "Verification", "involvement": "Responsible"}, {"process_name": "Validation", "involvement": "Not performing"}]}	\N	2025-10-21 03:10:07.752087
eda2783e-bbe8-4725-8e85-666a29bc71f7	1	11	task_process_mapping	1	{"username": "phase1_temp_1761016208072_92q9esvce", "tasks": {"responsible_for": ["Developing and executing test plans for software and systems", "Identifying and documenting software defects", "Ensuring compliance with quality standards and regulations", "Performing regression testing on software releases", "Managing defect tracking and resolution processes"], "supporting": ["Process improvement initiatives", "Root cause analysis of quality issues", "Training team members on testing procedures", "Quality metrics collection and reporting"], "designing": ["Quality assurance processes and procedures", "Test automation frameworks", "Quality metrics and KPIs", "Continuous improvement initiatives"]}, "processes": [{"process_name": "Quality Management", "involvement": "Responsible"}, {"process_name": "Project Assessment and Control", "involvement": "Supporting"}, {"process_name": "Configuration Management", "involvement": "Not performing"}, {"process_name": "Measurement", "involvement": "Supporting"}, {"process_name": "Verification", "involvement": "Responsible"}, {"process_name": "Validation", "involvement": "Responsible"}]}	\N	2025-10-21 03:10:13.457069
d7fcc669-000a-4410-b7e6-803118835a96	1	11	task_process_mapping	1	{"username": "phase1_temp_1761016213780_dxef7n394", "tasks": {"responsible_for": ["Planning and coordinating technical project activities", "Monitoring project progress and managing resources", "Tracking project objectives and deliverables", "Managing project risks and issues", "Coordinating between technical teams and stakeholders"], "supporting": ["Technical decision-making processes", "Resource allocation and scheduling", "Stakeholder communication and reporting", "Team performance management"], "designing": ["Project management processes and templates", "Risk management strategies", "Communication workflows", "Team collaboration practices"]}, "processes": [{"process_name": "Project Planning", "involvement": "Responsible"}, {"process_name": "Project Assessment and Control", "involvement": "Responsible"}, {"process_name": "Decision Management", "involvement": "Supporting"}, {"process_name": "Risk Management", "involvement": "Responsible"}, {"process_name": "Information Management", "involvement": "Not performing"}, {"process_name": "Stakeholder Needs and Requirements Definition", "involvement": "Supporting"}, {"process_name": "System Requirements Definition", "involvement": "Not performing"}, {"process_name": "System Architecture Definition", "involvement": "Not performing"}, {"process_name": "Design Definition", "involvement": "Not performing"}]}	\N	2025-10-21 03:10:24.555105
97872af6-2900-44f3-8ded-d485b483a795	13	11	maturity	1	{"rolloutScope": 2, "seRolesProcesses": 2, "seMindset": 2, "knowledgeBase": 2}	{"rawScore": 46.5, "balancePenalty": 0.4, "finalScore": 46.1, "maturityLevel": 3, "maturityName": "Defined", "maturityColor": "#EAB308", "maturityDescription": "SE processes and roles are formally defined and documented.", "balanceScore": 95.7, "profileType": "Balanced Development", "fieldScores": {"rolloutScope": 50, "seRolesProcesses": 40, "seMindset": 50, "knowledgeBase": 50}, "weakestField": {"field": "SE Processes & Roles", "value": 40}, "strongestField": {"field": "Knowledge Base", "value": 50}, "normalizedValues": {"rolloutScope": 0.5, "seRolesProcesses": 0.4, "seMindset": 0.5, "knowledgeBase": 0.5}, "strategyInputs": {"seProcessesValue": 2, "rolloutScopeValue": 2, "seMindsetValue": 2, "knowledgeBaseValue": 2}}	2025-10-21 03:25:02.572762
02af5f22-d57d-4fcc-9ed7-f6dabdcd71e0	1	11	task_process_mapping	1	{"username": "phase1_temp_1761017154494_7y8xdy75t", "tasks": {"responsible_for": ["Planning and coordinating technical project activities", "Monitoring project progress and managing resources", "Tracking project objectives and deliverables", "Managing project risks and issues", "Coordinating between technical teams and stakeholders"], "supporting": ["Technical decision-making processes", "Resource allocation and scheduling", "Stakeholder communication and reporting", "Team performance management"], "designing": ["Project management processes and templates", "Risk management strategies", "Communication workflows", "Team collaboration practices"]}, "processes": [{"process_name": "Project Planning", "involvement": "Responsible"}, {"process_name": "Project Assessment and Control", "involvement": "Responsible"}, {"process_name": "Decision Management", "involvement": "Supporting"}, {"process_name": "Risk Management", "involvement": "Responsible"}, {"process_name": "Information Management", "involvement": "Supporting"}]}	\N	2025-10-21 03:25:59.410633
1a7a8df2-be07-4461-81d7-a6625a04e443	1	11	task_process_mapping	1	{"username": "phase1_temp_1761017159742_a8k9felke", "tasks": {"responsible_for": ["Designing electronic circuits and hardware components", "Creating schematics and PCB layouts", "Selecting components and materials for hardware designs", "Conducting hardware testing and validation", "Producing hardware documentation and specifications"], "supporting": ["System architecture development", "Design reviews and technical assessments", "Prototyping and proof-of-concept activities", "Troubleshooting hardware issues"], "designing": ["Hardware design methodologies", "Component selection criteria", "Testing procedures for hardware validation", "Design tools and workflows"]}, "processes": [{"process_name": "System Architecture Definition", "involvement": "Supporting"}, {"process_name": "Design Definition", "involvement": "Responsible"}, {"process_name": "Implementation", "involvement": "Not performing"}, {"process_name": "Verification", "involvement": "Not performing"}, {"process_name": "Validation", "involvement": "Responsible"}, {"process_name": "Maintenance", "involvement": "Not performing"}]}	\N	2025-10-21 03:26:04.928572
cc11f840-6e02-4727-9a85-2bfcaec52080	21	18	strategies	1	{"strategies": [{"strategy": "continuous_support", "strategyName": "Continuous Support", "priority": "PRIMARY", "reason": "SE is widely deployed - requires continuous support for sustainment", "userSelected": false, "autoRecommended": false, "warning": null}], "decision_path": [{"decision": "Add Train-the-Trainer", "reason": "Large target group requires multiplier approach", "step": 1}, {"decision": "Select Continuous Support", "reason": "Rollout scope is \\"Value Chain\\" - focus on continuous improvement", "step": 2}]}	\N	2025-10-22 00:12:30.502201
f7a0fb9e-08b7-47a3-86c5-53916487b8b4	17	15	maturity	1	{"rolloutScope": 2, "seRolesProcesses": 2, "seMindset": 2, "knowledgeBase": 2}	{"rawScore": 46.5, "balancePenalty": 0.4, "finalScore": 46.1, "maturityLevel": 3, "maturityName": "Defined", "maturityColor": "#EAB308", "maturityDescription": "SE processes and roles are formally defined and documented.", "balanceScore": 95.7, "profileType": "Balanced Development", "fieldScores": {"rolloutScope": 50, "seRolesProcesses": 40, "seMindset": 50, "knowledgeBase": 50}, "weakestField": {"field": "SE Processes & Roles", "value": 40}, "strongestField": {"field": "Knowledge Base", "value": 50}, "normalizedValues": {"rolloutScope": 0.5, "seRolesProcesses": 0.4, "seMindset": 0.5, "knowledgeBase": 0.5}, "strategyInputs": {"seProcessesValue": 2, "rolloutScopeValue": 2, "seMindsetValue": 2, "knowledgeBaseValue": 2}}	2025-10-21 03:55:39.905703
cf744b32-0263-42bc-bfef-386c995323b7	1	15	task_process_mapping	1	{"username": "phase1_temp_1761019144314_ceudlimcs", "tasks": {"responsible_for": ["Designing electronic circuits and hardware components", "Creating schematics and PCB layouts", "Selecting components and materials for hardware designs", "Conducting hardware testing and validation", "Producing hardware documentation and specifications"], "supporting": ["System architecture development", "Design reviews and technical assessments", "Prototyping and proof-of-concept activities", "Troubleshooting hardware issues"], "designing": ["Hardware design methodologies", "Component selection criteria", "Testing procedures for hardware validation", "Design tools and workflows"]}, "processes": [{"process_name": "Business or Mission Analysis", "involvement": "Not performing"}, {"process_name": "Stakeholder Needs and Requirements Definition", "involvement": "Not performing"}, {"process_name": "System Architecture Definition", "involvement": "Supporting"}, {"process_name": "Design Definition", "involvement": "Responsible"}, {"process_name": "Implementation", "involvement": "Not performing"}, {"process_name": "Integration", "involvement": "Not performing"}, {"process_name": "Verification", "involvement": "Not performing"}, {"process_name": "Validation", "involvement": "Responsible"}, {"process_name": "Maintenance", "involvement": "Not performing"}]}	\N	2025-10-21 03:59:11.79641
31c0e566-acd9-4c25-bbc2-81643d17a2ec	1	15	task_process_mapping	1	{"username": "phase1_temp_1761019339148_282cfkuz0", "tasks": {"responsible_for": ["Designing electronic circuits and hardware components", "Creating schematics and PCB layouts", "Selecting components and materials for hardware designs", "Conducting hardware testing and validation", "Producing hardware documentation and specifications"], "supporting": ["System architecture development", "Design reviews and technical assessments", "Prototyping and proof-of-concept activities", "Troubleshooting hardware issues"], "designing": ["Hardware design methodologies", "Component selection criteria", "Testing procedures for hardware validation", "Design tools and workflows"]}, "processes": [{"process_name": "System Architecture Definition", "involvement": "Supporting"}, {"process_name": "Design Definition", "involvement": "Responsible"}, {"process_name": "Implementation", "involvement": "Not performing"}, {"process_name": "Verification", "involvement": "Not performing"}, {"process_name": "Validation", "involvement": "Responsible"}, {"process_name": "Maintenance", "involvement": "Not performing"}]}	\N	2025-10-21 04:02:24.99565
3d062dbe-94c7-49aa-acc5-ea76b2103edb	17	15	maturity	1	{"rolloutScope": 2, "seRolesProcesses": 2, "seMindset": 2, "knowledgeBase": 2}	{"rawScore": 46.5, "balancePenalty": 0.4, "finalScore": 46.1, "maturityLevel": 3, "maturityName": "Defined", "maturityColor": "#EAB308", "maturityDescription": "SE processes and roles are formally defined and documented.", "balanceScore": 95.7, "profileType": "Balanced Development", "fieldScores": {"rolloutScope": 50, "seRolesProcesses": 40, "seMindset": 50, "knowledgeBase": 50}, "weakestField": {"field": "SE Processes & Roles", "value": 40}, "strongestField": {"field": "Knowledge Base", "value": 50}, "normalizedValues": {"rolloutScope": 0.5, "seRolesProcesses": 0.4, "seMindset": 0.5, "knowledgeBase": 0.5}, "strategyInputs": {"seProcessesValue": 2, "rolloutScopeValue": 2, "seMindsetValue": 2, "knowledgeBaseValue": 2}}	2025-10-21 04:04:32.441138
439b7ff8-ba02-4fbc-918a-37c083b43276	1	15	task_process_mapping	1	{"username": "phase1_temp_1761019496494_9h6b77ev2", "tasks": {"responsible_for": ["Designing electronic circuits and hardware components", "Creating schematics and PCB layouts", "Selecting components and materials for hardware designs", "Conducting hardware testing and validation", "Producing hardware documentation and specifications"], "supporting": ["System architecture development", "Design reviews and technical assessments", "Prototyping and proof-of-concept activities", "Troubleshooting hardware issues"], "designing": ["Hardware design methodologies", "Component selection criteria", "Testing procedures for hardware validation", "Design tools and workflows"]}, "processes": [{"process_name": "Business or Mission Analysis", "involvement": "Not performing"}, {"process_name": "System Requirements Definition", "involvement": "Not performing"}, {"process_name": "System Architecture Definition", "involvement": "Supporting"}, {"process_name": "Design Definition", "involvement": "Responsible"}, {"process_name": "Verification", "involvement": "Supporting"}, {"process_name": "Validation", "involvement": "Supporting"}]}	\N	2025-10-21 04:05:01.371116
6f6a67e2-e833-4df6-8778-d2c604ec5c6c	1	15	task_process_mapping	1	{"username": "phase1_temp_1761019757655_0kuif6je5", "tasks": {"responsible_for": ["Designing electronic circuits and hardware components", "Creating schematics and PCB layouts", "Selecting components and materials for hardware designs", "Conducting hardware testing and validation", "Producing hardware documentation and specifications"], "supporting": ["System architecture development", "Design reviews and technical assessments", "Prototyping and proof-of-concept activities", "Troubleshooting hardware issues"], "designing": ["Hardware design methodologies", "Component selection criteria", "Testing procedures for hardware validation", "Design tools and workflows"]}, "processes": [{"process_name": "System Architecture Definition", "involvement": "Supporting"}, {"process_name": "Design Definition", "involvement": "Responsible"}, {"process_name": "Implementation", "involvement": "Not performing"}, {"process_name": "Verification", "involvement": "Not performing"}, {"process_name": "Validation", "involvement": "Responsible"}, {"process_name": "Maintenance", "involvement": "Not performing"}]}	\N	2025-10-21 04:09:22.506316
5df50ca7-0adc-45f7-8140-08aaddceedc8	1	1	task_process_mapping	1	{"username": "test_user", "tasks": {"responsible_for": ["Developing software modules", "Writing unit tests"], "supporting": ["Code reviews"], "designing": ["Software architecture design"]}, "processes": [{"process_name": "System Architecture Definition", "involvement": "Designing"}, {"process_name": "Design Definition", "involvement": "Responsible"}, {"process_name": "Implementation", "involvement": "Responsible"}, {"process_name": "Verification", "involvement": "Supporting"}, {"process_name": "Validation", "involvement": "Supporting"}]}	\N	2025-10-21 04:17:41.995297
20f8ae18-81c7-4380-b19d-43c99e011194	17	15	maturity	1	{"rolloutScope": 1, "seRolesProcesses": 1, "seMindset": 1, "knowledgeBase": 1}	{"rawScore": 23.3, "balancePenalty": 0.2, "finalScore": 23, "maturityLevel": 2, "maturityName": "Developing", "maturityColor": "#F59E0B", "maturityDescription": "Organization is beginning to adopt SE practices in isolated areas.", "balanceScore": 97.8, "profileType": "Balanced Development", "fieldScores": {"rolloutScope": 25, "seRolesProcesses": 20, "seMindset": 25, "knowledgeBase": 25}, "weakestField": {"field": "SE Processes & Roles", "value": 20}, "strongestField": {"field": "Knowledge Base", "value": 25}, "normalizedValues": {"rolloutScope": 0.25, "seRolesProcesses": 0.2, "seMindset": 0.25, "knowledgeBase": 0.25}, "strategyInputs": {"seProcessesValue": 1, "rolloutScopeValue": 1, "seMindsetValue": 1, "knowledgeBaseValue": 1}}	2025-10-21 04:46:13.694315
1677cc62-e12e-4ab6-9265-8a2394d1ffb8	17	15	maturity	1	{"rolloutScope": 2, "seRolesProcesses": 2, "seMindset": 2, "knowledgeBase": 2}	{"rawScore": 46.5, "balancePenalty": 0.4, "finalScore": 46.1, "maturityLevel": 3, "maturityName": "Defined", "maturityColor": "#EAB308", "maturityDescription": "SE processes and roles are formally defined and documented.", "balanceScore": 95.7, "profileType": "Balanced Development", "fieldScores": {"rolloutScope": 50, "seRolesProcesses": 40, "seMindset": 50, "knowledgeBase": 50}, "weakestField": {"field": "SE Processes & Roles", "value": 40}, "strongestField": {"field": "Knowledge Base", "value": 50}, "normalizedValues": {"rolloutScope": 0.5, "seRolesProcesses": 0.4, "seMindset": 0.5, "knowledgeBase": 0.5}, "strategyInputs": {"seProcessesValue": 2, "rolloutScopeValue": 2, "seMindsetValue": 2, "knowledgeBaseValue": 2}}	2025-10-21 05:06:56.930028
baa99b53-01d7-403f-8f3f-51b2f946e053	17	15	maturity	1	{"rolloutScope": 1, "seRolesProcesses": 0, "seMindset": 2, "knowledgeBase": 4}	{"rawScore": 37.5, "balancePenalty": 3.7, "finalScore": 33.8, "maturityLevel": 2, "maturityName": "Developing", "maturityColor": "#F59E0B", "maturityDescription": "Organization is beginning to adopt SE practices in isolated areas.", "balanceScore": 63, "profileType": "Unbalanced Development", "fieldScores": {"rolloutScope": 25, "seRolesProcesses": 0, "seMindset": 50, "knowledgeBase": 100}, "weakestField": {"field": "SE Processes & Roles", "value": 0}, "strongestField": {"field": "Knowledge Base", "value": 100}, "normalizedValues": {"rolloutScope": 0.25, "seRolesProcesses": 0, "seMindset": 0.5, "knowledgeBase": 1}, "strategyInputs": {"seProcessesValue": 0, "rolloutScopeValue": 1, "seMindsetValue": 2, "knowledgeBaseValue": 4}}	2025-10-21 05:12:09.996516
49d00537-7248-4ff0-bc05-d9cbf9b25816	17	15	maturity	1	{"rolloutScope": 1, "seRolesProcesses": 1, "seMindset": 1, "knowledgeBase": 4}	{"rawScore": 38.3, "balancePenalty": 3.3, "finalScore": 34.9, "maturityLevel": 2, "maturityName": "Developing", "maturityColor": "#F59E0B", "maturityDescription": "Organization is beginning to adopt SE practices in isolated areas.", "balanceScore": 66.7, "profileType": "Unbalanced Development", "fieldScores": {"rolloutScope": 25, "seRolesProcesses": 20, "seMindset": 25, "knowledgeBase": 100}, "weakestField": {"field": "SE Processes & Roles", "value": 20}, "strongestField": {"field": "Knowledge Base", "value": 100}, "normalizedValues": {"rolloutScope": 0.25, "seRolesProcesses": 0.2, "seMindset": 0.25, "knowledgeBase": 1}, "strategyInputs": {"seProcessesValue": 1, "rolloutScopeValue": 1, "seMindsetValue": 1, "knowledgeBaseValue": 4}}	2025-10-21 05:16:02.04736
e33c9ebd-3694-44c1-bf21-7da3e24858ef	17	15	maturity	1	{"rolloutScope": 1, "seRolesProcesses": 1, "seMindset": 2, "knowledgeBase": 2}	{"rawScore": 34.5, "balancePenalty": 1.4, "finalScore": 33.1, "maturityLevel": 2, "maturityName": "Developing", "maturityColor": "#F59E0B", "maturityDescription": "Organization is beginning to adopt SE practices in isolated areas.", "balanceScore": 86.1, "profileType": "Balanced Development", "fieldScores": {"rolloutScope": 25, "seRolesProcesses": 20, "seMindset": 50, "knowledgeBase": 50}, "weakestField": {"field": "SE Processes & Roles", "value": 20}, "strongestField": {"field": "Knowledge Base", "value": 50}, "normalizedValues": {"rolloutScope": 0.25, "seRolesProcesses": 0.2, "seMindset": 0.5, "knowledgeBase": 0.5}, "strategyInputs": {"seProcessesValue": 1, "rolloutScopeValue": 1, "seMindsetValue": 2, "knowledgeBaseValue": 2}}	2025-10-21 05:20:23.439464
e4d018d5-619f-4b10-b205-5c5ff64bb4ba	18	16	maturity	1	{"rolloutScope": 1, "seRolesProcesses": 3, "seMindset": 4, "knowledgeBase": 4}	{"rawScore": 71, "balancePenalty": 3.1, "finalScore": 59.9, "maturityLevel": 3, "maturityName": "Defined", "maturityColor": "#EAB308", "maturityDescription": "SE processes and roles are formally defined and documented.", "balanceScore": 68.7, "profileType": "Unbalanced Development", "fieldScores": {"rolloutScope": 25, "seRolesProcesses": 60, "seMindset": 100, "knowledgeBase": 100}, "weakestField": {"field": "Rollout Scope", "value": 25}, "strongestField": {"field": "Knowledge Base", "value": 100}, "normalizedValues": {"rolloutScope": 0.25, "seRolesProcesses": 0.6, "seMindset": 1, "knowledgeBase": 1}, "strategyInputs": {"seProcessesValue": 3, "rolloutScopeValue": 1, "seMindsetValue": 4, "knowledgeBaseValue": 4}}	2025-10-21 14:25:39.247309
f42d581d-f056-495c-9f5e-21cacbc046ea	18	16	roles	1	{"roles": [{"standardRoleId": 1, "standardRoleName": "Customer", "orgRoleName": "jomon", "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 12, "standardRoleName": "Internal Support", "orgRoleName": "george", "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 11, "standardRoleName": "Process and Policy Manager", "orgRoleName": "thathanat", "identificationMethod": "STANDARD", "participatingInTraining": true}], "identification_method": "STANDARD"}	\N	2025-10-21 14:26:27.43767
73caa721-6512-461a-8af7-9b24d9099e1e	18	16	target_group	1	{"id": "medium", "range": "20-100", "category": "MEDIUM", "label": "20 - 100 people", "description": "Medium group - mixed format approach recommended", "value": 60, "implications": {"formats": ["Workshop", "Blended Learning", "Group Projects"], "approach": "Mixed format with cohorts", "trainTheTrainer": false}}	\N	2025-10-21 14:26:30.466571
0eda4a8e-7097-4225-a6a7-825252c8b260	18	16	maturity	1	{"rolloutScope": 1, "seRolesProcesses": 2, "seMindset": 4, "knowledgeBase": 4}	{"rawScore": 64, "balancePenalty": 3.4, "finalScore": 59.9, "maturityLevel": 3, "maturityName": "Defined", "maturityColor": "#EAB308", "maturityDescription": "SE processes and roles are formally defined and documented.", "balanceScore": 65.8, "profileType": "Unbalanced Development", "fieldScores": {"rolloutScope": 25, "seRolesProcesses": 40, "seMindset": 100, "knowledgeBase": 100}, "weakestField": {"field": "Rollout Scope", "value": 25}, "strongestField": {"field": "Knowledge Base", "value": 100}, "normalizedValues": {"rolloutScope": 0.25, "seRolesProcesses": 0.4, "seMindset": 1, "knowledgeBase": 1}, "strategyInputs": {"seProcessesValue": 2, "rolloutScopeValue": 1, "seMindsetValue": 4, "knowledgeBaseValue": 4}}	2025-10-21 14:28:16.124546
dbe33c1b-0405-4f06-8bdb-c4e49aa3254d	18	16	maturity	1	{"rolloutScope": 1, "seRolesProcesses": 2, "seMindset": 0, "knowledgeBase": 0}	{"rawScore": 19, "balancePenalty": 1.7, "finalScore": 17.3, "maturityLevel": 1, "maturityName": "Initial", "maturityColor": "#DC2626", "maturityDescription": "Organization has minimal or no Systems Engineering capability.", "balanceScore": 82.9, "profileType": "Balanced Development", "fieldScores": {"rolloutScope": 25, "seRolesProcesses": 40, "seMindset": 0, "knowledgeBase": 0}, "weakestField": {"field": "SE Mindset", "value": 0}, "strongestField": {"field": "SE Processes & Roles", "value": 40}, "normalizedValues": {"rolloutScope": 0.25, "seRolesProcesses": 0.4, "seMindset": 0, "knowledgeBase": 0}, "strategyInputs": {"seProcessesValue": 2, "rolloutScopeValue": 1, "seMindsetValue": 0, "knowledgeBaseValue": 0}}	2025-10-21 14:50:41.356669
5542167b-3707-4a46-bb31-013385ac3159	18	16	maturity	1	{"rolloutScope": 1, "seRolesProcesses": 2, "seMindset": 1, "knowledgeBase": 3}	{"rawScore": 40.3, "balancePenalty": 2, "finalScore": 38.2, "maturityLevel": 2, "maturityName": "Developing", "maturityColor": "#F59E0B", "maturityDescription": "Organization is beginning to adopt SE practices in isolated areas.", "balanceScore": 79.6, "profileType": "Knowledge-Focused", "fieldScores": {"rolloutScope": 25, "seRolesProcesses": 40, "seMindset": 25, "knowledgeBase": 75}, "weakestField": {"field": "Rollout Scope", "value": 25}, "strongestField": {"field": "Knowledge Base", "value": 75}, "normalizedValues": {"rolloutScope": 0.25, "seRolesProcesses": 0.4, "seMindset": 0.25, "knowledgeBase": 0.75}, "strategyInputs": {"seProcessesValue": 2, "rolloutScopeValue": 1, "seMindsetValue": 1, "knowledgeBaseValue": 3}}	2025-10-21 14:58:55.324423
74ea919f-f0e8-444f-a627-390dd650b7b6	18	16	maturity	1	{"rolloutScope": 2, "seRolesProcesses": 2, "seMindset": 2, "knowledgeBase": 2}	{"rawScore": 46.5, "balancePenalty": 0.4, "finalScore": 46.1, "maturityLevel": 3, "maturityName": "Defined", "maturityColor": "#EAB308", "maturityDescription": "SE processes and roles are formally defined and documented.", "balanceScore": 95.7, "profileType": "Balanced Development", "fieldScores": {"rolloutScope": 50, "seRolesProcesses": 40, "seMindset": 50, "knowledgeBase": 50}, "weakestField": {"field": "SE Processes & Roles", "value": 40}, "strongestField": {"field": "Knowledge Base", "value": 50}, "normalizedValues": {"rolloutScope": 0.5, "seRolesProcesses": 0.4, "seMindset": 0.5, "knowledgeBase": 0.5}, "strategyInputs": {"seProcessesValue": 2, "rolloutScopeValue": 2, "seMindsetValue": 2, "knowledgeBaseValue": 2}}	2025-10-21 15:42:10.036533
a2be414e-b3fd-472b-b744-e3dd171f3b7d	18	16	maturity	1	{"rolloutScope": 1, "seRolesProcesses": 1, "seMindset": 2, "knowledgeBase": 4}	{"rawScore": 44.5, "balancePenalty": 3.2, "finalScore": 41.3, "maturityLevel": 3, "maturityName": "Defined", "maturityColor": "#EAB308", "maturityDescription": "SE processes and roles are formally defined and documented.", "balanceScore": 68.3, "profileType": "Unbalanced Development", "fieldScores": {"rolloutScope": 25, "seRolesProcesses": 20, "seMindset": 50, "knowledgeBase": 100}, "weakestField": {"field": "SE Processes & Roles", "value": 20}, "strongestField": {"field": "Knowledge Base", "value": 100}, "normalizedValues": {"rolloutScope": 0.25, "seRolesProcesses": 0.2, "seMindset": 0.5, "knowledgeBase": 1}, "strategyInputs": {"seProcessesValue": 1, "rolloutScopeValue": 1, "seMindsetValue": 2, "knowledgeBaseValue": 4}}	2025-10-21 16:02:53.174935
d4d0c35d-8733-41c7-b5fe-0caa3b40af00	18	16	maturity	1	{"rolloutScope": 1, "seRolesProcesses": 1, "seMindset": 1, "knowledgeBase": 2}	{"rawScore": 28.2, "balancePenalty": 1.2, "finalScore": 27.1, "maturityLevel": 2, "maturityName": "Developing", "maturityColor": "#F59E0B", "maturityDescription": "Organization is beginning to adopt SE practices in isolated areas.", "balanceScore": 88.3, "profileType": "Balanced Development", "fieldScores": {"rolloutScope": 25, "seRolesProcesses": 20, "seMindset": 25, "knowledgeBase": 50}, "weakestField": {"field": "SE Processes & Roles", "value": 20}, "strongestField": {"field": "Knowledge Base", "value": 50}, "normalizedValues": {"rolloutScope": 0.25, "seRolesProcesses": 0.2, "seMindset": 0.25, "knowledgeBase": 0.5}, "strategyInputs": {"seProcessesValue": 1, "rolloutScopeValue": 1, "seMindsetValue": 1, "knowledgeBaseValue": 2}}	2025-10-21 16:14:56.1759
463c0495-b62c-42f0-a437-b3aa1cf08c05	18	16	maturity	1	{"rolloutScope": 1, "seRolesProcesses": 1, "seMindset": 2, "knowledgeBase": 4}	{"rawScore": 44.5, "balancePenalty": 3.2, "finalScore": 41.3, "maturityLevel": 3, "maturityName": "Defined", "maturityColor": "#EAB308", "maturityDescription": "SE processes and roles are formally defined and documented.", "balanceScore": 68.3, "profileType": "Unbalanced Development", "fieldScores": {"rolloutScope": 25, "seRolesProcesses": 20, "seMindset": 50, "knowledgeBase": 100}, "weakestField": {"field": "SE Processes & Roles", "value": 20}, "strongestField": {"field": "Knowledge Base", "value": 100}, "normalizedValues": {"rolloutScope": 0.25, "seRolesProcesses": 0.2, "seMindset": 0.5, "knowledgeBase": 1}, "strategyInputs": {"seProcessesValue": 1, "rolloutScopeValue": 1, "seMindsetValue": 2, "knowledgeBaseValue": 4}}	2025-10-21 16:27:24.901042
020818f1-5638-4077-aa14-dac9a3659077	18	16	maturity	1	{"rolloutScope": 2, "seRolesProcesses": 2, "seMindset": 2, "knowledgeBase": 4}	{"rawScore": 56.5, "balancePenalty": 2.3, "finalScore": 54.2, "maturityLevel": 3, "maturityName": "Defined", "maturityColor": "#EAB308", "maturityDescription": "SE processes and roles are formally defined and documented.", "balanceScore": 76.5, "profileType": "Knowledge-Focused", "fieldScores": {"rolloutScope": 50, "seRolesProcesses": 40, "seMindset": 50, "knowledgeBase": 100}, "weakestField": {"field": "SE Processes & Roles", "value": 40}, "strongestField": {"field": "Knowledge Base", "value": 100}, "normalizedValues": {"rolloutScope": 0.5, "seRolesProcesses": 0.4, "seMindset": 0.5, "knowledgeBase": 1}, "strategyInputs": {"seProcessesValue": 2, "rolloutScopeValue": 2, "seMindsetValue": 2, "knowledgeBaseValue": 4}}	2025-10-21 16:34:18.341694
de5015ea-63a8-4388-bb66-7a7fc7157fa9	18	16	maturity	1	{"rolloutScope": 1, "seRolesProcesses": 1, "seMindset": 1, "knowledgeBase": 1}	{"rawScore": 23.3, "balancePenalty": 0.2, "finalScore": 23, "maturityLevel": 2, "maturityName": "Developing", "maturityColor": "#F59E0B", "maturityDescription": "Organization is beginning to adopt SE practices in isolated areas.", "balanceScore": 97.8, "profileType": "Balanced Development", "fieldScores": {"rolloutScope": 25, "seRolesProcesses": 20, "seMindset": 25, "knowledgeBase": 25}, "weakestField": {"field": "SE Processes & Roles", "value": 20}, "strongestField": {"field": "Knowledge Base", "value": 25}, "normalizedValues": {"rolloutScope": 0.25, "seRolesProcesses": 0.2, "seMindset": 0.25, "knowledgeBase": 0.25}, "strategyInputs": {"seProcessesValue": 1, "rolloutScopeValue": 1, "seMindsetValue": 1, "knowledgeBaseValue": 1}}	2025-10-21 16:46:36.755742
a2b8d24f-a7a6-4edd-b513-1d10ec011e75	18	16	maturity	1	{"rolloutScope": 1, "seRolesProcesses": 2, "seMindset": 4, "knowledgeBase": 4}	{"rawScore": 64, "balancePenalty": 3.4, "finalScore": 59.9, "maturityLevel": 3, "maturityName": "Defined", "maturityColor": "#EAB308", "maturityDescription": "SE processes and roles are formally defined and documented.", "balanceScore": 65.8, "profileType": "Unbalanced Development", "fieldScores": {"rolloutScope": 25, "seRolesProcesses": 40, "seMindset": 100, "knowledgeBase": 100}, "weakestField": {"field": "Rollout Scope", "value": 25}, "strongestField": {"field": "Knowledge Base", "value": 100}, "normalizedValues": {"rolloutScope": 0.25, "seRolesProcesses": 0.4, "seMindset": 1, "knowledgeBase": 1}, "strategyInputs": {"seProcessesValue": 2, "rolloutScopeValue": 1, "seMindsetValue": 4, "knowledgeBaseValue": 4}}	2025-10-21 16:53:27.64794
b344f73c-72ea-42de-9b78-30b3902626ab	18	16	maturity	1	{"rolloutScope": 1, "seRolesProcesses": 2, "seMindset": 2, "knowledgeBase": 4}	{"rawScore": 51.5, "balancePenalty": 2.8, "finalScore": 48.7, "maturityLevel": 3, "maturityName": "Defined", "maturityColor": "#EAB308", "maturityDescription": "SE processes and roles are formally defined and documented.", "balanceScore": 71.9, "profileType": "Knowledge-Focused", "fieldScores": {"rolloutScope": 25, "seRolesProcesses": 40, "seMindset": 50, "knowledgeBase": 100}, "weakestField": {"field": "Rollout Scope", "value": 25}, "strongestField": {"field": "Knowledge Base", "value": 100}, "normalizedValues": {"rolloutScope": 0.25, "seRolesProcesses": 0.4, "seMindset": 0.5, "knowledgeBase": 1}, "strategyInputs": {"seProcessesValue": 2, "rolloutScopeValue": 1, "seMindsetValue": 2, "knowledgeBaseValue": 4}}	2025-10-21 16:59:42.83359
bf869903-6dc3-4921-a8c1-fb4cd3eba542	18	16	maturity	1	{"rolloutScope": 1, "seRolesProcesses": 0, "seMindset": 0, "knowledgeBase": 0}	{"rawScore": 5, "balancePenalty": 1.1, "finalScore": 3.9, "maturityLevel": 1, "maturityName": "Initial", "maturityColor": "#DC2626", "maturityDescription": "Organization has minimal or no Systems Engineering capability.", "balanceScore": 89.2, "profileType": "Balanced Development", "fieldScores": {"rolloutScope": 25, "seRolesProcesses": 0, "seMindset": 0, "knowledgeBase": 0}, "weakestField": {"field": "SE Processes & Roles", "value": 0}, "strongestField": {"field": "Rollout Scope", "value": 25}, "normalizedValues": {"rolloutScope": 0.25, "seRolesProcesses": 0, "seMindset": 0, "knowledgeBase": 0}, "strategyInputs": {"seProcessesValue": 0, "rolloutScopeValue": 1, "seMindsetValue": 0, "knowledgeBaseValue": 0}}	2025-10-21 17:05:54.191731
675fe015-1700-416d-a3a2-dc92eb046ae0	18	16	maturity	1	{"rolloutScope": 1, "seRolesProcesses": 1, "seMindset": 1, "knowledgeBase": 1}	{"rawScore": 23.3, "balancePenalty": 0.2, "finalScore": 23, "maturityLevel": 2, "maturityName": "Developing", "maturityColor": "#F59E0B", "maturityDescription": "Organization is beginning to adopt SE practices in isolated areas.", "balanceScore": 97.8, "profileType": "Balanced Development", "fieldScores": {"rolloutScope": 25, "seRolesProcesses": 20, "seMindset": 25, "knowledgeBase": 25}, "weakestField": {"field": "SE Processes & Roles", "value": 20}, "strongestField": {"field": "Knowledge Base", "value": 25}, "normalizedValues": {"rolloutScope": 0.25, "seRolesProcesses": 0.2, "seMindset": 0.25, "knowledgeBase": 0.25}, "strategyInputs": {"seProcessesValue": 1, "rolloutScopeValue": 1, "seMindsetValue": 1, "knowledgeBaseValue": 1}}	2025-10-21 17:18:40.861631
35abbd89-c348-4db1-9be3-6fc9f288ab5c	18	16	maturity	1	{"rolloutScope": 1, "seRolesProcesses": 1, "seMindset": 0, "knowledgeBase": 0}	{"rawScore": 12, "balancePenalty": 1.1, "finalScore": 10.9, "maturityLevel": 1, "maturityName": "Initial", "maturityColor": "#DC2626", "maturityDescription": "Organization has minimal or no Systems Engineering capability.", "balanceScore": 88.6, "profileType": "Balanced Development", "fieldScores": {"rolloutScope": 25, "seRolesProcesses": 20, "seMindset": 0, "knowledgeBase": 0}, "weakestField": {"field": "SE Mindset", "value": 0}, "strongestField": {"field": "Rollout Scope", "value": 25}, "normalizedValues": {"rolloutScope": 0.25, "seRolesProcesses": 0.2, "seMindset": 0, "knowledgeBase": 0}, "strategyInputs": {"seProcessesValue": 1, "rolloutScopeValue": 1, "seMindsetValue": 0, "knowledgeBaseValue": 0}}	2025-10-21 18:27:05.754192
b7c0efc8-2b05-4038-9b3b-2be0522f44a6	18	16	maturity	1	{"rolloutScope": 1, "seRolesProcesses": 0, "seMindset": 0, "knowledgeBase": 0}	{"rawScore": 5, "balancePenalty": 1.1, "finalScore": 3.9, "maturityLevel": 1, "maturityName": "Initial", "maturityColor": "#DC2626", "maturityDescription": "Organization has minimal or no Systems Engineering capability.", "balanceScore": 89.2, "profileType": "Balanced Development", "fieldScores": {"rolloutScope": 25, "seRolesProcesses": 0, "seMindset": 0, "knowledgeBase": 0}, "weakestField": {"field": "SE Processes & Roles", "value": 0}, "strongestField": {"field": "Rollout Scope", "value": 25}, "normalizedValues": {"rolloutScope": 0.25, "seRolesProcesses": 0, "seMindset": 0, "knowledgeBase": 0}, "strategyInputs": {"seProcessesValue": 0, "rolloutScopeValue": 1, "seMindsetValue": 0, "knowledgeBaseValue": 0}}	2025-10-21 19:52:57.197133
c2e4f55f-1092-430e-a317-610105c2e5c9	18	16	maturity	1	{"rolloutScope": 1, "seRolesProcesses": 0, "seMindset": 0, "knowledgeBase": 0}	{"rawScore": 5, "balancePenalty": 1.1, "finalScore": 3.9, "maturityLevel": 1, "maturityName": "Initial", "maturityColor": "#DC2626", "maturityDescription": "Organization has minimal or no Systems Engineering capability.", "balanceScore": 89.2, "profileType": "Balanced Development", "fieldScores": {"rolloutScope": 25, "seRolesProcesses": 0, "seMindset": 0, "knowledgeBase": 0}, "weakestField": {"field": "SE Processes & Roles", "value": 0}, "strongestField": {"field": "Rollout Scope", "value": 25}, "normalizedValues": {"rolloutScope": 0.25, "seRolesProcesses": 0, "seMindset": 0, "knowledgeBase": 0}, "strategyInputs": {"seProcessesValue": 0, "rolloutScopeValue": 1, "seMindsetValue": 0, "knowledgeBaseValue": 0}}	2025-10-21 20:20:41.184969
44bf077f-74ca-41a8-a69e-205723f1fcb8	18	16	maturity	1	{"rolloutScope": 0, "seRolesProcesses": 0, "seMindset": 0, "knowledgeBase": 0}	{"rawScore": 0, "balancePenalty": 0, "finalScore": 0, "maturityLevel": 1, "maturityName": "Initial", "maturityColor": "#DC2626", "maturityDescription": "Organization has minimal or no Systems Engineering capability.", "balanceScore": 100, "profileType": "Balanced Development", "fieldScores": {"rolloutScope": 0, "seRolesProcesses": 0, "seMindset": 0, "knowledgeBase": 0}, "weakestField": {"field": "Rollout Scope", "value": 0}, "strongestField": {"field": "Knowledge Base", "value": 0}, "normalizedValues": {"rolloutScope": 0, "seRolesProcesses": 0, "seMindset": 0, "knowledgeBase": 0}, "strategyInputs": {"seProcessesValue": 0, "rolloutScopeValue": 0, "seMindsetValue": 0, "knowledgeBaseValue": 0}}	2025-10-21 20:58:27.509474
e3fc4d5f-88c6-43d6-8b95-d33e6b3ab705	18	16	maturity	1	{"rolloutScope": 0, "seRolesProcesses": 0, "seMindset": 0, "knowledgeBase": 0}	{"rawScore": 0, "balancePenalty": 0, "finalScore": 0, "maturityLevel": 1, "maturityName": "Initial", "maturityColor": "#DC2626", "maturityDescription": "Organization has minimal or no Systems Engineering capability.", "balanceScore": 100, "profileType": "Balanced Development", "fieldScores": {"rolloutScope": 0, "seRolesProcesses": 0, "seMindset": 0, "knowledgeBase": 0}, "weakestField": {"field": "Rollout Scope", "value": 0}, "strongestField": {"field": "Knowledge Base", "value": 0}, "normalizedValues": {"rolloutScope": 0, "seRolesProcesses": 0, "seMindset": 0, "knowledgeBase": 0}, "strategyInputs": {"seProcessesValue": 0, "rolloutScopeValue": 0, "seMindsetValue": 0, "knowledgeBaseValue": 0}}	2025-10-21 21:02:41.432112
5f0f6786-b020-4df8-94dd-dd4b6f27156c	20	17	maturity	1	{"rolloutScope": 0, "seRolesProcesses": 2, "seMindset": 1, "knowledgeBase": 2}	{"rawScore": 30.3, "balancePenalty": 1.9, "finalScore": 28.4, "maturityLevel": 2, "maturityName": "Developing", "maturityColor": "#F59E0B", "maturityDescription": "Organization is beginning to adopt SE practices in isolated areas.", "balanceScore": 81.2, "profileType": "Balanced Development", "fieldScores": {"rolloutScope": 0, "seRolesProcesses": 40, "seMindset": 25, "knowledgeBase": 50}, "weakestField": {"field": "Rollout Scope", "value": 0}, "strongestField": {"field": "Knowledge Base", "value": 50}, "normalizedValues": {"rolloutScope": 0, "seRolesProcesses": 0.4, "seMindset": 0.25, "knowledgeBase": 0.5}, "strategyInputs": {"seProcessesValue": 2, "rolloutScopeValue": 0, "seMindsetValue": 1, "knowledgeBaseValue": 2}}	2025-10-21 22:03:43.11578
fd5afb3a-3f1b-4220-b24f-21933eeff8d0	20	17	roles	1	{"roles": [{"standardRoleId": 4, "standardRoleName": "System Engineer", "orgRoleName": "somebody", "jobDescription": "somebody", "mainTasks": {"responsible_for": ["Integrating software and hardware components into complete systems", "Coordinating interfaces between different system modules", "Defining integration test procedures and executing tests", "Managing system-level requirements and specifications", "Ensuring compatibility across system boundaries"], "supporting": ["System architecture reviews", "Requirements analysis and decomposition", "Stakeholder communication and coordination", "Risk assessment for integration activities"], "designing": ["System integration strategies and approaches", "Interface specifications between components", "Integration testing frameworks", "System verification procedures"]}, "isoProcesses": {"llm_role_suggestion": {"confidence": "High", "reasoning": "The user's tasks involve integrating software and hardware components, managing system-level requirements, and defining integration test procedures, which are core responsibilities of a System Engineer. Their involvement in designing integration strategies and supporting various ISO processes further solidifies this role, as it requires a comprehensive understanding of system architecture and interfaces.", "role_id": 4, "role_name": "System Engineer"}, "processes": [{"involvement": "Supporting", "process_name": "System requirements definition process"}, {"involvement": "Supporting", "process_name": "Stakeholder needs and requirements definition process"}, {"involvement": "Supporting", "process_name": "Risk management process"}, {"involvement": "Designing", "process_name": "System architecture definition process"}, {"involvement": "Not performing", "process_name": "Validation process"}, {"involvement": "Supporting", "process_name": "System analysis process"}, {"involvement": "Designing", "process_name": "Design definition process"}, {"involvement": "Responsible", "process_name": "Implementation process"}, {"involvement": "Not performing", "process_name": "Verification process"}, {"involvement": "Not performing", "process_name": "Operation process"}], "status": "success"}, "identificationMethod": "TASK_BASED", "confidenceScore": 95, "participatingInTraining": true}], "identification_method": "TASK_BASED"}	\N	2025-10-21 22:04:28.466339
c145727d-c9da-4d4e-b90c-6f5d21e0606f	20	17	target_group	1	{"id": "medium", "range": "20-100", "category": "MEDIUM", "label": "20 - 100 people", "description": "Medium group - mixed format approach recommended", "value": 60, "implications": {"formats": ["Workshop", "Blended Learning", "Group Projects"], "approach": "Mixed format with cohorts", "trainTheTrainer": false}}	\N	2025-10-21 22:04:34.655763
ca3e83bc-bae6-4536-be11-b7164a81d8d8	21	18	maturity	1	{"rolloutScope": 2, "seRolesProcesses": 3, "seMindset": 3, "knowledgeBase": 4}	{"rawScore": 69.8, "balancePenalty": 1.9, "finalScore": 67.9, "maturityLevel": 4, "maturityName": "Managed", "maturityColor": "#10B981", "maturityDescription": "SE is systematically implemented company-wide with quantitative management.", "balanceScore": 81.2, "profileType": "Knowledge-Focused", "fieldScores": {"rolloutScope": 50, "seRolesProcesses": 60, "seMindset": 75, "knowledgeBase": 100}, "weakestField": {"field": "Rollout Scope", "value": 50}, "strongestField": {"field": "Knowledge Base", "value": 100}, "normalizedValues": {"rolloutScope": 0.5, "seRolesProcesses": 0.6, "seMindset": 0.75, "knowledgeBase": 1}, "strategyInputs": {"seProcessesValue": 3, "rolloutScopeValue": 2, "seMindsetValue": 3, "knowledgeBaseValue": 4}}	2025-10-21 22:52:17.784418
f3b1c801-7b4f-43e1-876d-3f2bd7b4c497	21	18	roles	1	{"roles": [{"standardRoleId": 1, "standardRoleName": "Customer", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 2, "standardRoleName": "Customer Representative", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 3, "standardRoleName": "Project Manager", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 11, "standardRoleName": "Process and Policy Manager", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}], "identification_method": "STANDARD"}	\N	2025-10-21 22:52:32.336589
1dda85a9-4970-496a-b5dd-5029508af35c	21	18	target_group	1	{"id": "large", "range": "100-500", "category": "LARGE", "label": "100 - 500 people", "description": "Large group - consider train-the-trainer approach", "value": 300, "implications": {"formats": ["Blended Learning", "E-Learning", "Train-the-Trainer"], "approach": "Scalable formats required", "trainTheTrainer": true}}	\N	2025-10-21 22:52:37.538205
da119158-2c20-49d2-a2db-216a242b2f06	21	18	target_group	1	{"id": "xlarge", "range": "500-1500", "category": "VERY_LARGE", "label": "500 - 1500 people", "description": "Very large group - phased rollout recommended", "value": 1000, "implications": {"formats": ["E-Learning", "Train-the-Trainer", "Self-paced"], "approach": "Phased rollout with trainers", "trainTheTrainer": true}}	\N	2025-10-21 22:55:09.436141
c400cb5c-af39-4e4b-b2a3-70eaa0488049	21	18	maturity	1	{"rolloutScope": 0, "seRolesProcesses": 4, "seMindset": 1, "knowledgeBase": 4}	{"rawScore": 54.3, "balancePenalty": 4, "finalScore": 39.9, "maturityLevel": 2, "maturityName": "Developing", "maturityColor": "#F59E0B", "maturityDescription": "Organization is beginning to adopt SE practices in isolated areas.", "balanceScore": 59.6, "profileType": "Critically Unbalanced", "fieldScores": {"rolloutScope": 0, "seRolesProcesses": 80, "seMindset": 25, "knowledgeBase": 100}, "weakestField": {"field": "Rollout Scope", "value": 0}, "strongestField": {"field": "Knowledge Base", "value": 100}, "normalizedValues": {"rolloutScope": 0, "seRolesProcesses": 0.8, "seMindset": 0.25, "knowledgeBase": 1}, "strategyInputs": {"seProcessesValue": 4, "rolloutScopeValue": 0, "seMindsetValue": 1, "knowledgeBaseValue": 4}}	2025-10-21 23:09:13.868906
bb16fe4f-78a0-4225-9aee-58c09f932849	21	18	roles	1	{"roles": [{"standardRoleId": 1, "standardRoleName": "Customer", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 2, "standardRoleName": "Customer Representative", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 12, "standardRoleName": "Internal Support", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 10, "standardRoleName": "Service Technician", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}], "identification_method": "STANDARD"}	\N	2025-10-21 23:09:26.819665
e9e8b2d3-872b-458c-ac10-88683b2c4f4f	21	18	target_group	1	{"id": "large", "range": "100-500", "category": "LARGE", "label": "100 - 500 people", "description": "Large group - consider train-the-trainer approach", "value": 300, "implications": {"formats": ["Blended Learning", "E-Learning", "Train-the-Trainer"], "approach": "Scalable formats required", "trainTheTrainer": true}}	\N	2025-10-21 23:09:30.500724
0209e54a-5e5f-456d-9a4c-c8ead6d7bb09	21	18	maturity	1	{"rolloutScope": 4, "seRolesProcesses": 5, "seMindset": 4, "knowledgeBase": 4}	{"rawScore": 100, "balancePenalty": 0, "finalScore": 100, "maturityLevel": 5, "maturityName": "Optimized", "maturityColor": "#059669", "maturityDescription": "SE excellence achieved with continuous optimization.", "balanceScore": 100, "profileType": "Balanced Development", "fieldScores": {"rolloutScope": 100, "seRolesProcesses": 100, "seMindset": 100, "knowledgeBase": 100}, "weakestField": {"field": "Rollout Scope", "value": 100}, "strongestField": {"field": "Knowledge Base", "value": 100}, "normalizedValues": {"rolloutScope": 1, "seRolesProcesses": 1, "seMindset": 1, "knowledgeBase": 1}, "strategyInputs": {"seProcessesValue": 5, "rolloutScopeValue": 4, "seMindsetValue": 4, "knowledgeBaseValue": 4}}	2025-10-21 23:10:29.428011
5d98cdd1-d25b-4f16-9194-1997313e6375	21	18	maturity	1	{"rolloutScope": 4, "seRolesProcesses": 3, "seMindset": 2, "knowledgeBase": 1}	{"rawScore": 58.5, "balancePenalty": 2.7, "finalScore": 55.8, "maturityLevel": 3, "maturityName": "Defined", "maturityColor": "#EAB308", "maturityDescription": "SE processes and roles are formally defined and documented.", "balanceScore": 73, "profileType": "Deployment-Focused", "fieldScores": {"rolloutScope": 100, "seRolesProcesses": 60, "seMindset": 50, "knowledgeBase": 25}, "weakestField": {"field": "Knowledge Base", "value": 25}, "strongestField": {"field": "Rollout Scope", "value": 100}, "normalizedValues": {"rolloutScope": 1, "seRolesProcesses": 0.6, "seMindset": 0.5, "knowledgeBase": 0.25}, "strategyInputs": {"seProcessesValue": 3, "rolloutScopeValue": 4, "seMindsetValue": 2, "knowledgeBaseValue": 1}}	2025-10-21 23:19:10.310332
26181870-8059-4a37-b12d-75636bfca319	21	18	roles	1	{"roles": [{"standardRoleId": 1, "standardRoleName": "Customer", "orgRoleName": "oniisama", "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 2, "standardRoleName": "Customer Representative", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 10, "standardRoleName": "Service Technician", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 12, "standardRoleName": "Internal Support", "orgRoleName": "yamete", "identificationMethod": "STANDARD", "participatingInTraining": true}], "identification_method": "STANDARD"}	\N	2025-10-21 23:19:46.723687
590bec4e-997e-4280-b2d0-cc67a59b69c9	21	18	target_group	1	{"id": "medium", "range": "20-100", "category": "MEDIUM", "label": "20 - 100 people", "description": "Medium group - mixed format approach recommended", "value": 60, "implications": {"formats": ["Workshop", "Blended Learning", "Group Projects"], "approach": "Mixed format with cohorts", "trainTheTrainer": false}}	\N	2025-10-21 23:19:50.458985
0140f252-1460-41b9-8372-638283aaa712	21	18	strategies	1	{"strategies": [{"strategy": "continuous_support", "strategyName": "Continuous Support", "priority": "PRIMARY", "reason": "SE is widely deployed - requires continuous support for sustainment", "userSelected": false, "autoRecommended": false, "warning": null}], "decision_path": [{"decision": "Select Continuous Support", "reason": "Rollout scope is \\"Value Chain\\" - focus on continuous improvement", "step": 2}]}	\N	2025-10-21 23:20:02.877104
f10bb7de-e0f6-489d-8dc6-53204f0cf63e	21	18	maturity	1	{"rolloutScope": 0, "seRolesProcesses": 2, "seMindset": 3, "knowledgeBase": 4}	{"rawScore": 52.8, "balancePenalty": 3.8, "finalScore": 39.9, "maturityLevel": 2, "maturityName": "Developing", "maturityColor": "#F59E0B", "maturityDescription": "Organization is beginning to adopt SE practices in isolated areas.", "balanceScore": 62.4, "profileType": "Unbalanced Development", "fieldScores": {"rolloutScope": 0, "seRolesProcesses": 40, "seMindset": 75, "knowledgeBase": 100}, "weakestField": {"field": "Rollout Scope", "value": 0}, "strongestField": {"field": "Knowledge Base", "value": 100}, "normalizedValues": {"rolloutScope": 0, "seRolesProcesses": 0.4, "seMindset": 0.75, "knowledgeBase": 1}, "strategyInputs": {"seProcessesValue": 2, "rolloutScopeValue": 0, "seMindsetValue": 3, "knowledgeBaseValue": 4}}	2025-10-21 23:29:18.543334
8533e9d7-7e39-4aa4-94a1-ade051b9d803	21	18	roles	1	{"roles": [{"standardRoleId": 5, "standardRoleName": "Specialist Developer", "orgRoleName": "Hardware Design Engineer", "jobDescription": "Hardware Design Engineer", "mainTasks": {"responsible_for": ["Designing electronic circuits and hardware components", "Creating schematics and PCB layouts", "Selecting components and materials for hardware designs", "Conducting hardware testing and validation", "Producing hardware documentation and specifications"], "supporting": ["System architecture development", "Design reviews and technical assessments", "Prototyping and proof-of-concept activities", "Troubleshooting hardware issues"], "designing": ["Hardware design methodologies", "Component selection criteria", "Testing procedures for hardware validation", "Design tools and workflows"]}, "isoProcesses": {"llm_role_suggestion": {"confidence": "High", "reasoning": "The user's tasks primarily involve designing electronic circuits and hardware components, which aligns closely with the responsibilities of a Specialist Developer. They are also engaged in creating schematics, conducting testing, and producing documentation, indicating a strong technical focus in a specialized area of development.", "role_id": 5, "role_name": "Specialist Developer"}, "processes": [{"involvement": "Not performing", "process_name": "System requirements definition process"}, {"involvement": "Supporting", "process_name": "System architecture definition process"}, {"involvement": "Responsible", "process_name": "Design definition process"}, {"involvement": "Not performing", "process_name": "Stakeholder needs and requirements definition process"}, {"involvement": "Not performing", "process_name": "System analysis process"}, {"involvement": "Not performing", "process_name": "Implementation process"}, {"involvement": "Not performing", "process_name": "Validation process"}, {"involvement": "Not performing", "process_name": "Operation process"}, {"involvement": "Not performing", "process_name": "Transition process"}, {"involvement": "Not performing", "process_name": "Verification process"}], "status": "success"}, "identificationMethod": "TASK_BASED", "confidenceScore": 95, "participatingInTraining": true}, {"standardRoleId": 4, "standardRoleName": "System Engineer", "orgRoleName": "Systems Integration Engineer", "jobDescription": "Systems Integration Engineer", "mainTasks": {"responsible_for": ["Integrating software and hardware components into complete systems", "Coordinating interfaces between different system modules", "Defining integration test procedures and executing tests", "Managing system-level requirements and specifications", "Ensuring compatibility across system boundaries"], "supporting": ["System architecture reviews", "Requirements analysis and decomposition", "Stakeholder communication and coordination", "Risk assessment for integration activities"], "designing": ["System integration strategies and approaches", "Interface specifications between components", "Integration testing frameworks", "System verification procedures"]}, "isoProcesses": {"llm_role_suggestion": {"confidence": "High", "reasoning": "The user's tasks involve integrating software and hardware components, managing system-level requirements, and defining integration strategies, which are core responsibilities of a System Engineer. Their involvement in system architecture reviews and interface specifications further aligns with the role's focus on overseeing the entire system lifecycle from requirements to integration.", "role_id": 4, "role_name": "System Engineer"}, "processes": [{"involvement": "Supporting", "process_name": "System requirements definition process"}, {"involvement": "Supporting", "process_name": "Stakeholder needs and requirements definition process"}, {"involvement": "Designing", "process_name": "System architecture definition process"}, {"involvement": "Supporting", "process_name": "Risk management process"}, {"involvement": "Supporting", "process_name": "System analysis process"}, {"involvement": "Not performing", "process_name": "Validation process"}, {"involvement": "Designing", "process_name": "Design definition process"}, {"involvement": "Not performing", "process_name": "Verification process"}, {"involvement": "Not performing", "process_name": "Implementation process"}, {"involvement": "Not performing", "process_name": "Operation process"}], "status": "success"}, "identificationMethod": "TASK_BASED", "confidenceScore": 95, "participatingInTraining": true}], "identification_method": "TASK_BASED"}	\N	2025-10-21 23:31:51.123539
f2331df3-49b3-40d2-b8f4-9b9351738356	21	18	target_group	1	{"id": "xxlarge", "range": "> 1500", "category": "ENTERPRISE", "label": "More than 1500 people", "description": "Enterprise scale - comprehensive program required", "value": 2000, "implications": {"formats": ["E-Learning Platform", "Train-the-Trainer", "Learning Management System"], "approach": "Enterprise learning program", "trainTheTrainer": true}}	\N	2025-10-21 23:31:57.688445
dd80755b-3381-4408-bc77-00229e5eea40	21	18	strategies	1	{"strategies": [{"strategy": "train_the_trainer", "strategyName": "Train the SE-Trainer", "priority": "SUPPLEMENTARY", "reason": "With > 1500 people to train, a train-the-trainer approach will enable scalable knowledge transfer", "userSelected": false, "autoRecommended": false, "warning": "Strategy typically supports up to 10 participants. Consider multiple cohorts or alternative approach."}, {"strategy": "needs_based_project", "strategyName": "Needs-based Project-oriented Training", "priority": "PRIMARY", "reason": "SE processes are defined but not widely deployed - needs targeted project-based training", "userSelected": false, "autoRecommended": false, "warning": "Strategy typically supports up to 50 participants. Consider multiple cohorts or alternative approach."}, {"strategy": "certification", "strategyName": "Certification", "priority": "SUPPLEMENTARY", "reason": "Manually selected by user to meet specific organizational needs", "userSelected": true, "autoRecommended": false, "warning": null}], "decision_path": [{"decision": "Add Train-the-Trainer", "reason": "Large target group requires multiplier approach", "step": 1}, {"decision": "Select Needs-based Project-oriented Training", "reason": "Rollout scope is \\"Not Available\\" - requires expansion through project training", "step": 2}]}	\N	2025-10-21 23:32:27.220562
07707112-811e-40bc-aaff-8794127a1d87	21	18	maturity	1	{"rolloutScope": 0, "seRolesProcesses": 3, "seMindset": 2, "knowledgeBase": 4}	{"rawScore": 53.5, "balancePenalty": 3.6, "finalScore": 39.9, "maturityLevel": 2, "maturityName": "Developing", "maturityColor": "#F59E0B", "maturityDescription": "Organization is beginning to adopt SE practices in isolated areas.", "balanceScore": 64.4, "profileType": "Unbalanced Development", "fieldScores": {"rolloutScope": 0, "seRolesProcesses": 60, "seMindset": 50, "knowledgeBase": 100}, "weakestField": {"field": "Rollout Scope", "value": 0}, "strongestField": {"field": "Knowledge Base", "value": 100}, "normalizedValues": {"rolloutScope": 0, "seRolesProcesses": 0.6, "seMindset": 0.5, "knowledgeBase": 1}, "strategyInputs": {"seProcessesValue": 3, "rolloutScopeValue": 0, "seMindsetValue": 2, "knowledgeBaseValue": 4}}	2025-10-21 23:50:01.369834
3f1e06f0-6c79-4f8b-b5c1-6b1d8cfcb92b	21	18	strategies	1	{"strategies": [{"strategy": "train_the_trainer", "strategyName": "Train the SE-Trainer", "priority": "SUPPLEMENTARY", "reason": "With 500-1500 people to train, a train-the-trainer approach will enable scalable knowledge transfer", "userSelected": false, "autoRecommended": false, "warning": "Strategy typically supports up to 10 participants. Consider multiple cohorts or alternative approach."}, {"strategy": "needs_based_project", "strategyName": "Needs-based Project-oriented Training", "priority": "PRIMARY", "reason": "SE processes are defined but not widely deployed - needs targeted project-based training", "userSelected": false, "autoRecommended": false, "warning": "Strategy typically supports up to 50 participants. Consider multiple cohorts or alternative approach."}, {"strategy": "continuous_support", "strategyName": "Continuous Support", "priority": "SUPPLEMENTARY", "reason": "Manually selected by user to meet specific organizational needs", "userSelected": true, "autoRecommended": false, "warning": null}, {"strategy": "certification", "strategyName": "Certification", "priority": "SUPPLEMENTARY", "reason": "Manually selected by user to meet specific organizational needs", "userSelected": true, "autoRecommended": false, "warning": null}], "decision_path": [{"decision": "Add Train-the-Trainer", "reason": "Large target group requires multiplier approach", "step": 1}, {"decision": "Select Needs-based Project-oriented Training", "reason": "Rollout scope is \\"Not Available\\" - requires expansion through project training", "step": 2}]}	\N	2025-10-21 23:50:31.990614
6f4faaca-9d78-4da4-9354-6380a7b7446e	21	18	maturity	1	{"answers": {"rolloutScope": 3, "seRolesProcesses": 3, "seMindset": 2, "knowledgeBase": 2}, "results": {"rawScore": 58.5, "balancePenalty": 1, "finalScore": 57.5, "maturityLevel": 3, "maturityName": "Defined", "maturityColor": "#EAB308", "maturityDescription": "SE processes and roles are formally defined and documented.", "balanceScore": 89.8, "profileType": "Balanced Development", "fieldScores": {"rolloutScope": 75, "seRolesProcesses": 60, "seMindset": 50, "knowledgeBase": 50}, "weakestField": {"field": "SE Mindset", "value": 50}, "strongestField": {"field": "Rollout Scope", "value": 75}, "normalizedValues": {"rolloutScope": 0.75, "seRolesProcesses": 0.6, "seMindset": 0.5, "knowledgeBase": 0.5}, "strategyInputs": {"seProcessesValue": 3, "rolloutScopeValue": 3, "seMindsetValue": 2, "knowledgeBaseValue": 2}}}	\N	2025-10-22 00:09:15.123673
9dc8eb6b-f13b-4af5-9bca-7ef017406ac7	21	18	roles	1	{"roles": [{"standardRoleId": 5, "standardRoleName": "Specialist Developer", "orgRoleName": "Hardware Design Engineer", "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 4, "standardRoleName": "System Engineer", "orgRoleName": "Systems Integration Engineer", "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 1, "standardRoleName": "Customer", "orgRoleName": "neechan", "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 2, "standardRoleName": "Customer Representative", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}], "identification_method": "STANDARD"}	\N	2025-10-22 00:09:45.960068
4e9014c2-72fb-4db9-933f-e6559cba2cf3	21	18	target_group	1	{"id": "large", "range": "100-500", "category": "LARGE", "label": "100 - 500 people", "description": "Large group - consider train-the-trainer approach", "value": 300, "implications": {"formats": ["Blended Learning", "E-Learning", "Train-the-Trainer"], "approach": "Scalable formats required", "trainTheTrainer": true}}	\N	2025-10-22 00:09:50.814218
71ecbfd6-ac42-4d60-ab8f-b158afdf9c3e	21	18	strategies	1	{"strategies": [{"strategy": "train_the_trainer", "strategyName": "Train the SE-Trainer", "priority": "SUPPLEMENTARY", "reason": "With 100-500 people to train, a train-the-trainer approach will enable scalable knowledge transfer", "userSelected": false, "autoRecommended": false, "warning": "Strategy typically supports up to 10 participants. Consider multiple cohorts or alternative approach."}, {"strategy": "continuous_support", "strategyName": "Continuous Support", "priority": "PRIMARY", "reason": "SE is widely deployed - requires continuous support for sustainment", "userSelected": false, "autoRecommended": false, "warning": null}, {"strategy": "se_for_managers", "strategyName": "SE for Managers", "priority": "SUPPLEMENTARY", "reason": "Manually selected by user to meet specific organizational needs", "userSelected": true, "autoRecommended": false, "warning": null}], "decision_path": [{"decision": "Add Train-the-Trainer", "reason": "Large target group requires multiplier approach", "step": 1}, {"decision": "Select Continuous Support", "reason": "Rollout scope is \\"Company Wide\\" - focus on continuous improvement", "step": 2}]}	\N	2025-10-22 00:10:33.162743
616b65d6-1453-4b02-a04c-a211ca5a10fb	21	18	maturity	1	{"answers": {"rolloutScope": 4, "seRolesProcesses": 4, "seMindset": 2, "knowledgeBase": 0}, "results": {"rawScore": 60.5, "balancePenalty": 3.8, "finalScore": 39.9, "maturityLevel": 2, "maturityName": "Developing", "maturityColor": "#F59E0B", "maturityDescription": "Organization is beginning to adopt SE practices in isolated areas.", "balanceScore": 62.3, "profileType": "Unbalanced Development", "fieldScores": {"rolloutScope": 100, "seRolesProcesses": 80, "seMindset": 50, "knowledgeBase": 0}, "weakestField": {"field": "Knowledge Base", "value": 0}, "strongestField": {"field": "Rollout Scope", "value": 100}, "normalizedValues": {"rolloutScope": 1, "seRolesProcesses": 0.8, "seMindset": 0.5, "knowledgeBase": 0}, "strategyInputs": {"seProcessesValue": 4, "rolloutScopeValue": 4, "seMindsetValue": 2, "knowledgeBaseValue": 0}}}	\N	2025-10-22 00:11:50.115015
1aa0f621-34d1-4f66-82db-284054496fc2	21	18	roles	1	{"roles": [{"standardRoleId": 5, "standardRoleName": "Specialist Developer", "orgRoleName": "Hardware Design Engineer", "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 4, "standardRoleName": "System Engineer", "orgRoleName": "Systems Integration Engineer", "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 1, "standardRoleName": "Customer", "orgRoleName": "neechan", "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 2, "standardRoleName": "Customer Representative", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 3, "standardRoleName": "Project Manager", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 11, "standardRoleName": "Process and Policy Manager", "orgRoleName": "yolo", "identificationMethod": "STANDARD", "participatingInTraining": true}], "identification_method": "STANDARD"}	\N	2025-10-22 00:12:05.385511
e4fd9611-472d-4073-86a8-583ad2eae592	21	18	target_group	1	{"id": "xxlarge", "range": "> 1500", "category": "ENTERPRISE", "label": "More than 1500 people", "description": "Enterprise scale - comprehensive program required", "value": 2000, "implications": {"formats": ["E-Learning Platform", "Train-the-Trainer", "Learning Management System"], "approach": "Enterprise learning program", "trainTheTrainer": true}}	\N	2025-10-22 00:12:08.16026
7c1b5bad-42a2-4744-b316-064deb8121d5	23	19	maturity	1	{"answers": {"rolloutScope": 2, "seRolesProcesses": 3, "seMindset": 0, "knowledgeBase": 0}, "results": {"rawScore": 31, "balancePenalty": 2.8, "finalScore": 28.2, "maturityLevel": 2, "maturityName": "Developing", "maturityColor": "#F59E0B", "maturityDescription": "Organization is beginning to adopt SE practices in isolated areas.", "balanceScore": 72.3, "profileType": "Balanced Development", "fieldScores": {"rolloutScope": 50, "seRolesProcesses": 60, "seMindset": 0, "knowledgeBase": 0}, "weakestField": {"field": "SE Mindset", "value": 0}, "strongestField": {"field": "SE Processes & Roles", "value": 60}, "normalizedValues": {"rolloutScope": 0.5, "seRolesProcesses": 0.6, "seMindset": 0, "knowledgeBase": 0}, "strategyInputs": {"seProcessesValue": 3, "rolloutScopeValue": 2, "seMindsetValue": 0, "knowledgeBaseValue": 0}}}	\N	2025-10-22 00:15:43.949114
ca42d07e-f0af-4e7a-b62e-101d11b04ac1	23	19	roles	1	{"roles": [{"standardRoleId": 1, "standardRoleName": "Customer", "orgRoleName": "nande", "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 2, "standardRoleName": "Customer Representative", "orgRoleName": "gacha", "identificationMethod": "STANDARD", "participatingInTraining": true}], "identification_method": "STANDARD"}	\N	2025-10-22 00:16:02.247776
ad655075-9574-4e9a-aa42-67eafb83cb0d	23	19	target_group	1	{"id": "small", "range": "< 20", "category": "SMALL", "label": "Less than 20 people", "description": "Small group - suitable for intensive workshops", "value": 10, "implications": {"formats": ["Workshop", "Coaching", "Mentoring"], "approach": "Direct intensive training", "trainTheTrainer": false}}	\N	2025-10-22 00:16:07.762015
835925f9-5f16-4e20-a1ca-207e1dac1212	23	19	strategies	1	{"strategies": [{"strategy": "continuous_support", "strategyName": "Continuous Support", "priority": "PRIMARY", "reason": "SE is widely deployed - requires continuous support for sustainment", "userSelected": false, "autoRecommended": false, "warning": null}, {"strategy": "certification", "strategyName": "Certification", "priority": "SUPPLEMENTARY", "reason": "Manually selected by user to meet specific organizational needs", "userSelected": true, "autoRecommended": false, "warning": null}, {"strategy": "needs_based_project", "strategyName": "Needs-based Project-oriented Training", "priority": "SUPPLEMENTARY", "reason": "Manually selected by user to meet specific organizational needs", "userSelected": true, "autoRecommended": false, "warning": null}, {"strategy": "train_the_trainer", "strategyName": "Train the SE-Trainer", "priority": "SUPPLEMENTARY", "reason": "Manually selected by user to meet specific organizational needs", "userSelected": true, "autoRecommended": false, "warning": null}], "decision_path": [{"decision": "Select Continuous Support", "reason": "Rollout scope is \\"Development Area\\" - focus on continuous improvement", "step": 2}]}	\N	2025-10-22 00:16:56.266172
144dec1f-ba54-4d6d-accb-5038985d6137	23	19	maturity	1	{"answers": {"rolloutScope": 1, "seRolesProcesses": 3, "seMindset": 3, "knowledgeBase": 3}, "results": {"rawScore": 59.8, "balancePenalty": 2, "finalScore": 57.7, "maturityLevel": 3, "maturityName": "Defined", "maturityColor": "#EAB308", "maturityDescription": "SE processes and roles are formally defined and documented.", "balanceScore": 79.6, "profileType": "Culture-Centric", "fieldScores": {"rolloutScope": 25, "seRolesProcesses": 60, "seMindset": 75, "knowledgeBase": 75}, "weakestField": {"field": "Rollout Scope", "value": 25}, "strongestField": {"field": "Knowledge Base", "value": 75}, "normalizedValues": {"rolloutScope": 0.25, "seRolesProcesses": 0.6, "seMindset": 0.75, "knowledgeBase": 0.75}, "strategyInputs": {"seProcessesValue": 3, "rolloutScopeValue": 1, "seMindsetValue": 3, "knowledgeBaseValue": 3}}}	\N	2025-10-22 00:19:12.61828
23bb03bf-7fb4-49c5-a3ef-50902a77867d	23	19	roles	1	{"roles": [{"standardRoleId": 1, "standardRoleName": "Customer", "orgRoleName": "nande", "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 2, "standardRoleName": "Customer Representative", "orgRoleName": "gacha", "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 3, "standardRoleName": "Project Manager", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 11, "standardRoleName": "Process and Policy Manager", "orgRoleName": "amme", "identificationMethod": "STANDARD", "participatingInTraining": true}], "identification_method": "STANDARD"}	\N	2025-10-22 00:19:23.066093
d72de2fb-6fe9-463b-adf5-c015dda58cf3	23	19	target_group	1	{"id": "xxlarge", "range": "> 1500", "category": "ENTERPRISE", "label": "More than 1500 people", "description": "Enterprise scale - comprehensive program required", "value": 2000, "implications": {"formats": ["E-Learning Platform", "Train-the-Trainer", "Learning Management System"], "approach": "Enterprise learning program", "trainTheTrainer": true}}	\N	2025-10-22 00:19:26.78094
107b935f-e38a-4850-a3c4-3b18ad818f3d	23	19	strategies	1	{"strategies": [{"strategy": "train_the_trainer", "strategyName": "Train the SE-Trainer", "priority": "SUPPLEMENTARY", "reason": "With > 1500 people to train, a train-the-trainer approach will enable scalable knowledge transfer", "userSelected": false, "autoRecommended": false, "warning": "Strategy typically supports up to 10 participants. Consider multiple cohorts or alternative approach."}, {"strategy": "needs_based_project", "strategyName": "Needs-based Project-oriented Training", "priority": "PRIMARY", "reason": "SE processes are defined but not widely deployed - needs targeted project-based training", "userSelected": false, "autoRecommended": false, "warning": "Strategy typically supports up to 50 participants. Consider multiple cohorts or alternative approach."}], "decision_path": [{"decision": "Add Train-the-Trainer", "reason": "Large target group requires multiplier approach", "step": 1}, {"decision": "Select Needs-based Project-oriented Training", "reason": "Rollout scope is \\"Individual Area\\" - requires expansion through project training", "step": 2}]}	\N	2025-10-22 00:19:34.427827
a3fef630-f33b-45af-86d2-979147e7fe27	23	19	maturity	1	{"answers": {"rolloutScope": 1, "seRolesProcesses": 3, "seMindset": 0, "knowledgeBase": 3}, "results": {"rawScore": 41, "balancePenalty": 2.9, "finalScore": 38.1, "maturityLevel": 2, "maturityName": "Developing", "maturityColor": "#F59E0B", "maturityDescription": "Organization is beginning to adopt SE practices in isolated areas.", "balanceScore": 70.6, "profileType": "Knowledge-Focused", "fieldScores": {"rolloutScope": 25, "seRolesProcesses": 60, "seMindset": 0, "knowledgeBase": 75}, "weakestField": {"field": "SE Mindset", "value": 0}, "strongestField": {"field": "Knowledge Base", "value": 75}, "normalizedValues": {"rolloutScope": 0.25, "seRolesProcesses": 0.6, "seMindset": 0, "knowledgeBase": 0.75}, "strategyInputs": {"seProcessesValue": 3, "rolloutScopeValue": 1, "seMindsetValue": 0, "knowledgeBaseValue": 3}}}	\N	2025-10-22 00:30:02.031155
15d0171f-01b6-4e67-becc-09fa333b1594	23	19	roles	1	{"roles": [{"standardRoleId": 1, "standardRoleName": "Customer", "orgRoleName": "nande", "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 2, "standardRoleName": "Customer Representative", "orgRoleName": "gacha", "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 3, "standardRoleName": "Project Manager", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 11, "standardRoleName": "Process and Policy Manager", "orgRoleName": "amme", "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 12, "standardRoleName": "Internal Support", "orgRoleName": "Internal guy", "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 10, "standardRoleName": "Service Technician", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}], "identification_method": "STANDARD"}	\N	2025-10-22 00:30:22.714731
7e33a92c-8b6d-45bf-8b40-0142c576bf3c	23	19	target_group	1	{"id": "medium", "range": "20-100", "category": "MEDIUM", "label": "20 - 100 people", "description": "Medium group - mixed format approach recommended", "value": 60, "implications": {"formats": ["Workshop", "Blended Learning", "Group Projects"], "approach": "Mixed format with cohorts", "trainTheTrainer": false}}	\N	2025-10-22 00:30:27.048058
a88ae474-1ee4-4abd-b00e-4c0e7982d91c	23	19	strategies	1	{"strategies": [{"strategy": "needs_based_project", "strategyName": "Needs-based Project-oriented Training", "priority": "PRIMARY", "reason": "SE processes are defined but not widely deployed - needs targeted project-based training", "userSelected": false, "autoRecommended": false, "warning": "Strategy typically supports up to 50 participants. Consider multiple cohorts or alternative approach."}, {"strategy": "se_for_managers", "strategyName": "SE for Managers", "priority": "SUPPLEMENTARY", "reason": "Manually selected by user to meet specific organizational needs", "userSelected": true, "autoRecommended": false, "warning": null}, {"strategy": "common_understanding", "strategyName": "Common Basic Understanding", "priority": "SUPPLEMENTARY", "reason": "Manually selected by user to meet specific organizational needs", "userSelected": true, "autoRecommended": false, "warning": null}], "decision_path": [{"decision": "Select Needs-based Project-oriented Training", "reason": "Rollout scope is \\"Individual Area\\" - requires expansion through project training", "step": 2}]}	\N	2025-10-22 00:30:38.946185
8e478fe3-f7a5-41a3-8ade-bd3836ad1f5d	23	19	roles	1	{"roles": [{"standardRoleId": 3, "standardRoleName": "Project Manager", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 11, "standardRoleName": "Process and Policy Manager", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 13, "standardRoleName": "Innovation Management", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 14, "standardRoleName": "Management", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}], "identification_method": "STANDARD"}	\N	2025-10-22 00:33:06.923441
acb60fcb-c35a-4dd4-8357-ad8750889103	23	19	target_group	1	{"id": "small", "range": "< 20", "category": "SMALL", "label": "Less than 20 people", "description": "Small group - suitable for intensive workshops", "value": 10, "implications": {"formats": ["Workshop", "Coaching", "Mentoring"], "approach": "Direct intensive training", "trainTheTrainer": false}}	\N	2025-10-22 00:33:11.27247
fe6cbd7b-7c0b-4dfb-baca-c4276d4c5dd7	23	19	strategies	1	{"strategies": [{"strategy": "needs_based_project", "strategyName": "Needs-based Project-oriented Training", "priority": "PRIMARY", "reason": "SE processes are defined but not widely deployed - needs targeted project-based training", "userSelected": false, "autoRecommended": false, "warning": null}, {"strategy": "se_for_managers", "strategyName": "SE for Managers", "priority": "SUPPLEMENTARY", "reason": "Manually selected by user to meet specific organizational needs", "userSelected": true, "autoRecommended": false, "warning": null}, {"strategy": "common_understanding", "strategyName": "Common Basic Understanding", "priority": "SUPPLEMENTARY", "reason": "Manually selected by user to meet specific organizational needs", "userSelected": true, "autoRecommended": false, "warning": null}, {"strategy": "orientation_pilot", "strategyName": "Orientation in Pilot Project", "priority": "SUPPLEMENTARY", "reason": "Manually selected by user to meet specific organizational needs", "userSelected": true, "autoRecommended": false, "warning": null}], "decision_path": [{"decision": "Select Needs-based Project-oriented Training", "reason": "Rollout scope is \\"Individual Area\\" - requires expansion through project training", "step": 2}]}	\N	2025-10-22 00:33:30.260408
def16aec-fee6-49a0-a972-827d8528ee5d	23	19	roles	1	{"roles": [{"standardRoleId": 3, "standardRoleName": "Project Manager", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 11, "standardRoleName": "Process and Policy Manager", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 13, "standardRoleName": "Innovation Management", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 14, "standardRoleName": "Management", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 1, "standardRoleName": "Customer", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 2, "standardRoleName": "Customer Representative", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 12, "standardRoleName": "Internal Support", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 10, "standardRoleName": "Service Technician", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}], "identification_method": "STANDARD"}	\N	2025-10-22 00:34:16.953658
96addee1-7561-4d88-beef-5d3282d3312f	23	19	target_group	1	{"id": "medium", "range": "20-100", "category": "MEDIUM", "label": "20 - 100 people", "description": "Medium group - mixed format approach recommended", "value": 60, "implications": {"formats": ["Workshop", "Blended Learning", "Group Projects"], "approach": "Mixed format with cohorts", "trainTheTrainer": false}}	\N	2025-10-22 00:34:19.004581
1b5f04bc-8b29-462a-8211-20f49eb3ae49	24	20	maturity	1	{"answers": {"rolloutScope": 0, "seRolesProcesses": 3, "seMindset": 2, "knowledgeBase": 3}, "results": {"rawScore": 48.5, "balancePenalty": 2.8, "finalScore": 39.9, "maturityLevel": 2, "maturityName": "Developing", "maturityColor": "#F59E0B", "maturityDescription": "Organization is beginning to adopt SE practices in isolated areas.", "balanceScore": 71.9, "profileType": "Knowledge-Focused", "fieldScores": {"rolloutScope": 0, "seRolesProcesses": 60, "seMindset": 50, "knowledgeBase": 75}, "weakestField": {"field": "Rollout Scope", "value": 0}, "strongestField": {"field": "Knowledge Base", "value": 75}, "normalizedValues": {"rolloutScope": 0, "seRolesProcesses": 0.6, "seMindset": 0.5, "knowledgeBase": 0.75}, "strategyInputs": {"seProcessesValue": 3, "rolloutScopeValue": 0, "seMindsetValue": 2, "knowledgeBaseValue": 3}}}	\N	2025-10-23 01:37:36.951699
171837bd-574f-4945-9029-fde8cde53013	23	19	strategies	1	{"strategies": [{"strategy": "needs_based_project", "strategyName": "Needs-based Project-oriented Training", "priority": "PRIMARY", "reason": "SE processes are defined but not widely deployed - needs targeted project-based training", "userSelected": false, "autoRecommended": false, "warning": "Strategy typically supports up to 50 participants. Consider multiple cohorts or alternative approach."}, {"strategy": "train_the_trainer", "strategyName": "Train the SE-Trainer", "priority": "SUPPLEMENTARY", "reason": "Manually selected by user to meet specific organizational needs", "userSelected": true, "autoRecommended": false, "warning": null}, {"strategy": "certification", "strategyName": "Certification", "priority": "SUPPLEMENTARY", "reason": "Manually selected by user to meet specific organizational needs", "userSelected": true, "autoRecommended": false, "warning": null}], "decision_path": [{"decision": "Select Needs-based Project-oriented Training", "reason": "Rollout scope is \\"Individual Area\\" - requires expansion through project training", "step": 2}]}	\N	2025-10-22 00:34:27.128178
a9b558aa-58c6-4299-a0d1-c9b6006d1692	23	19	maturity	1	{"answers": {"rolloutScope": 4, "seRolesProcesses": 3, "seMindset": 0, "knowledgeBase": 3}, "results": {"rawScore": 56, "balancePenalty": 3.7, "finalScore": 39.9, "maturityLevel": 2, "maturityName": "Developing", "maturityColor": "#F59E0B", "maturityDescription": "Organization is beginning to adopt SE practices in isolated areas.", "balanceScore": 63.2, "profileType": "Unbalanced Development", "fieldScores": {"rolloutScope": 100, "seRolesProcesses": 60, "seMindset": 0, "knowledgeBase": 75}, "weakestField": {"field": "SE Mindset", "value": 0}, "strongestField": {"field": "Rollout Scope", "value": 100}, "normalizedValues": {"rolloutScope": 1, "seRolesProcesses": 0.6, "seMindset": 0, "knowledgeBase": 0.75}, "strategyInputs": {"seProcessesValue": 3, "rolloutScopeValue": 4, "seMindsetValue": 0, "knowledgeBaseValue": 3}}}	\N	2025-10-22 00:34:41.371105
f0ed7445-8a81-4058-9bcf-2232210296c9	23	19	roles	1	{"roles": [{"standardRoleId": 3, "standardRoleName": "Project Manager", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 11, "standardRoleName": "Process and Policy Manager", "orgRoleName": "chichi's chichi", "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 13, "standardRoleName": "Innovation Management", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 14, "standardRoleName": "Management", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 1, "standardRoleName": "Customer", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 2, "standardRoleName": "Customer Representative", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 12, "standardRoleName": "Internal Support", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 10, "standardRoleName": "Service Technician", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 4, "standardRoleName": "System Engineer", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 5, "standardRoleName": "Specialist Developer", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}], "identification_method": "STANDARD"}	\N	2025-10-22 00:35:11.15646
3c13a9c8-59d4-49d0-b602-e60f8ccfbabf	23	19	target_group	1	{"id": "large", "range": "100-500", "category": "LARGE", "label": "100 - 500 people", "description": "Large group - consider train-the-trainer approach", "value": 300, "implications": {"formats": ["Blended Learning", "E-Learning", "Train-the-Trainer"], "approach": "Scalable formats required", "trainTheTrainer": true}}	\N	2025-10-22 00:35:14.265462
206bdd91-a054-4495-a1dd-701af1bf467b	23	19	strategies	1	{"strategies": [{"strategy": "train_the_trainer", "strategyName": "Train the SE-Trainer", "priority": "SUPPLEMENTARY", "reason": "With 100-500 people to train, a train-the-trainer approach will enable scalable knowledge transfer", "userSelected": false, "autoRecommended": false, "warning": "Strategy typically supports up to 10 participants. Consider multiple cohorts or alternative approach."}, {"strategy": "continuous_support", "strategyName": "Continuous Support", "priority": "PRIMARY", "reason": "SE is widely deployed - requires continuous support for sustainment", "userSelected": false, "autoRecommended": false, "warning": null}], "decision_path": [{"decision": "Add Train-the-Trainer", "reason": "Large target group requires multiplier approach", "step": 1}, {"decision": "Select Continuous Support", "reason": "Rollout scope is \\"Value Chain\\" - focus on continuous improvement", "step": 2}]}	\N	2025-10-22 00:35:24.751006
c3575d58-5ec1-43a3-9dbb-3aa73ab088bd	23	19	roles	1	{"roles": [{"standardRoleId": 3, "standardRoleName": "Project Manager", "standard_role_description": "Responsible for project planning, coordination, and achieving goals within constraints.", "orgRoleName": "Valya annan", "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 11, "standardRoleName": "Process and Policy Manager", "standard_role_description": "Develops internal guidelines and monitors process compliance.", "orgRoleName": "Cheriya annan", "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 13, "standardRoleName": "Innovation Management", "standard_role_description": "Focuses on commercial implementation of products/services and new business models.", "orgRoleName": "Myran", "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 14, "standardRoleName": "Management", "standard_role_description": "Decision-makers providing company vision, goals, and project oversight.", "orgRoleName": "Poori", "identificationMethod": "STANDARD", "participatingInTraining": true}], "identification_method": "STANDARD"}	\N	2025-10-22 22:52:06.123146
faee56eb-8019-41a1-9e4c-4c33de880fcb	23	19	target_group	1	{"id": "large", "range": "100-500", "category": "LARGE", "label": "100 - 500 people", "description": "Large group - consider train-the-trainer approach", "value": 300, "implications": {"formats": ["Blended Learning", "E-Learning", "Train-the-Trainer"], "approach": "Scalable formats required", "trainTheTrainer": true}}	\N	2025-10-22 22:52:21.622244
24280143-c1ed-4138-aff7-d5b845185ccf	23	19	strategies	1	{"strategies": [{"strategy": "train_the_trainer", "strategyName": "Train the SE-Trainer", "priority": "SUPPLEMENTARY", "reason": "With 100-500 people to train, a train-the-trainer approach will enable scalable knowledge transfer", "userSelected": false, "autoRecommended": false, "warning": "Strategy typically supports up to 10 participants. Consider multiple cohorts or alternative approach."}, {"strategy": "continuous_support", "strategyName": "Continuous Support", "priority": "PRIMARY", "reason": "SE is widely deployed - requires continuous support for sustainment", "userSelected": false, "autoRecommended": false, "warning": null}, {"strategy": "orientation_pilot", "strategyName": "Orientation in Pilot Project", "priority": "SUPPLEMENTARY", "reason": "Manually selected by user to meet specific organizational needs", "userSelected": true, "autoRecommended": false, "warning": null}], "decision_path": [{"decision": "Add Train-the-Trainer", "reason": "Large target group requires multiplier approach", "step": 1}, {"decision": "Select Continuous Support", "reason": "Rollout scope is \\"Value Chain\\" - focus on continuous improvement", "step": 2}]}	\N	2025-10-22 22:52:41.763326
4d7fd12e-01da-454e-ae67-2b953df26a68	23	19	roles	1	{"roles": [{"standardRoleId": 3, "standardRoleName": "Project Manager", "standard_role_description": "Responsible for project planning, coordination, and achieving goals within constraints.", "orgRoleName": "Valya annan", "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 11, "standardRoleName": "Process and Policy Manager", "standard_role_description": "Develops internal guidelines and monitors process compliance.", "orgRoleName": "Cheriya annan", "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 13, "standardRoleName": "Innovation Management", "standard_role_description": "Focuses on commercial implementation of products/services and new business models.", "orgRoleName": "Myran", "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 14, "standardRoleName": "Management", "standard_role_description": "Decision-makers providing company vision, goals, and project oversight.", "orgRoleName": "Poori", "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 1, "standardRoleName": "Customer", "standard_role_description": "Party that orders or uses the service/product with influence on system design.", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 2, "standardRoleName": "Customer Representative", "standard_role_description": "Interface between customer and company, voice for customer requirements.", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}], "identification_method": "STANDARD"}	\N	2025-10-22 23:01:26.553223
4638ef7a-267c-4424-a93f-a70195627fc3	23	19	target_group	1	{"id": "large", "range": "100-500", "category": "LARGE", "label": "100 - 500 people", "description": "Large group - consider train-the-trainer approach", "value": 300, "implications": {"formats": ["Blended Learning", "E-Learning", "Train-the-Trainer"], "approach": "Scalable formats required", "trainTheTrainer": true}}	\N	2025-10-22 23:01:29.541515
474d859a-de58-4d21-b2c8-3dd476ac1dc3	23	19	strategies	1	{"strategies": [{"strategy": "train_the_trainer", "strategyName": "Train the SE-Trainer", "priority": "SUPPLEMENTARY", "reason": "With 100-500 people to train, a train-the-trainer approach will enable scalable knowledge transfer", "userSelected": false, "autoRecommended": false, "warning": "Strategy typically supports up to 10 participants. Consider multiple cohorts or alternative approach."}, {"strategy": "continuous_support", "strategyName": "Continuous Support", "priority": "PRIMARY", "reason": "SE is widely deployed - requires continuous support for sustainment", "userSelected": false, "autoRecommended": false, "warning": null}, {"strategy": "orientation_pilot", "strategyName": "Orientation in Pilot Project", "priority": "SUPPLEMENTARY", "reason": "Manually selected by user to meet specific organizational needs", "userSelected": true, "autoRecommended": false, "warning": null}, {"strategy": "common_understanding", "strategyName": "Common Basic Understanding", "priority": "SUPPLEMENTARY", "reason": "Manually selected by user to meet specific organizational needs", "userSelected": true, "autoRecommended": false, "warning": null}], "decision_path": [{"decision": "Add Train-the-Trainer", "reason": "Large target group requires multiplier approach", "step": 1}, {"decision": "Select Continuous Support", "reason": "Rollout scope is \\"Value Chain\\" - focus on continuous improvement", "step": 2}]}	\N	2025-10-22 23:01:40.012548
1b14b92f-a6d7-4a07-ba04-a9de99947bd0	24	20	maturity	1	{"answers": {"rolloutScope": 0, "seRolesProcesses": 1, "seMindset": 2, "knowledgeBase": 3}, "results": {"rawScore": 34.5, "balancePenalty": 2.9, "finalScore": 31.6, "maturityLevel": 2, "maturityName": "Developing", "maturityColor": "#F59E0B", "maturityDescription": "Organization is beginning to adopt SE practices in isolated areas.", "balanceScore": 71.4, "profileType": "Knowledge-Focused", "fieldScores": {"rolloutScope": 0, "seRolesProcesses": 20, "seMindset": 50, "knowledgeBase": 75}, "weakestField": {"field": "Rollout Scope", "value": 0}, "strongestField": {"field": "Knowledge Base", "value": 75}, "normalizedValues": {"rolloutScope": 0, "seRolesProcesses": 0.2, "seMindset": 0.5, "knowledgeBase": 0.75}, "strategyInputs": {"seProcessesValue": 1, "rolloutScopeValue": 0, "seMindsetValue": 2, "knowledgeBaseValue": 3}}}	\N	2025-10-23 01:33:44.180136
2962154b-e8b7-4323-8a52-7b1731a5e492	24	20	roles	1	{"roles": [{"standardRoleId": 5, "standardRoleName": "Specialist Developer", "standard_role_description": "Develops in specific areas (software, hardware, etc.) based on system specifications.", "orgRoleName": "Senior Software Developer", "jobDescription": "Senior Software Developer", "mainTasks": {"responsible_for": ["Developing embedded software modules for automotive control systems", "Writing unit tests and integration tests for software components", "Creating technical documentation for software designs", "Implementing software modules according to system specifications", "Debugging and fixing software defects"], "supporting": ["Code reviews for junior developers", "Helping team members troubleshoot technical issues", "Mentoring junior engineers in software best practices", "Supporting integration testing activities"], "designing": ["Software architecture for control modules", "Design patterns and coding standards", "Software development processes and workflows", "Continuous integration and deployment pipelines"]}, "isoProcesses": {"llm_role_suggestion": {"confidence": "High", "reasoning": "The user's tasks primarily involve developing embedded software modules, writing tests, and creating documentation, which aligns closely with the responsibilities of a Specialist Developer. Their involvement in designing software architecture and supporting integration testing further emphasizes their technical expertise in a specialized area, making this role a clear fit.", "role_id": 5, "role_name": "Specialist Developer"}, "processes": [{"involvement": "Not performing", "process_name": "Quality management process"}, {"involvement": "Designing", "process_name": "System architecture definition process"}, {"involvement": "Not performing", "process_name": "Project planning process"}, {"involvement": "Not performing", "process_name": "Quality assurance process"}, {"involvement": "Designing", "process_name": "Design definition process"}, {"involvement": "Responsible", "process_name": "Implementation process"}, {"involvement": "Not performing", "process_name": "Validation process"}, {"involvement": "Not performing", "process_name": "System analysis process"}, {"involvement": "Not performing", "process_name": "System requirements definition process"}, {"involvement": "Not performing", "process_name": "Maintenance process"}], "status": "success"}, "identificationMethod": "TASK_BASED", "confidenceScore": 95, "participatingInTraining": true}, {"standardRoleId": 4, "standardRoleName": "System Engineer", "standard_role_description": "Oversees requirements, system decomposition, interfaces, and integration planning.", "orgRoleName": "Systems Integration Engineer", "jobDescription": "Systems Integration Engineer", "mainTasks": {"responsible_for": ["Integrating software and hardware components into complete systems", "Coordinating interfaces between different system modules", "Defining integration test procedures and executing tests", "Managing system-level requirements and specifications", "Ensuring compatibility across system boundaries"], "supporting": ["System architecture reviews", "Requirements analysis and decomposition", "Stakeholder communication and coordination", "Risk assessment for integration activities"], "designing": ["System integration strategies and approaches", "Interface specifications between components", "Integration testing frameworks", "System verification procedures"]}, "isoProcesses": {"llm_role_suggestion": {"confidence": "High", "reasoning": "The user's tasks involve integrating software and hardware components, managing system-level requirements, and defining integration strategies, which are core responsibilities of a System Engineer. Their involvement in system architecture reviews and interface specifications further aligns with the role's focus on overseeing the entire system lifecycle from requirements to integration.", "role_id": 4, "role_name": "System Engineer"}, "processes": [{"involvement": "Supporting", "process_name": "System requirements definition process"}, {"involvement": "Supporting", "process_name": "Stakeholder needs and requirements definition process"}, {"involvement": "Designing", "process_name": "System architecture definition process"}, {"involvement": "Supporting", "process_name": "Risk management process"}, {"involvement": "Supporting", "process_name": "System analysis process"}, {"involvement": "Not performing", "process_name": "Validation process"}, {"involvement": "Designing", "process_name": "Design definition process"}, {"involvement": "Not performing", "process_name": "Verification process"}, {"involvement": "Not performing", "process_name": "Implementation process"}, {"involvement": "Not performing", "process_name": "Operation process"}], "status": "success"}, "identificationMethod": "TASK_BASED", "confidenceScore": 95, "participatingInTraining": true}, {"standardRoleId": 8, "standardRoleName": "Quality Engineer/Manager", "standard_role_description": "Ensures quality standards are maintained and cooperates with V&V.", "orgRoleName": "Quality Assurance Specialist", "jobDescription": "Quality Assurance Specialist", "mainTasks": {"responsible_for": ["Developing and executing test plans for software and systems", "Identifying and documenting software defects", "Ensuring compliance with quality standards and regulations", "Performing regression testing on software releases", "Managing defect tracking and resolution processes"], "supporting": ["Process improvement initiatives", "Root cause analysis of quality issues", "Training team members on testing procedures", "Quality metrics collection and reporting"], "designing": ["Quality assurance processes and procedures", "Test automation frameworks", "Quality metrics and KPIs", "Continuous improvement initiatives"]}, "isoProcesses": {"llm_role_suggestion": {"confidence": "High", "reasoning": "The user's responsibilities align closely with the role of a Quality Engineer/Manager, as they are focused on developing and executing test plans, ensuring compliance with quality standards, and managing defect tracking processes. Their involvement in quality assurance processes and continuous improvement initiatives further solidifies this match, indicating a strong emphasis on maintaining and enhancing quality within systems.", "role_id": 8, "role_name": "Quality Engineer/Manager"}, "processes": [{"involvement": "Supporting", "process_name": "Quality management process"}, {"involvement": "Responsible", "process_name": "Quality assurance process"}, {"involvement": "Not performing", "process_name": "Project assessment and control process"}, {"involvement": "Not performing", "process_name": "Validation process"}, {"involvement": "Supporting", "process_name": "Measurement process"}, {"involvement": "Not performing", "process_name": "Configuration management process"}, {"involvement": "Not performing", "process_name": "Project planning process"}, {"involvement": "Responsible", "process_name": "Verification process"}, {"involvement": "Not performing", "process_name": "Risk management process"}, {"involvement": "Not performing", "process_name": "Portfolio management process"}], "status": "success"}, "identificationMethod": "TASK_BASED", "confidenceScore": 95, "participatingInTraining": true}, {"standardRoleId": 5, "standardRoleName": "Specialist Developer", "standard_role_description": "Develops in specific areas (software, hardware, etc.) based on system specifications.", "orgRoleName": "Hardware Design Engineer", "jobDescription": "Hardware Design Engineer", "mainTasks": {"responsible_for": ["Designing electronic circuits and hardware components", "Creating schematics and PCB layouts", "Selecting components and materials for hardware designs", "Conducting hardware testing and validation", "Producing hardware documentation and specifications"], "supporting": ["System architecture development", "Design reviews and technical assessments", "Prototyping and proof-of-concept activities", "Troubleshooting hardware issues"], "designing": ["Hardware design methodologies", "Component selection criteria", "Testing procedures for hardware validation", "Design tools and workflows"]}, "isoProcesses": {"llm_role_suggestion": {"confidence": "High", "reasoning": "The user's tasks primarily involve designing electronic circuits and hardware components, which aligns closely with the responsibilities of a Specialist Developer. Their involvement in creating schematics, PCB layouts, and conducting hardware testing indicates a deep technical focus on development, making this role the most suitable match.", "role_id": 5, "role_name": "Specialist Developer"}, "processes": [{"involvement": "Not performing", "process_name": "System requirements definition process"}, {"involvement": "Not performing", "process_name": "Business or mission analysis process"}, {"involvement": "Not performing", "process_name": "Stakeholder needs and requirements definition process"}, {"involvement": "Not performing", "process_name": "System analysis process"}, {"involvement": "Supporting", "process_name": "System architecture definition process"}, {"involvement": "Responsible", "process_name": "Design definition process"}, {"involvement": "Not performing", "process_name": "Operation process"}, {"involvement": "Not performing", "process_name": "Validation process"}, {"involvement": "Not performing", "process_name": "Transition process"}, {"involvement": "Not performing", "process_name": "Implementation process"}], "status": "success"}, "identificationMethod": "TASK_BASED", "confidenceScore": 95, "participatingInTraining": true}], "identification_method": "TASK_BASED"}	\N	2025-10-23 01:36:16.06315
cbdcf893-e379-4c09-943e-d7024fbc2c0e	24	20	target_group	1	{"id": "xlarge", "range": "500-1500", "category": "VERY_LARGE", "label": "500 - 1500 people", "description": "Very large group - phased rollout recommended", "value": 1000, "implications": {"formats": ["E-Learning", "Train-the-Trainer", "Self-paced"], "approach": "Phased rollout with trainers", "trainTheTrainer": true}}	\N	2025-10-23 01:36:22.321313
48f87675-3130-4a18-9dbd-c8e5b5712cb5	24	20	strategies	1	{"strategies": [{"strategy": "train_the_trainer", "strategyName": "Train the SE-Trainer", "priority": "SUPPLEMENTARY", "reason": "With 500-1500 people to train, a train-the-trainer approach will enable scalable knowledge transfer", "userSelected": false, "autoRecommended": false, "warning": "Strategy typically supports up to 10 participants. Consider multiple cohorts or alternative approach."}, {"strategy": "se_for_managers", "strategyName": "SE for Managers", "priority": "PRIMARY", "reason": "Management buy-in is essential for SE introduction in organizations with undefined processes", "userSelected": false, "autoRecommended": false, "warning": "Strategy typically supports up to 30 participants. Consider multiple cohorts or alternative approach."}, {"strategy": "common_understanding", "strategyName": "Common Basic Understanding", "priority": "SUPPLEMENTARY", "reason": "Manually selected by user to meet specific organizational needs", "userSelected": true, "autoRecommended": false, "warning": null}], "decision_path": [{"decision": "Add Train-the-Trainer", "reason": "Large target group requires multiplier approach", "step": 1}, {"decision": "Select SE for Managers as primary", "reason": "SE Processes maturity is \\"Ad hoc / Undefined\\" - requires management enablement first", "step": 2}, {"decision": "User selects secondary strategy", "options": ["common_understanding", "orientation_pilot", "certification"], "step": 3}]}	\N	2025-10-23 01:36:46.930207
c645b119-c513-4280-b0f8-ffe219a42acd	24	20	roles	1	{"roles": [{"standardRoleId": 5, "standardRoleName": "Specialist Developer", "standard_role_description": "Develops in specific areas (software, hardware, etc.) based on system specifications.", "orgRoleName": "Hardware Design Engineer", "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 4, "standardRoleName": "System Engineer", "standard_role_description": "Oversees requirements, system decomposition, interfaces, and integration planning.", "orgRoleName": "Systems Integration Engineer", "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 8, "standardRoleName": "Quality Engineer/Manager", "standard_role_description": "Ensures quality standards are maintained and cooperates with V&V.", "orgRoleName": "Quality Assurance Specialist", "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 5, "standardRoleName": "Specialist Developer", "standard_role_description": "Develops in specific areas (software, hardware, etc.) based on system specifications.", "orgRoleName": "Hardware Design Engineer", "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 10, "standardRoleName": "Service Technician", "standard_role_description": "Handles installation, commissioning, training, maintenance, and repair.", "orgRoleName": "Hoi Hoi", "identificationMethod": "STANDARD", "participatingInTraining": true}, {"standardRoleId": 12, "standardRoleName": "Internal Support", "standard_role_description": "Provides advisory and support during development (IT, qualification, SE support).", "orgRoleName": null, "identificationMethod": "STANDARD", "participatingInTraining": true}], "identification_method": "STANDARD"}	\N	2025-10-23 01:37:55.623001
d514378c-916c-4f4b-83ef-660c59524c9c	24	20	target_group	1	{"id": "large", "range": "100-500", "category": "LARGE", "label": "100 - 500 people", "description": "Large group - consider train-the-trainer approach", "value": 300, "implications": {"formats": ["Blended Learning", "E-Learning", "Train-the-Trainer"], "approach": "Scalable formats required", "trainTheTrainer": true}}	\N	2025-10-23 01:37:59.678184
0b31a7f9-7200-4585-90f3-92524dca90ce	24	20	strategies	1	{"strategies": [{"strategy": "train_the_trainer", "strategyName": "Train the SE-Trainer", "priority": "SUPPLEMENTARY", "reason": "With 100-500 people to train, a train-the-trainer approach will enable scalable knowledge transfer", "userSelected": false, "autoRecommended": false, "warning": "Strategy typically supports up to 10 participants. Consider multiple cohorts or alternative approach."}, {"strategy": "needs_based_project", "strategyName": "Needs-based Project-oriented Training", "priority": "PRIMARY", "reason": "SE processes are defined but not widely deployed - needs targeted project-based training", "userSelected": false, "autoRecommended": false, "warning": "Strategy typically supports up to 50 participants. Consider multiple cohorts or alternative approach."}, {"strategy": "certification", "strategyName": "Certification", "priority": "SUPPLEMENTARY", "reason": "Manually selected by user to meet specific organizational needs", "userSelected": true, "autoRecommended": false, "warning": null}, {"strategy": "continuous_support", "strategyName": "Continuous Support", "priority": "SUPPLEMENTARY", "reason": "Manually selected by user to meet specific organizational needs", "userSelected": true, "autoRecommended": false, "warning": null}, {"strategy": "se_for_managers", "strategyName": "SE for Managers", "priority": "SUPPLEMENTARY", "reason": "Manually selected by user to meet specific organizational needs", "userSelected": true, "autoRecommended": false, "warning": null}, {"strategy": "common_understanding", "strategyName": "Common Basic Understanding", "priority": "SUPPLEMENTARY", "reason": "Manually selected by user to meet specific organizational needs", "userSelected": true, "autoRecommended": false, "warning": null}, {"strategy": "orientation_pilot", "strategyName": "Orientation in Pilot Project", "priority": "SUPPLEMENTARY", "reason": "Manually selected by user to meet specific organizational needs", "userSelected": true, "autoRecommended": false, "warning": null}], "decision_path": [{"decision": "Add Train-the-Trainer", "reason": "Large target group requires multiplier approach", "step": 1}, {"decision": "Select Needs-based Project-oriented Training", "reason": "Rollout scope is \\"Not Available\\" - requires expansion through project training", "step": 2}]}	\N	2025-10-23 01:38:25.858623
\.


--
-- Data for Name: process_competency_matrix; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.process_competency_matrix (id, iso_process_id, competency_id, process_competency_value) FROM stdin;
2	2	1	1
3	3	1	2
4	4	1	1
5	5	1	1
6	6	1	1
7	7	1	1
8	8	1	1
9	9	1	2
10	10	1	1
11	11	1	1
12	12	1	1
13	13	1	0
14	14	1	1
15	15	1	1
16	16	1	1
17	17	1	2
18	18	1	2
19	19	1	2
20	20	1	2
21	21	1	1
22	22	1	1
23	23	1	1
24	24	1	1
25	25	1	1
26	26	1	1
27	27	1	2
28	28	1	1
29	29	1	1
30	30	1	1
31	1	6	0
32	2	6	0
33	3	6	2
34	4	6	1
35	5	6	0
36	6	6	1
37	7	6	1
38	8	6	1
39	9	6	0
40	10	6	0
41	11	6	1
42	12	6	2
43	13	6	1
44	14	6	1
45	15	6	0
46	16	6	0
47	17	6	2
48	18	6	2
49	19	6	2
50	20	6	2
51	21	6	2
52	22	6	2
53	23	6	1
54	24	6	1
55	25	6	1
56	26	6	1
57	27	6	1
58	28	6	1
59	29	6	1
60	30	6	1
61	1	4	0
62	2	4	0
63	3	4	2
64	4	4	0
65	5	4	0
66	6	4	1
67	7	4	1
68	8	4	0
69	9	4	1
70	10	4	1
71	11	4	2
72	12	4	2
73	13	4	0
74	14	4	0
75	15	4	0
76	16	4	0
77	17	4	2
78	18	4	2
79	19	4	2
80	20	4	2
81	21	4	2
82	22	4	2
83	23	4	1
84	24	4	1
85	25	4	1
86	26	4	1
87	27	4	1
88	28	4	1
89	29	4	1
90	30	4	1
91	1	18	0
92	2	18	0
94	4	18	0
95	5	18	0
96	6	18	0
97	7	18	0
98	8	18	0
99	9	18	2
100	10	18	2
103	13	18	0
104	14	18	0
105	15	18	0
106	16	18	0
107	17	18	2
108	18	18	2
109	19	18	2
110	20	18	2
111	21	18	2
112	22	18	2
113	23	18	1
114	24	18	1
116	26	18	1
118	28	18	1
119	29	18	1
120	30	18	1
121	1	14	1
122	2	14	1
123	3	14	2
124	4	14	1
125	5	14	0
126	6	14	0
127	7	14	2
128	8	14	0
129	9	14	1
130	10	14	1
131	11	14	0
132	12	14	1
133	13	14	0
134	14	14	1
135	15	14	0
136	16	14	2
137	17	14	2
138	18	14	2
139	19	14	2
140	20	14	1
141	21	14	0
142	22	14	0
143	23	14	0
144	24	14	0
145	25	14	1
146	26	14	0
147	27	14	1
148	28	14	1
149	29	14	1
150	30	14	1
151	1	15	0
152	2	15	0
153	3	15	2
154	4	15	1
155	5	15	0
156	6	15	0
157	7	15	2
158	8	15	1
159	9	15	1
160	10	15	1
161	11	15	0
162	12	15	0
163	13	15	0
164	14	15	0
165	15	15	0
166	16	15	0
167	17	15	0
168	18	15	1
169	19	15	1
170	20	15	2
171	21	15	2
172	22	15	1
173	23	15	1
174	24	15	1
175	25	15	0
176	26	15	0
177	27	15	0
178	28	15	0
179	29	15	0
180	30	15	0
181	1	16	0
182	2	16	0
183	3	16	2
184	4	16	0
185	5	16	0
1	1	1	1
186	6	16	0
187	7	16	0
188	8	16	0
189	9	16	1
190	10	16	1
191	11	16	0
192	12	16	0
193	13	16	0
194	14	16	0
195	15	16	0
196	16	16	0
197	17	16	1
198	18	16	1
199	19	16	1
200	20	16	1
201	21	16	0
202	22	16	0
203	23	16	0
204	24	16	2
205	25	16	2
206	26	16	0
207	27	16	2
208	28	16	0
209	29	16	0
210	30	16	0
211	1	17	0
212	2	17	0
213	3	17	2
214	4	17	0
215	5	17	0
216	6	17	0
217	7	17	0
218	8	17	0
219	9	17	1
220	10	17	1
221	11	17	0
222	12	17	0
223	13	17	0
224	14	17	0
225	15	17	0
226	16	17	0
227	17	17	0
228	18	17	0
229	19	17	0
230	20	17	0
231	21	17	0
232	22	17	0
233	23	17	0
234	24	17	1
235	25	17	1
236	26	17	0
237	27	17	1
238	28	17	2
239	29	17	2
240	30	17	2
241	1	9	1
242	2	9	1
243	3	9	1
244	4	9	1
245	5	9	1
246	6	9	1
247	7	9	1
248	8	9	1
249	9	9	2
250	10	9	2
251	11	9	1
252	12	9	1
253	13	9	1
254	14	9	1
255	15	9	0
256	16	9	1
257	17	9	2
258	18	9	2
259	19	9	2
260	20	9	2
261	21	9	2
262	22	9	2
263	23	9	1
264	24	9	2
265	25	9	2
266	26	9	1
267	27	9	2
268	28	9	1
269	29	9	1
270	30	9	1
271	1	7	2
272	2	7	2
273	3	7	0
274	4	7	1
275	5	7	1
276	6	7	1
277	7	7	1
278	8	7	1
279	9	7	2
280	10	7	2
281	11	7	1
282	12	7	1
283	13	7	1
284	14	7	1
285	15	7	0
286	16	7	1
287	17	7	2
288	18	7	2
289	19	7	2
290	20	7	2
291	21	7	1
292	22	7	1
293	23	7	1
294	24	7	2
295	25	7	1
296	26	7	2
297	27	7	1
298	28	7	1
299	29	7	1
300	30	7	1
301	1	8	0
302	2	8	0
303	3	8	0
304	4	8	1
305	5	8	2
306	6	8	1
307	7	8	1
308	8	8	1
309	9	8	2
310	10	8	2
311	11	8	1
312	12	8	1
313	13	8	1
314	14	8	1
315	15	8	0
316	16	8	1
317	17	8	1
318	18	8	1
319	19	8	1
320	20	8	1
321	21	8	1
322	22	8	1
323	23	8	1
324	24	8	1
325	25	8	1
326	26	8	0
327	27	8	1
328	28	8	0
329	29	8	0
330	30	8	0
331	1	10	0
332	2	10	0
333	3	10	2
334	4	10	0
335	5	10	1
336	6	10	0
337	7	10	2
338	8	10	0
339	9	10	2
340	10	10	2
341	11	10	1
342	12	10	1
343	13	10	0
344	14	10	0
345	15	10	2
346	16	10	2
347	17	10	1
348	18	10	1
349	19	10	1
350	20	10	1
351	21	10	0
352	22	10	0
353	23	10	0
354	24	10	0
355	25	10	0
356	26	10	0
357	27	10	0
358	28	10	0
359	29	10	0
360	30	10	0
361	1	11	0
362	2	11	0
363	3	11	2
364	4	11	1
365	5	11	2
366	6	11	0
367	7	11	0
368	8	11	0
369	9	11	1
370	10	11	1
371	11	11	2
372	12	11	2
373	13	11	0
374	14	11	0
375	15	11	0
376	16	11	0
377	17	11	1
378	18	11	1
379	19	11	1
380	20	11	2
381	21	11	1
382	22	11	0
383	23	11	0
384	24	11	1
385	25	11	1
386	26	11	0
387	27	11	1
388	28	11	0
389	29	11	0
390	30	11	0
391	1	12	0
392	2	12	0
393	3	12	2
394	4	12	1
395	5	12	0
396	6	12	0
397	7	12	0
398	8	12	2
399	9	12	1
400	10	12	1
401	11	12	0
402	12	12	1
403	13	12	1
404	14	12	2
405	15	12	1
406	16	12	1
407	17	12	1
408	18	12	1
409	19	12	1
410	20	12	1
411	21	12	1
412	22	12	1
413	23	12	1
414	24	12	1
415	25	12	1
416	26	12	1
417	27	12	1
418	28	12	1
419	29	12	1
420	30	12	1
421	1	13	0
422	2	13	0
423	3	13	2
424	4	13	1
425	5	13	0
426	6	13	0
427	7	13	0
428	8	13	0
429	9	13	0
430	10	13	0
431	11	13	0
432	12	13	0
433	13	13	2
434	14	13	0
435	15	13	0
436	16	13	0
437	17	13	1
438	18	13	1
439	19	13	1
440	20	13	2
441	21	13	1
442	22	13	1
443	23	13	1
444	24	13	2
445	25	13	1
446	26	13	1
447	27	13	1
448	28	13	1
449	29	13	1
450	30	13	1
93	3	18	2
101	11	18	0
102	12	18	0
115	25	18	2
117	27	18	2
451	1	5	0
452	2	5	0
453	3	5	1
454	4	5	0
455	5	5	0
456	6	5	0
457	7	5	0
458	8	5	0
459	9	5	2
460	10	5	2
461	11	5	1
462	12	5	1
463	13	5	0
464	14	5	0
465	15	5	0
466	16	5	0
467	17	5	2
468	18	5	2
469	19	5	2
470	20	5	2
471	21	5	2
472	22	5	2
473	23	5	1
474	24	5	1
475	25	5	1
476	26	5	1
477	27	5	1
478	28	5	1
479	29	5	1
480	30	5	1
\.


--
-- Data for Name: qualification_archetypes; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.qualification_archetypes (id, name, description, typical_duration, learning_format, target_audience, focus_area, delivery_method, strategy, is_active, created_at) FROM stdin;
\.


--
-- Data for Name: qualification_plans; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.qualification_plans (id, uuid, user_id, name, description, target_role, archetype_id, estimated_duration_weeks, modules, learning_path, progress_tracking, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: question_options; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.question_options (id, question_id, option_text, option_value, score_value, sort_order, is_correct, additional_data) FROM stdin;
\.


--
-- Data for Name: question_responses; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.question_responses (id, questionnaire_response_id, question_id, response_value, selected_option_id, score, confidence_level, time_spent_seconds, revision_count, responded_at, last_modified_at) FROM stdin;
\.


--
-- Data for Name: questionnaire_responses; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.questionnaire_responses (id, uuid, user_id, questionnaire_id, status, completion_percentage, total_score, max_possible_score, score_percentage, section_scores, results_summary, recommendations, computed_archetype, started_at, completed_at, duration_minutes) FROM stdin;
\.


--
-- Data for Name: questionnaires; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.questionnaires (id, name, title, description, questionnaire_type, phase, is_active, sort_order, estimated_duration_minutes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: questions; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.questions (id, questionnaire_id, question_number, question_text, question_type, section, weight, max_score, scoring_method, is_required, sort_order, help_text, validation_rules, created_at) FROM stdin;
\.


--
-- Data for Name: rag_templates; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.rag_templates (id, name, category, competency_focus, industry_context, template_text, variables, success_criteria, usage_count, average_quality_score, template_metadata, is_active, created_at) FROM stdin;
\.


--
-- Data for Name: role_cluster; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.role_cluster (id, role_cluster_name, role_cluster_description) FROM stdin;
1	Customer	Party that orders or uses the service/product with influence on system design.
2	Customer Representative	Interface between customer and company, voice for customer requirements.
3	Project Manager	Responsible for project planning, coordination, and achieving goals within constraints.
4	System Engineer	Oversees requirements, system decomposition, interfaces, and integration planning.
5	Specialist Developer	Develops in specific areas (software, hardware, etc.) based on system specifications.
6	Production Planner/Coordinator	Prepares product realization and transfer to customer.
7	Production Employee	Handles implementation, assembly, manufacture, and product integration.
8	Quality Engineer/Manager	Ensures quality standards are maintained and cooperates with V&V.
9	Verification and Validation (V&V) Operator	Performs system verification and validation activities.
10	Service Technician	Handles installation, commissioning, training, maintenance, and repair.
11	Process and Policy Manager	Develops internal guidelines and monitors process compliance.
13	Innovation Management	Focuses on commercial implementation of products/services and new business models.
14	Management	Decision-makers providing company vision, goals, and project oversight.
12	Internal Support	Provides advisory and support during development (IT, qualification, SE support).
\.


--
-- Data for Name: role_competency_matrix; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.role_competency_matrix (id, role_cluster_id, competency_id, role_competency_value, organization_id) FROM stdin;
1121	1	8	1	11
1122	5	13	2	11
1123	7	8	2	11
1124	6	18	2	11
1125	2	13	2	11
1126	7	14	0	11
1127	3	12	4	11
1128	3	15	2	11
1129	13	11	4	11
1130	1	1	2	11
1131	9	7	2	11
1132	4	8	2	11
1133	3	13	4	11
1134	5	4	4	11
1135	6	9	2	11
1136	9	4	4	11
1137	6	15	2	11
1138	2	17	1	11
1139	4	13	4	11
1140	1	11	1	11
1141	1	9	2	11
1142	9	17	2	11
1143	4	1	4	11
1144	6	16	2	11
1145	6	12	2	11
1146	13	5	4	11
1147	8	12	2	11
1148	5	15	2	11
1149	14	14	2	11
1150	1	5	2	11
1151	12	6	2	11
1152	9	15	4	11
1153	7	7	4	11
1154	12	15	2	11
1155	3	9	4	11
1156	10	8	0	11
1157	3	17	2	11
1158	14	15	1	11
1159	9	11	2	11
1160	14	13	1	11
1161	7	1	2	11
1162	11	14	6	11
1163	3	1	4	11
1164	5	16	2	11
1165	11	18	6	11
1166	14	5	2	11
1167	5	12	2	11
1168	7	6	2	11
1169	9	5	4	11
1170	7	4	2	11
1171	5	11	2	11
1172	6	5	2	11
1173	4	9	4	11
1174	4	7	4	11
1175	7	17	2	11
1176	11	8	6	11
1177	9	16	4	11
1178	14	4	4	11
1179	11	6	6	11
1180	4	5	4	11
1181	8	8	2	11
1182	11	9	6	11
1183	9	10	1	11
1184	7	11	2	11
1185	5	9	4	11
1186	12	12	4	11
1187	13	12	2	11
1188	11	12	6	11
1189	1	13	2	11
1190	3	11	4	11
1191	14	18	2	11
1192	8	13	1	11
1193	4	10	2	11
1194	5	5	4	11
1195	9	6	4	11
1196	14	12	1	11
1197	3	4	4	11
1198	11	5	6	11
1199	6	10	1	11
1200	14	17	1	11
1201	5	14	4	11
1202	12	1	2	11
1203	11	11	6	11
1204	2	12	2	11
1205	9	18	4	11
1206	4	17	2	11
1207	8	6	2	11
1208	4	12	2	11
1209	13	9	4	11
1210	10	17	2	11
1211	6	7	4	11
1212	1	15	0	11
1213	10	16	0	11
1214	11	16	6	11
1215	3	14	2	11
1216	2	18	4	11
1217	2	9	4	11
1218	10	7	4	11
1219	12	18	2	11
1220	8	5	1	11
1221	8	14	4	11
1222	4	18	4	11
1223	4	14	4	11
1224	11	17	6	11
1225	10	4	2	11
1226	10	13	2	11
1227	1	4	2	11
1228	6	11	2	11
1229	2	14	4	11
1230	1	6	2	11
1231	12	16	2	11
1232	11	15	6	11
1233	6	6	2	11
1234	9	9	4	11
1235	14	7	2	11
1236	4	6	4	11
1237	10	12	2	11
1238	8	9	2	11
1239	8	15	4	11
1240	9	14	2	11
1241	6	13	2	11
1242	7	12	2	11
1243	14	9	2	11
1244	10	15	0	11
1245	1	10	0	11
1246	12	13	2	11
1247	4	4	4	11
1248	8	18	2	11
1249	5	8	2	11
1250	11	13	6	11
1251	9	1	2	11
1252	2	6	4	11
1253	11	1	6	11
1254	14	8	2	11
1255	10	10	0	11
1256	7	15	2	11
1257	5	1	4	11
1258	12	5	1	11
1259	13	4	4	11
1260	12	17	2	11
1261	2	4	4	11
1262	1	17	4	11
1263	2	8	2	11
1264	6	8	2	11
1265	5	6	4	11
1266	13	16	2	11
1267	8	4	2	11
1268	10	1	2	11
1269	5	10	2	11
1270	12	14	2	11
1271	8	11	2	11
1272	13	6	4	11
1273	12	9	2	11
1274	8	7	2	11
1275	9	13	2	11
1276	4	16	2	11
1277	1	12	2	11
1278	3	5	4	11
1279	14	10	2	11
1280	10	18	2	11
1281	1	16	2	11
1282	12	11	2	11
1283	4	11	4	11
1284	13	13	2	11
1285	1	7	4	11
1286	2	10	2	11
1287	4	15	4	11
1288	3	16	2	11
1289	10	14	1	11
1290	7	5	2	11
1291	9	12	2	11
1292	10	6	2	11
1293	2	16	2	11
1294	6	17	1	11
1295	8	16	2	11
1296	2	11	4	11
1297	12	7	2	11
1298	13	18	4	11
1299	3	18	4	11
1300	11	4	6	11
1301	14	1	2	11
1302	13	17	0	11
1303	10	5	2	11
1304	3	6	4	11
1305	13	10	2	11
1306	3	7	4	11
1307	13	15	0	11
1308	11	7	6	11
1309	8	10	4	11
1310	6	4	2	11
1311	1	18	2	11
1312	12	10	2	11
1313	2	1	4	11
1314	11	10	6	11
1315	10	11	0	11
1316	10	9	2	11
1317	7	18	2	11
1318	3	10	4	11
1319	13	14	4	11
1320	6	1	2	11
1321	13	1	4	11
1322	7	10	0	11
1323	7	13	4	11
1324	7	9	4	11
1325	5	7	4	11
1326	13	7	4	11
1327	2	15	2	11
1328	5	18	4	11
1329	9	8	2	11
1330	12	8	2	11
1331	5	17	0	11
1332	13	8	4	11
1333	1	14	2	11
1334	2	5	4	11
1335	3	8	4	11
1336	6	14	2	11
1337	8	1	2	11
1338	14	11	4	11
1339	14	16	1	11
1340	14	6	2	11
1341	8	17	1	11
1342	2	7	4	11
1343	7	16	4	11
1344	12	4	2	11
1694	12	13	2	17
1695	4	4	4	17
1696	8	18	2	17
1697	5	8	2	17
1698	11	13	6	17
1699	9	1	2	17
1700	2	6	4	17
1701	11	1	6	17
1702	14	8	2	17
1703	10	10	0	17
1704	7	15	2	17
225	1	8	1	15
226	5	13	2	15
227	7	8	2	15
228	6	18	2	15
229	2	13	2	15
230	7	14	0	15
231	3	12	4	15
232	3	15	2	15
233	13	11	4	15
234	1	1	2	15
235	9	7	2	15
236	4	8	2	15
237	3	13	4	15
238	5	4	4	15
239	6	9	2	15
240	9	4	4	15
241	6	15	2	15
242	2	17	1	15
243	4	13	4	15
244	1	11	1	15
245	1	9	2	15
246	9	17	2	15
247	4	1	4	15
248	6	16	2	15
249	6	12	2	15
250	13	5	4	15
251	8	12	2	15
252	5	15	2	15
253	14	14	2	15
254	1	5	2	15
255	12	6	2	15
256	9	15	4	15
257	7	7	4	15
258	12	15	2	15
259	3	9	4	15
260	10	8	0	15
261	3	17	2	15
262	14	15	1	15
263	9	11	2	15
264	14	13	1	15
265	7	1	2	15
266	11	14	6	15
267	3	1	4	15
268	5	16	2	15
269	11	18	6	15
270	14	5	2	15
271	5	12	2	15
272	7	6	2	15
273	9	5	4	15
274	7	4	2	15
275	5	11	2	15
276	6	5	2	15
277	4	9	4	15
278	4	7	4	15
279	7	17	2	15
280	11	8	6	15
281	9	16	4	15
282	14	4	4	15
283	11	6	6	15
284	4	5	4	15
285	8	8	2	15
286	11	9	6	15
287	9	10	1	15
288	7	11	2	15
289	5	9	4	15
290	12	12	4	15
291	13	12	2	15
292	11	12	6	15
293	1	13	2	15
294	3	11	4	15
295	14	18	2	15
296	8	13	1	15
297	4	10	2	15
298	5	5	4	15
299	9	6	4	15
300	14	12	1	15
301	3	4	4	15
302	11	5	6	15
303	6	10	1	15
304	14	17	1	15
305	5	14	4	15
306	12	1	2	15
307	11	11	6	15
308	2	12	2	15
309	9	18	4	15
310	4	17	2	15
311	8	6	2	15
312	4	12	2	15
313	13	9	4	15
314	10	17	2	15
315	6	7	4	15
316	1	15	0	15
317	10	16	0	15
318	11	16	6	15
319	3	14	2	15
320	2	18	4	15
321	2	9	4	15
322	10	7	4	15
323	12	18	2	15
324	8	5	1	15
325	8	14	4	15
326	4	18	4	15
327	4	14	4	15
328	11	17	6	15
329	10	4	2	15
330	10	13	2	15
331	1	4	2	15
332	6	11	2	15
333	2	14	4	15
334	1	6	2	15
335	12	16	2	15
336	11	15	6	15
337	6	6	2	15
338	9	9	4	15
339	14	7	2	15
340	4	6	4	15
341	10	12	2	15
342	8	9	2	15
343	8	15	4	15
344	9	14	2	15
345	6	13	2	15
346	7	12	2	15
347	14	9	2	15
348	10	15	0	15
349	1	10	0	15
350	12	13	2	15
351	4	4	4	15
352	8	18	2	15
353	5	8	2	15
354	11	13	6	15
355	9	1	2	15
356	2	6	4	15
357	11	1	6	15
358	14	8	2	15
359	10	10	0	15
360	7	15	2	15
361	5	1	4	15
362	12	5	1	15
363	13	4	4	15
364	12	17	2	15
365	2	4	4	15
366	1	17	4	15
367	2	8	2	15
368	6	8	2	15
369	5	6	4	15
370	13	16	2	15
371	8	4	2	15
372	10	1	2	15
373	5	10	2	15
374	12	14	2	15
375	8	11	2	15
376	13	6	4	15
377	12	9	2	15
378	8	7	2	15
379	9	13	2	15
380	4	16	2	15
381	1	12	2	15
382	3	5	4	15
383	14	10	2	15
384	10	18	2	15
385	1	16	2	15
386	12	11	2	15
387	4	11	4	15
388	13	13	2	15
389	1	7	4	15
390	2	10	2	15
391	4	15	4	15
392	3	16	2	15
393	10	14	1	15
394	7	5	2	15
395	9	12	2	15
396	10	6	2	15
397	2	16	2	15
398	6	17	1	15
399	8	16	2	15
400	2	11	4	15
401	12	7	2	15
402	13	18	4	15
403	3	18	4	15
404	11	4	6	15
405	14	1	2	15
406	13	17	0	15
407	10	5	2	15
408	3	6	4	15
409	13	10	2	15
410	3	7	4	15
411	13	15	0	15
412	11	7	6	15
413	8	10	4	15
414	6	4	2	15
415	1	18	2	15
416	12	10	2	15
417	2	1	4	15
418	11	10	6	15
419	10	11	0	15
420	10	9	2	15
421	7	18	2	15
422	3	10	4	15
423	13	14	4	15
424	6	1	2	15
425	13	1	4	15
426	7	10	0	15
427	7	13	4	15
428	7	9	4	15
429	5	7	4	15
430	13	7	4	15
431	2	15	2	15
432	5	18	4	15
433	9	8	2	15
434	12	8	2	15
435	5	17	0	15
436	13	8	4	15
437	1	14	2	15
438	2	5	4	15
439	3	8	4	15
440	6	14	2	15
441	8	1	2	15
442	14	11	4	15
443	14	16	1	15
444	14	6	2	15
445	8	17	1	15
446	2	7	4	15
447	7	16	4	15
448	12	4	2	15
1345	1	8	1	16
1346	5	13	2	16
1347	7	8	2	16
1348	6	18	2	16
1349	2	13	2	16
1350	7	14	0	16
1351	3	12	4	16
1352	3	15	2	16
1353	13	11	4	16
1354	1	1	2	16
1355	9	7	2	16
1356	4	8	2	16
1357	3	13	4	16
1358	5	4	4	16
1359	6	9	2	16
1360	9	4	4	16
1361	6	15	2	16
1362	2	17	1	16
1363	4	13	4	16
1364	1	11	1	16
1365	1	9	2	16
1366	9	17	2	16
1367	4	1	4	16
1368	6	16	2	16
1369	6	12	2	16
1370	13	5	4	16
1371	8	12	2	16
1372	5	15	2	16
1373	14	14	2	16
1374	1	5	2	16
1375	12	6	2	16
1376	9	15	4	16
1377	7	7	4	16
1378	12	15	2	16
1379	3	9	4	16
1380	10	8	0	16
1381	3	17	2	16
1382	14	15	1	16
1383	9	11	2	16
1384	14	13	1	16
1385	7	1	2	16
1386	11	14	6	16
1387	3	1	4	16
1388	5	16	2	16
1389	11	18	6	16
1390	14	5	2	16
1391	5	12	2	16
1392	7	6	2	16
1393	9	5	4	16
1394	7	4	2	16
1395	5	11	2	16
1396	6	5	2	16
1397	4	9	4	16
1398	4	7	4	16
1399	7	17	2	16
1400	11	8	6	16
1401	9	16	4	16
1402	14	4	4	16
1403	11	6	6	16
1404	4	5	4	16
1405	8	8	2	16
1406	11	9	6	16
1407	9	10	1	16
1408	7	11	2	16
1409	5	9	4	16
1410	12	12	4	16
1411	13	12	2	16
1412	11	12	6	16
1413	1	13	2	16
1414	3	11	4	16
1415	14	18	2	16
1416	8	13	1	16
1417	4	10	2	16
1418	5	5	4	16
1419	9	6	4	16
1420	14	12	1	16
1421	3	4	4	16
1422	11	5	6	16
1423	6	10	1	16
1424	14	17	1	16
1425	5	14	4	16
1426	12	1	2	16
1427	11	11	6	16
1428	2	12	2	16
1429	9	18	4	16
1430	4	17	2	16
1431	8	6	2	16
1432	4	12	2	16
1433	13	9	4	16
1434	10	17	2	16
1435	6	7	4	16
1436	1	15	0	16
1437	10	16	0	16
1438	11	16	6	16
1439	3	14	2	16
1440	2	18	4	16
1441	2	9	4	16
1442	10	7	4	16
1443	12	18	2	16
1444	8	5	1	16
1445	8	14	4	16
1446	4	18	4	16
1447	4	14	4	16
1448	11	17	6	16
1449	10	4	2	16
1450	10	13	2	16
1451	1	4	2	16
1452	6	11	2	16
1453	2	14	4	16
1454	1	6	2	16
1455	12	16	2	16
1456	11	15	6	16
1457	6	6	2	16
1458	9	9	4	16
1459	14	7	2	16
1460	4	6	4	16
1461	10	12	2	16
1462	8	9	2	16
1463	8	15	4	16
1464	9	14	2	16
1465	6	13	2	16
1466	7	12	2	16
1467	14	9	2	16
1468	10	15	0	16
1469	1	10	0	16
1470	12	13	2	16
1471	4	4	4	16
1472	8	18	2	16
1473	5	8	2	16
1474	11	13	6	16
1475	9	1	2	16
1476	2	6	4	16
1477	11	1	6	16
1478	14	8	2	16
1479	10	10	0	16
1480	7	15	2	16
1481	5	1	4	16
1482	12	5	1	16
1483	13	4	4	16
1484	12	17	2	16
1485	2	4	4	16
1486	1	17	4	16
1487	2	8	2	16
1488	6	8	2	16
1489	5	6	4	16
1490	13	16	2	16
1491	8	4	2	16
1492	10	1	2	16
1493	5	10	2	16
1494	12	14	2	16
1495	8	11	2	16
1496	13	6	4	16
1497	12	9	2	16
1498	8	7	2	16
1499	9	13	2	16
1500	4	16	2	16
1501	1	12	2	16
1502	3	5	4	16
1503	14	10	2	16
1504	10	18	2	16
1505	1	16	2	16
1506	12	11	2	16
1507	4	11	4	16
1508	13	13	2	16
1509	1	7	4	16
1510	2	10	2	16
1511	4	15	4	16
1512	3	16	2	16
1513	10	14	1	16
1514	7	5	2	16
1515	9	12	2	16
1516	10	6	2	16
1517	2	16	2	16
1518	6	17	1	16
1519	8	16	2	16
1520	2	11	4	16
1521	12	7	2	16
1522	13	18	4	16
1523	3	18	4	16
1524	11	4	6	16
1525	14	1	2	16
1526	13	17	0	16
1527	10	5	2	16
1528	3	6	4	16
1529	13	10	2	16
1530	3	7	4	16
1531	13	15	0	16
1532	11	7	6	16
1533	8	10	4	16
1534	6	4	2	16
1535	1	18	2	16
1536	12	10	2	16
1537	2	1	4	16
1538	11	10	6	16
1539	10	11	0	16
1540	10	9	2	16
1541	7	18	2	16
1542	3	10	4	16
1543	13	14	4	16
1544	6	1	2	16
1545	13	1	4	16
1546	7	10	0	16
1547	7	13	4	16
1548	7	9	4	16
1549	5	7	4	16
1550	13	7	4	16
1551	2	15	2	16
1552	5	18	4	16
1553	9	8	2	16
1554	12	8	2	16
1555	5	17	0	16
1556	13	8	4	16
1557	1	14	2	16
1558	2	5	4	16
1559	3	8	4	16
1560	6	14	2	16
1561	8	1	2	16
1562	14	11	4	16
1563	14	16	1	16
1564	14	6	2	16
1565	8	17	1	16
1566	2	7	4	16
1567	7	16	4	16
1568	12	4	2	16
673	1	8	1	1
674	5	13	2	1
675	7	8	2	1
676	6	18	2	1
677	2	13	2	1
678	7	14	0	1
679	3	12	4	1
680	3	15	2	1
681	13	11	4	1
682	1	1	2	1
683	9	7	2	1
684	4	8	2	1
685	3	13	4	1
686	5	4	4	1
687	6	9	2	1
688	9	4	4	1
689	6	15	2	1
690	2	17	1	1
691	4	13	4	1
692	1	11	1	1
693	1	9	2	1
694	9	17	2	1
695	4	1	4	1
696	6	16	2	1
697	6	12	2	1
698	13	5	4	1
699	8	12	2	1
700	5	15	2	1
701	14	14	2	1
702	1	5	2	1
703	12	6	2	1
704	9	15	4	1
705	7	7	4	1
706	12	15	2	1
707	3	9	4	1
708	10	8	0	1
709	3	17	2	1
710	14	15	1	1
711	9	11	2	1
712	14	13	1	1
713	7	1	2	1
714	11	14	6	1
715	3	1	4	1
716	5	16	2	1
717	11	18	6	1
718	14	5	2	1
719	5	12	2	1
720	7	6	2	1
721	9	5	4	1
722	7	4	2	1
723	5	11	2	1
724	6	5	2	1
725	4	9	4	1
726	4	7	4	1
727	7	17	2	1
728	11	8	6	1
729	9	16	4	1
730	14	4	4	1
731	11	6	6	1
732	4	5	4	1
733	8	8	2	1
734	11	9	6	1
735	9	10	1	1
736	7	11	2	1
737	5	9	4	1
738	12	12	4	1
739	13	12	2	1
740	11	12	6	1
741	1	13	2	1
742	3	11	4	1
743	14	18	2	1
744	8	13	1	1
745	4	10	2	1
746	5	5	4	1
747	9	6	4	1
748	14	12	1	1
749	3	4	4	1
750	11	5	6	1
751	6	10	1	1
752	14	17	1	1
753	5	14	4	1
754	12	1	2	1
755	11	11	6	1
756	2	12	2	1
757	9	18	4	1
758	4	17	2	1
759	8	6	2	1
760	4	12	2	1
761	13	9	4	1
762	10	17	2	1
763	6	7	4	1
764	1	15	0	1
765	10	16	0	1
766	11	16	6	1
767	3	14	2	1
768	2	18	4	1
769	2	9	4	1
770	10	7	4	1
771	12	18	2	1
772	8	5	1	1
773	8	14	4	1
774	4	18	4	1
775	4	14	4	1
776	11	17	6	1
777	10	4	2	1
778	10	13	2	1
779	1	4	2	1
780	6	11	2	1
781	2	14	4	1
782	1	6	2	1
783	12	16	2	1
784	11	15	6	1
785	6	6	2	1
786	9	9	4	1
787	14	7	2	1
788	4	6	4	1
789	10	12	2	1
790	8	9	2	1
791	8	15	4	1
792	9	14	2	1
793	6	13	2	1
794	7	12	2	1
795	14	9	2	1
796	10	15	0	1
797	1	10	0	1
798	12	13	2	1
799	4	4	4	1
800	8	18	2	1
801	5	8	2	1
802	11	13	6	1
803	9	1	2	1
804	2	6	4	1
805	11	1	6	1
806	14	8	2	1
807	10	10	0	1
808	7	15	2	1
809	5	1	4	1
810	12	5	1	1
811	13	4	4	1
812	12	17	2	1
813	2	4	4	1
814	1	17	4	1
815	2	8	2	1
816	6	8	2	1
817	5	6	4	1
818	13	16	2	1
819	8	4	2	1
820	10	1	2	1
821	5	10	2	1
822	12	14	2	1
823	8	11	2	1
824	13	6	4	1
825	12	9	2	1
826	8	7	2	1
827	9	13	2	1
828	4	16	2	1
829	1	12	2	1
830	3	5	4	1
831	14	10	2	1
832	10	18	2	1
833	1	16	2	1
834	12	11	2	1
835	4	11	4	1
836	13	13	2	1
837	1	7	4	1
838	2	10	2	1
839	4	15	4	1
840	3	16	2	1
841	10	14	1	1
842	7	5	2	1
843	9	12	2	1
844	10	6	2	1
845	2	16	2	1
846	6	17	1	1
847	8	16	2	1
848	2	11	4	1
849	12	7	2	1
850	13	18	4	1
851	3	18	4	1
852	11	4	6	1
853	14	1	2	1
854	13	17	0	1
855	10	5	2	1
856	3	6	4	1
857	13	10	2	1
858	3	7	4	1
859	13	15	0	1
860	11	7	6	1
861	8	10	4	1
862	6	4	2	1
863	1	18	2	1
864	12	10	2	1
865	2	1	4	1
866	11	10	6	1
867	10	11	0	1
868	10	9	2	1
869	7	18	2	1
870	3	10	4	1
871	13	14	4	1
872	6	1	2	1
873	13	1	4	1
874	7	10	0	1
875	7	13	4	1
876	7	9	4	1
877	5	7	4	1
878	13	7	4	1
879	2	15	2	1
880	5	18	4	1
881	9	8	2	1
882	12	8	2	1
883	5	17	0	1
884	13	8	4	1
885	1	14	2	1
886	2	5	4	1
887	3	8	4	1
888	6	14	2	1
889	8	1	2	1
890	14	11	4	1
891	14	16	1	1
892	14	6	2	1
893	8	17	1	1
894	2	7	4	1
895	7	16	4	1
896	12	4	2	1
2913	5	13	2	20
2914	1	8	1	20
2915	7	8	2	20
2916	6	18	2	20
2917	2	13	2	20
2918	7	14	0	20
2919	3	12	4	20
2920	3	15	2	20
2921	13	11	4	20
2922	9	7	2	20
2923	1	1	2	20
2924	4	8	2	20
2925	5	4	4	20
2926	3	13	4	20
2927	6	9	2	20
2928	9	4	4	20
2929	6	15	2	20
2930	2	17	1	20
2931	4	13	4	20
2932	1	11	1	20
2933	1	9	2	20
2934	9	17	2	20
2935	4	1	4	20
2936	6	12	2	20
2937	6	16	2	20
2938	13	5	4	20
2939	8	12	2	20
2940	5	15	2	20
2941	14	14	2	20
2942	1	5	2	20
2943	12	6	2	20
2944	9	15	4	20
2945	7	7	4	20
2946	12	15	2	20
2947	3	9	4	20
2948	10	8	0	20
2949	3	17	2	20
2950	14	15	1	20
2951	9	11	2	20
2952	14	13	1	20
2953	7	1	2	20
2954	11	14	6	20
2955	5	16	2	20
2956	3	1	4	20
2957	11	18	6	20
2958	14	5	2	20
2959	5	12	2	20
2960	9	5	4	20
2961	7	6	2	20
2962	7	4	2	20
2963	5	11	2	20
2964	6	5	2	20
2965	4	7	4	20
2966	4	9	4	20
2967	7	17	2	20
2968	11	8	6	20
2969	9	16	4	20
2970	14	4	4	20
2971	11	6	6	20
2972	4	5	4	20
2973	8	8	2	20
2974	11	9	6	20
2975	9	10	1	20
2976	7	11	2	20
2977	5	9	4	20
2978	12	12	4	20
2979	13	12	2	20
2980	11	12	6	20
2981	1	13	2	20
2982	3	11	4	20
2983	14	18	2	20
2984	8	13	1	20
2985	4	10	2	20
2986	5	5	4	20
2987	9	6	4	20
2988	14	12	1	20
2989	3	4	4	20
2990	11	5	6	20
2991	6	10	1	20
2992	14	17	1	20
2993	5	14	4	20
2994	12	1	2	20
2995	11	11	6	20
2996	9	18	4	20
2997	4	17	2	20
2998	2	12	2	20
2999	8	6	2	20
3000	4	12	2	20
3001	13	9	4	20
3002	10	17	2	20
3003	6	7	4	20
3004	1	15	0	20
3005	10	16	0	20
3006	11	16	6	20
3007	3	14	2	20
3008	2	18	4	20
3009	2	9	4	20
3010	10	7	4	20
3011	12	18	2	20
3012	8	5	1	20
3013	8	14	4	20
3014	4	14	4	20
3015	4	18	4	20
3016	11	17	6	20
3017	10	4	2	20
3018	10	13	2	20
3019	1	4	2	20
3020	6	11	2	20
3021	2	14	4	20
3022	1	6	2	20
3023	12	16	2	20
3024	11	15	6	20
3025	9	9	4	20
3026	6	6	2	20
3027	14	7	2	20
3028	4	6	4	20
3029	10	12	2	20
3030	8	9	2	20
3031	9	14	2	20
3032	8	15	4	20
3033	6	13	2	20
3034	7	12	2	20
3035	14	9	2	20
3036	10	15	0	20
3037	1	10	0	20
3038	12	13	2	20
3039	4	4	4	20
3040	8	18	2	20
3041	5	8	2	20
3042	11	13	6	20
3043	9	1	2	20
3044	2	6	4	20
3045	11	1	6	20
3046	14	8	2	20
3047	10	10	0	20
3048	7	15	2	20
3049	5	1	4	20
3050	12	5	1	20
3051	13	4	4	20
3052	12	17	2	20
3053	2	4	4	20
3054	2	8	2	20
3055	1	17	4	20
3056	6	8	2	20
3057	5	6	4	20
3058	13	16	2	20
3059	8	4	2	20
3060	10	1	2	20
3061	5	10	2	20
3062	12	14	2	20
3063	8	11	2	20
3064	13	6	4	20
3065	12	9	2	20
3066	9	13	2	20
3067	8	7	2	20
3068	4	16	2	20
3069	3	5	4	20
3070	1	12	2	20
3071	14	10	2	20
3072	10	18	2	20
3073	1	16	2	20
3074	12	11	2	20
3075	4	11	4	20
3076	13	13	2	20
3077	1	7	4	20
3078	4	15	4	20
3079	2	10	2	20
3080	3	16	2	20
3081	10	14	1	20
3082	9	12	2	20
3083	7	5	2	20
3084	10	6	2	20
3085	2	16	2	20
3086	6	17	1	20
3087	8	16	2	20
3088	2	11	4	20
3089	12	7	2	20
3090	13	18	4	20
3091	3	18	4	20
3092	11	4	6	20
3093	14	1	2	20
3094	13	17	0	20
3095	10	5	2	20
3096	3	6	4	20
3097	13	10	2	20
3098	3	7	4	20
3099	13	15	0	20
3100	11	7	6	20
3101	8	10	4	20
3102	6	4	2	20
3103	1	18	2	20
3104	12	10	2	20
3105	2	1	4	20
3106	11	10	6	20
3107	10	11	0	20
3108	10	9	2	20
3109	7	18	2	20
3110	3	10	4	20
3111	13	14	4	20
3112	6	1	2	20
3113	13	1	4	20
3114	7	13	4	20
3115	7	10	0	20
3116	7	9	4	20
3117	5	7	4	20
3118	13	7	4	20
3119	5	18	4	20
3120	2	15	2	20
3121	9	8	2	20
3122	12	8	2	20
3123	5	17	0	20
3124	13	8	4	20
3125	2	5	4	20
3126	1	14	2	20
3127	3	8	4	20
3128	6	14	2	20
3129	8	1	2	20
3130	14	11	4	20
3131	14	16	1	20
3132	14	6	2	20
3133	8	17	1	20
3134	2	7	4	20
3135	7	16	4	20
3136	12	4	2	20
1569	5	13	2	17
1570	1	8	1	17
1571	7	8	2	17
1572	6	18	2	17
1573	2	13	2	17
1574	7	14	0	17
1575	3	12	4	17
1576	3	15	2	17
1577	13	11	4	17
1578	9	7	2	17
1579	1	1	2	17
1580	4	8	2	17
1581	5	4	4	17
1582	3	13	4	17
1583	6	9	2	17
1584	9	4	4	17
1585	6	15	2	17
1586	2	17	1	17
1587	4	13	4	17
1588	1	11	1	17
1589	1	9	2	17
1590	9	17	2	17
1591	4	1	4	17
1592	6	12	2	17
1593	6	16	2	17
1594	13	5	4	17
1595	8	12	2	17
1596	5	15	2	17
1597	14	14	2	17
1598	1	5	2	17
1599	12	6	2	17
1600	9	15	4	17
1601	7	7	4	17
1602	12	15	2	17
1603	3	9	4	17
1604	10	8	0	17
1605	3	17	2	17
1606	14	15	1	17
1607	9	11	2	17
1608	14	13	1	17
1609	7	1	2	17
1610	11	14	6	17
1611	5	16	2	17
1612	3	1	4	17
1613	11	18	6	17
1614	14	5	2	17
1615	5	12	2	17
1616	9	5	4	17
1617	7	6	2	17
1618	7	4	2	17
1619	5	11	2	17
1620	6	5	2	17
1621	4	7	4	17
1622	4	9	4	17
1623	7	17	2	17
1624	11	8	6	17
1625	9	16	4	17
1626	14	4	4	17
1627	11	6	6	17
1628	4	5	4	17
1629	8	8	2	17
1630	11	9	6	17
1631	9	10	1	17
1632	7	11	2	17
1633	5	9	4	17
1634	12	12	4	17
1635	13	12	2	17
1636	11	12	6	17
1637	1	13	2	17
1638	3	11	4	17
1639	14	18	2	17
1640	8	13	1	17
1641	4	10	2	17
1642	5	5	4	17
1643	9	6	4	17
1644	14	12	1	17
1645	3	4	4	17
1646	11	5	6	17
1647	6	10	1	17
1648	14	17	1	17
1649	5	14	4	17
1650	12	1	2	17
1651	11	11	6	17
1652	9	18	4	17
1653	4	17	2	17
1654	2	12	2	17
1655	8	6	2	17
1656	4	12	2	17
1657	13	9	4	17
1658	10	17	2	17
1659	6	7	4	17
1660	1	15	0	17
1661	10	16	0	17
1662	11	16	6	17
1663	3	14	2	17
1664	2	18	4	17
1665	2	9	4	17
1666	10	7	4	17
1667	12	18	2	17
1668	8	5	1	17
1669	8	14	4	17
1670	4	14	4	17
1671	4	18	4	17
1672	11	17	6	17
1673	10	4	2	17
1674	10	13	2	17
1675	1	4	2	17
1676	6	11	2	17
1677	2	14	4	17
1678	1	6	2	17
1679	12	16	2	17
1680	11	15	6	17
1681	9	9	4	17
1682	6	6	2	17
1683	14	7	2	17
1684	4	6	4	17
1685	10	12	2	17
1686	8	9	2	17
1687	9	14	2	17
1688	8	15	4	17
1689	6	13	2	17
1690	7	12	2	17
1691	14	9	2	17
1692	10	15	0	17
1693	1	10	0	17
1705	5	1	4	17
1706	12	5	1	17
1707	13	4	4	17
1708	12	17	2	17
1709	2	4	4	17
1710	2	8	2	17
1711	1	17	4	17
1712	6	8	2	17
1713	5	6	4	17
1714	13	16	2	17
1715	8	4	2	17
1716	10	1	2	17
1717	5	10	2	17
1718	12	14	2	17
1719	8	11	2	17
1720	13	6	4	17
1721	12	9	2	17
1722	9	13	2	17
1723	8	7	2	17
1724	4	16	2	17
1725	3	5	4	17
1726	1	12	2	17
1727	14	10	2	17
1728	10	18	2	17
1729	1	16	2	17
1730	12	11	2	17
1731	4	11	4	17
1732	13	13	2	17
1733	1	7	4	17
1734	4	15	4	17
1735	2	10	2	17
1736	3	16	2	17
1737	10	14	1	17
1738	9	12	2	17
1739	7	5	2	17
1740	10	6	2	17
1741	2	16	2	17
1742	6	17	1	17
1743	8	16	2	17
1744	2	11	4	17
1745	12	7	2	17
1746	13	18	4	17
1747	3	18	4	17
1748	11	4	6	17
1749	14	1	2	17
1750	13	17	0	17
1751	10	5	2	17
1752	3	6	4	17
1753	13	10	2	17
1754	3	7	4	17
1755	13	15	0	17
1756	11	7	6	17
1757	8	10	4	17
1758	6	4	2	17
1759	1	18	2	17
1760	12	10	2	17
1761	2	1	4	17
1762	11	10	6	17
1763	10	11	0	17
1764	10	9	2	17
1765	7	18	2	17
1766	3	10	4	17
1767	13	14	4	17
1768	6	1	2	17
1769	13	1	4	17
1770	7	13	4	17
1771	7	10	0	17
1772	7	9	4	17
1773	5	7	4	17
1774	13	7	4	17
1775	5	18	4	17
1776	2	15	2	17
1777	9	8	2	17
1778	12	8	2	17
1779	5	17	0	17
1780	13	8	4	17
1781	2	5	4	17
1782	1	14	2	17
1783	3	8	4	17
1784	6	14	2	17
1785	8	1	2	17
1786	14	11	4	17
1787	14	16	1	17
1788	14	6	2	17
1789	8	17	1	17
1790	2	7	4	17
1791	7	16	4	17
1792	12	4	2	17
1793	5	13	2	18
1794	1	8	1	18
1795	7	8	2	18
1796	6	18	2	18
1797	2	13	2	18
1798	7	14	0	18
1799	3	12	4	18
1800	3	15	2	18
1801	13	11	4	18
1802	9	7	2	18
1803	1	1	2	18
1804	4	8	2	18
1805	5	4	4	18
1806	3	13	4	18
1807	6	9	2	18
1808	9	4	4	18
1809	6	15	2	18
1810	2	17	1	18
1811	4	13	4	18
1812	1	11	1	18
1813	1	9	2	18
1814	9	17	2	18
1815	4	1	4	18
1816	6	12	2	18
1817	6	16	2	18
1818	13	5	4	18
1819	8	12	2	18
1820	5	15	2	18
1821	14	14	2	18
1822	1	5	2	18
1823	12	6	2	18
1824	9	15	4	18
1825	7	7	4	18
1826	12	15	2	18
1827	3	9	4	18
1828	10	8	0	18
1829	3	17	2	18
1830	14	15	1	18
1831	9	11	2	18
1832	14	13	1	18
1833	7	1	2	18
1834	11	14	6	18
1835	5	16	2	18
1836	3	1	4	18
1837	11	18	6	18
1838	14	5	2	18
1839	5	12	2	18
1840	9	5	4	18
1841	7	6	2	18
1842	7	4	2	18
1843	5	11	2	18
1844	6	5	2	18
1845	4	7	4	18
1846	4	9	4	18
1847	7	17	2	18
1848	11	8	6	18
1849	9	16	4	18
1850	14	4	4	18
1851	11	6	6	18
1852	4	5	4	18
1853	8	8	2	18
1854	11	9	6	18
1855	9	10	1	18
1856	7	11	2	18
1857	5	9	4	18
1858	12	12	4	18
1859	13	12	2	18
1860	11	12	6	18
1861	1	13	2	18
1862	3	11	4	18
1863	14	18	2	18
1864	8	13	1	18
1865	4	10	2	18
1866	5	5	4	18
1867	9	6	4	18
1868	14	12	1	18
1869	3	4	4	18
1870	11	5	6	18
1871	6	10	1	18
1872	14	17	1	18
1873	5	14	4	18
1874	12	1	2	18
1875	11	11	6	18
1876	9	18	4	18
1877	4	17	2	18
1878	2	12	2	18
1879	8	6	2	18
1880	4	12	2	18
1881	13	9	4	18
1882	10	17	2	18
1883	6	7	4	18
1884	1	15	0	18
1885	10	16	0	18
1886	11	16	6	18
1887	3	14	2	18
1888	2	18	4	18
1889	2	9	4	18
1890	10	7	4	18
1891	12	18	2	18
1892	8	5	1	18
1893	8	14	4	18
1894	4	14	4	18
1895	4	18	4	18
1896	11	17	6	18
1897	10	4	2	18
1898	10	13	2	18
1899	1	4	2	18
1900	6	11	2	18
1901	2	14	4	18
1902	1	6	2	18
1903	12	16	2	18
1904	11	15	6	18
1905	9	9	4	18
1906	6	6	2	18
1907	14	7	2	18
1908	4	6	4	18
1909	10	12	2	18
1910	8	9	2	18
1911	9	14	2	18
1912	8	15	4	18
1913	6	13	2	18
1914	7	12	2	18
1915	14	9	2	18
1916	10	15	0	18
1917	1	10	0	18
1918	12	13	2	18
1919	4	4	4	18
1920	8	18	2	18
1921	5	8	2	18
1922	11	13	6	18
1923	9	1	2	18
1924	2	6	4	18
1925	11	1	6	18
1926	14	8	2	18
1927	10	10	0	18
1928	7	15	2	18
1929	5	1	4	18
1930	12	5	1	18
1931	13	4	4	18
1932	12	17	2	18
1933	2	4	4	18
1934	2	8	2	18
1935	1	17	4	18
1936	6	8	2	18
1937	5	6	4	18
1938	13	16	2	18
1939	8	4	2	18
1940	10	1	2	18
1941	5	10	2	18
1942	12	14	2	18
1943	8	11	2	18
1944	13	6	4	18
1945	12	9	2	18
1946	9	13	2	18
1947	8	7	2	18
1948	4	16	2	18
1949	3	5	4	18
1950	1	12	2	18
1951	14	10	2	18
1952	10	18	2	18
1953	1	16	2	18
1954	12	11	2	18
1955	4	11	4	18
1956	13	13	2	18
1957	1	7	4	18
1958	4	15	4	18
1959	2	10	2	18
1960	3	16	2	18
1961	10	14	1	18
1962	9	12	2	18
1963	7	5	2	18
1964	10	6	2	18
1965	2	16	2	18
1966	6	17	1	18
1967	8	16	2	18
1968	2	11	4	18
1969	12	7	2	18
1970	13	18	4	18
1971	3	18	4	18
1972	11	4	6	18
1973	14	1	2	18
1974	13	17	0	18
1975	10	5	2	18
1976	3	6	4	18
1977	13	10	2	18
1978	3	7	4	18
1979	13	15	0	18
1980	11	7	6	18
1981	8	10	4	18
1982	6	4	2	18
1983	1	18	2	18
1984	12	10	2	18
1985	2	1	4	18
1986	11	10	6	18
1987	10	11	0	18
1988	10	9	2	18
1989	7	18	2	18
1990	3	10	4	18
1991	13	14	4	18
1992	6	1	2	18
1993	13	1	4	18
1994	7	13	4	18
1995	7	10	0	18
1996	7	9	4	18
1997	5	7	4	18
1998	13	7	4	18
1999	5	18	4	18
2000	2	15	2	18
2001	9	8	2	18
2002	12	8	2	18
2003	5	17	0	18
2004	13	8	4	18
2005	2	5	4	18
2006	1	14	2	18
2007	3	8	4	18
2008	6	14	2	18
2009	8	1	2	18
2010	14	11	4	18
2011	14	16	1	18
2012	14	6	2	18
2013	8	17	1	18
2014	2	7	4	18
2015	7	16	4	18
2016	12	4	2	18
2689	1	8	1	19
2690	5	13	2	19
2691	7	8	2	19
2692	6	18	2	19
2693	2	13	2	19
2694	7	14	0	19
2695	3	12	4	19
2696	3	15	2	19
2697	13	11	4	19
2698	1	1	2	19
2699	9	7	2	19
2700	4	8	2	19
2701	3	13	4	19
2702	5	4	4	19
2703	6	9	2	19
2704	9	4	4	19
2705	6	15	2	19
2706	2	17	1	19
2707	4	13	4	19
2708	1	11	1	19
2709	1	9	2	19
2710	9	17	2	19
2711	4	1	4	19
2712	6	16	2	19
2713	6	12	2	19
2714	13	5	4	19
2715	8	12	2	19
2716	5	15	2	19
2717	14	14	2	19
2718	1	5	2	19
2719	12	6	2	19
2720	9	15	4	19
2721	7	7	4	19
2722	12	15	2	19
2723	3	9	4	19
2724	10	8	0	19
2725	3	17	2	19
2726	14	15	1	19
2727	9	11	2	19
2728	14	13	1	19
2729	7	1	2	19
2730	11	14	6	19
2731	3	1	4	19
2732	5	16	2	19
2733	11	18	6	19
2734	14	5	2	19
2735	5	12	2	19
2736	7	6	2	19
2737	9	5	4	19
2738	7	4	2	19
2739	5	11	2	19
2740	6	5	2	19
2741	4	9	4	19
2742	4	7	4	19
2743	7	17	2	19
2744	11	8	6	19
2745	9	16	4	19
2746	14	4	4	19
2747	11	6	6	19
2748	4	5	4	19
2749	8	8	2	19
2750	11	9	6	19
2751	9	10	1	19
2752	7	11	2	19
2753	5	9	4	19
2754	12	12	4	19
2755	13	12	2	19
2756	11	12	6	19
2757	1	13	2	19
2758	3	11	4	19
2759	14	18	2	19
2760	8	13	1	19
2761	4	10	2	19
2762	5	5	4	19
2763	9	6	4	19
2764	14	12	1	19
2765	3	4	4	19
2766	11	5	6	19
2767	6	10	1	19
2768	14	17	1	19
2769	5	14	4	19
2770	12	1	2	19
2771	11	11	6	19
2772	2	12	2	19
2773	9	18	4	19
2774	4	17	2	19
2775	8	6	2	19
2776	4	12	2	19
2777	13	9	4	19
2778	10	17	2	19
2779	6	7	4	19
2780	1	15	0	19
2781	10	16	0	19
2782	11	16	6	19
2783	3	14	2	19
2784	2	18	4	19
2785	2	9	4	19
2786	10	7	4	19
2787	12	18	2	19
2788	8	5	1	19
2789	8	14	4	19
2790	4	18	4	19
2791	4	14	4	19
2792	11	17	6	19
2793	10	4	2	19
2794	10	13	2	19
2795	1	4	2	19
2796	6	11	2	19
2797	2	14	4	19
2798	1	6	2	19
2799	12	16	2	19
2800	11	15	6	19
2801	6	6	2	19
2802	9	9	4	19
2803	14	7	2	19
2804	4	6	4	19
2805	10	12	2	19
2806	8	9	2	19
2807	8	15	4	19
2808	9	14	2	19
2809	6	13	2	19
2810	7	12	2	19
2811	14	9	2	19
2812	10	15	0	19
2813	1	10	0	19
2814	12	13	2	19
2815	4	4	4	19
2816	8	18	2	19
2817	5	8	2	19
2818	11	13	6	19
2819	9	1	2	19
2820	2	6	4	19
2821	11	1	6	19
2822	14	8	2	19
2823	10	10	0	19
2824	7	15	2	19
2825	5	1	4	19
2826	12	5	1	19
2827	13	4	4	19
2828	12	17	2	19
2829	2	4	4	19
2830	1	17	4	19
2831	2	8	2	19
2832	6	8	2	19
2833	5	6	4	19
2834	13	16	2	19
2835	8	4	2	19
2836	10	1	2	19
2837	5	10	2	19
2838	12	14	2	19
2839	8	11	2	19
2840	13	6	4	19
2841	12	9	2	19
2842	8	7	2	19
2843	9	13	2	19
2844	4	16	2	19
2845	1	12	2	19
2846	3	5	4	19
2847	14	10	2	19
2848	10	18	2	19
2849	1	16	2	19
2850	12	11	2	19
2851	4	11	4	19
2852	13	13	2	19
2853	1	7	4	19
2854	2	10	2	19
2855	4	15	4	19
2856	3	16	2	19
2857	10	14	1	19
2858	7	5	2	19
2859	9	12	2	19
2860	10	6	2	19
2861	2	16	2	19
2862	6	17	1	19
2863	8	16	2	19
2864	2	11	4	19
2865	12	7	2	19
2866	13	18	4	19
2867	3	18	4	19
2868	11	4	6	19
2869	14	1	2	19
2870	13	17	0	19
2871	10	5	2	19
2872	3	6	4	19
2873	13	10	2	19
2874	3	7	4	19
2875	13	15	0	19
2876	11	7	6	19
2877	8	10	4	19
2878	6	4	2	19
2879	1	18	2	19
2880	12	10	2	19
2881	2	1	4	19
2882	11	10	6	19
2883	10	11	0	19
2884	10	9	2	19
2885	7	18	2	19
2886	3	10	4	19
2887	13	14	4	19
2888	6	1	2	19
2889	13	1	4	19
2890	7	10	0	19
2891	7	13	4	19
2892	7	9	4	19
2893	5	7	4	19
2894	13	7	4	19
2895	2	15	2	19
2896	5	18	4	19
2897	9	8	2	19
2898	12	8	2	19
2899	5	17	0	19
2900	13	8	4	19
2901	1	14	2	19
2902	2	5	4	19
2903	3	8	4	19
2904	6	14	2	19
2905	8	1	2	19
2906	14	11	4	19
2907	14	16	1	19
2908	14	6	2	19
2909	8	17	1	19
2910	2	7	4	19
2911	7	16	4	19
2912	12	4	2	19
\.


--
-- Data for Name: role_process_matrix; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.role_process_matrix (id, role_cluster_id, iso_process_id, role_process_value, organization_id) FROM stdin;
1206	4	1	1	15
1207	4	2	1	15
1208	4	3	0	15
1209	4	4	0	15
1210	4	5	0	15
1211	4	6	0	15
1212	4	7	0	15
1213	4	8	0	15
1214	4	9	0	15
1215	4	10	0	15
1216	4	11	2	15
1217	4	12	2	15
1218	4	13	2	15
1219	4	14	1	15
1220	4	15	0	15
1221	4	16	0	15
1222	4	17	0	15
1223	4	18	1	15
1224	4	19	2	15
1225	4	20	2	15
1226	4	21	2	15
1227	4	22	1	15
1228	4	23	0	15
1229	4	24	0	15
1230	4	25	1	15
1231	4	26	0	15
1232	4	27	0	15
1233	4	28	1	15
1234	5	1	0	15
30	4	1	1	1
31	4	2	1	1
32	4	3	0	1
33	4	4	0	1
34	4	5	0	1
35	4	6	0	1
36	4	7	0	1
37	4	8	0	1
38	4	9	0	1
39	4	10	0	1
40	4	11	2	1
41	4	12	2	1
42	4	13	2	1
43	4	14	1	1
44	4	15	0	1
45	4	16	0	1
46	4	17	0	1
47	4	18	1	1
48	4	19	2	1
49	4	20	2	1
50	4	21	2	1
51	4	22	1	1
52	4	23	0	1
53	4	24	0	1
54	4	25	1	1
55	4	26	0	1
56	4	27	0	1
57	4	28	1	1
58	5	1	0	1
59	5	2	0	1
60	5	3	0	1
61	5	4	0	1
62	5	5	0	1
63	5	6	0	1
64	5	7	1	1
65	5	8	0	1
66	5	9	0	1
67	5	10	0	1
68	5	11	1	1
69	5	12	1	1
70	5	13	1	1
71	5	14	1	1
72	5	15	0	1
73	5	16	0	1
74	5	17	2	1
75	5	18	2	1
76	5	19	0	1
77	5	20	0	1
78	5	21	1	1
79	5	22	2	1
80	5	23	0	1
81	5	24	0	1
82	5	25	0	1
83	5	26	0	1
84	5	27	0	1
85	5	28	0	1
86	9	1	0	1
87	9	2	0	1
88	9	3	0	1
89	9	4	0	1
90	9	5	0	1
91	9	6	0	1
92	9	7	0	1
93	9	8	0	1
94	9	9	0	1
95	9	10	0	1
96	9	11	1	1
97	9	12	1	1
98	9	13	1	1
99	9	14	0	1
100	9	15	0	1
101	9	16	0	1
102	9	17	0	1
103	9	18	0	1
104	9	19	0	1
105	9	20	0	1
106	9	21	2	1
107	9	22	2	1
108	9	23	2	1
109	9	24	0	1
110	9	25	2	1
111	9	26	0	1
112	9	27	0	1
113	9	28	0	1
114	3	1	0	1
115	3	2	1	1
116	3	3	0	1
117	3	4	0	1
118	3	5	1	1
119	3	6	0	1
120	3	7	0	1
121	3	8	0	1
122	3	9	2	1
123	3	10	2	1
124	3	11	2	1
125	3	12	2	1
126	3	13	2	1
127	3	14	2	1
128	3	15	0	1
129	3	16	1	1
130	3	17	0	1
131	3	18	0	1
132	3	19	0	1
133	3	20	0	1
134	3	21	0	1
135	3	22	0	1
136	3	23	0	1
137	3	24	0	1
138	3	25	0	1
139	3	26	0	1
140	3	27	0	1
141	3	28	0	1
142	2	1	0	1
143	2	2	2	1
144	2	3	0	1
145	2	4	0	1
146	2	5	1	1
147	2	6	0	1
148	2	7	0	1
149	2	8	0	1
150	2	9	0	1
151	2	10	0	1
152	2	11	2	1
153	2	12	1	1
154	2	13	1	1
155	2	14	1	1
156	2	15	0	1
157	2	16	1	1
158	2	17	2	1
159	2	18	2	1
160	2	19	2	1
161	2	20	1	1
162	2	21	1	1
163	2	22	0	1
164	2	23	0	1
165	2	24	1	1
166	2	25	1	1
167	2	26	2	1
168	2	27	1	1
169	2	28	0	1
170	1	1	0	1
171	1	2	0	1
172	1	3	0	1
173	1	4	0	1
174	1	5	0	1
175	1	6	0	1
176	1	7	0	1
177	1	8	0	1
178	1	9	0	1
179	1	10	0	1
180	1	11	0	1
181	1	12	0	1
182	1	13	0	1
183	1	14	0	1
184	1	15	0	1
185	1	16	0	1
186	1	17	0	1
187	1	18	0	1
188	1	19	0	1
189	1	20	0	1
190	1	21	0	1
191	1	22	0	1
192	1	23	0	1
193	1	24	0	1
194	1	25	0	1
195	1	26	2	1
196	1	27	1	1
197	1	28	2	1
198	6	1	2	1
199	6	2	1	1
200	6	3	0	1
201	6	4	0	1
202	6	5	0	1
203	6	6	0	1
204	6	7	0	1
205	6	8	0	1
206	6	9	0	1
207	6	10	0	1
208	6	11	1	1
209	6	12	1	1
210	6	13	0	1
211	6	14	0	1
212	6	15	0	1
213	6	16	0	1
214	6	17	0	1
215	6	18	0	1
216	6	19	0	1
217	6	20	0	1
218	6	21	0	1
219	6	22	0	1
220	6	23	2	1
221	6	24	1	1
222	6	25	0	1
223	6	26	2	1
224	6	27	0	1
225	6	28	0	1
226	7	1	0	1
227	7	2	0	1
228	7	3	0	1
229	7	4	0	1
230	7	5	0	1
231	7	6	0	1
232	7	7	0	1
233	7	8	0	1
234	7	9	0	1
235	7	10	0	1
236	7	11	0	1
237	7	12	0	1
238	7	13	0	1
239	7	14	0	1
240	7	15	0	1
241	7	16	0	1
242	7	17	0	1
243	7	18	0	1
244	7	19	0	1
245	7	20	0	1
246	7	21	0	1
247	7	22	0	1
248	7	23	2	1
249	7	24	2	1
250	7	25	0	1
251	7	26	0	1
252	7	27	0	1
253	7	28	0	1
254	8	1	0	1
255	8	2	0	1
256	8	3	0	1
257	8	4	0	1
258	8	5	0	1
259	8	6	0	1
260	8	7	2	1
261	8	8	0	1
262	8	9	0	1
263	8	10	0	1
264	8	11	0	1
265	8	12	1	1
266	8	13	0	1
267	8	14	0	1
268	8	15	0	1
269	8	16	2	1
270	8	17	0	1
271	8	18	0	1
272	8	19	0	1
273	8	20	0	1
274	8	21	0	1
275	8	22	0	1
276	8	23	0	1
277	8	24	0	1
278	8	25	1	1
279	8	26	0	1
280	8	27	1	1
281	8	28	0	1
282	10	1	0	1
283	10	2	1	1
284	10	3	0	1
285	10	4	0	1
286	10	5	0	1
287	10	6	0	1
288	10	7	0	1
289	10	8	0	1
290	10	9	0	1
291	10	10	0	1
292	10	11	0	1
293	10	12	0	1
294	10	13	0	1
295	10	14	0	1
296	10	15	0	1
297	10	16	0	1
298	10	17	0	1
299	10	18	0	1
300	10	19	0	1
301	10	20	0	1
302	10	21	0	1
303	10	22	0	1
304	10	23	0	1
305	10	24	0	1
306	10	25	0	1
307	10	26	2	1
308	10	27	0	1
309	10	28	1	1
310	11	1	3	1
311	11	2	3	1
312	11	3	3	1
313	11	4	3	1
314	11	5	3	1
315	11	6	3	1
316	11	7	3	1
317	11	8	3	1
318	11	9	3	1
319	11	10	3	1
320	11	11	3	1
321	11	12	3	1
322	11	13	3	1
323	11	14	3	1
324	11	15	3	1
325	11	16	3	1
326	11	17	3	1
327	11	18	3	1
328	11	19	3	1
329	11	20	3	1
330	11	21	3	1
331	11	22	3	1
332	11	23	3	1
333	11	24	3	1
334	11	25	3	1
335	11	26	3	1
336	11	27	3	1
337	11	28	3	1
338	12	1	0	1
339	12	2	0	1
340	12	3	1	1
341	12	4	2	1
342	12	5	0	1
343	12	6	2	1
344	12	7	0	1
345	12	8	2	1
346	12	9	0	1
347	12	10	0	1
348	12	11	0	1
349	12	12	0	1
350	12	13	0	1
351	12	14	0	1
352	12	15	0	1
353	12	16	0	1
354	12	17	0	1
355	12	18	0	1
356	12	19	0	1
357	12	20	0	1
358	12	21	0	1
359	12	22	0	1
360	12	23	0	1
361	12	24	0	1
362	12	25	0	1
363	12	26	0	1
364	12	27	0	1
365	12	28	0	1
366	13	1	0	1
367	13	2	0	1
368	13	3	0	1
369	13	4	0	1
370	13	5	2	1
371	13	6	0	1
372	13	7	0	1
373	13	8	0	1
374	13	9	0	1
375	13	10	0	1
376	13	11	1	1
377	13	12	0	1
378	13	13	0	1
379	13	14	0	1
380	13	15	0	1
381	13	16	0	1
382	13	17	2	1
383	13	18	0	1
384	13	19	0	1
385	13	20	0	1
386	13	21	0	1
387	13	22	0	1
388	13	23	0	1
389	13	24	0	1
390	13	25	0	1
391	13	26	0	1
392	13	27	0	1
393	13	28	0	1
394	14	1	0	1
395	14	2	0	1
396	14	3	0	1
397	14	4	0	1
398	14	5	1	1
399	14	6	1	1
400	14	7	0	1
401	14	8	0	1
402	14	9	0	1
403	14	10	1	1
404	14	11	2	1
405	14	12	0	1
406	14	13	0	1
407	14	14	0	1
408	14	15	0	1
409	14	16	0	1
410	14	17	1	1
411	14	18	0	1
412	14	19	0	1
413	14	20	0	1
414	14	21	0	1
415	14	22	0	1
416	14	23	0	1
417	14	24	0	1
418	14	25	0	1
419	14	26	0	1
420	14	27	0	1
421	14	28	0	1
1235	5	2	0	15
1236	5	3	0	15
1237	5	4	0	15
1238	5	5	0	15
1239	5	6	0	15
1240	5	7	1	15
1241	5	8	0	15
1242	5	9	0	15
1243	5	10	0	15
1244	5	11	1	15
1245	5	12	1	15
1246	5	13	1	15
1247	5	14	1	15
1248	5	15	0	15
1249	5	16	0	15
1250	5	17	2	15
1251	5	18	2	15
1252	5	19	0	15
1253	5	20	0	15
1254	5	21	1	15
1255	5	22	2	15
1256	5	23	0	15
1257	5	24	0	15
1258	5	25	0	15
1259	5	26	0	15
1260	5	27	0	15
1261	5	28	0	15
1262	9	1	0	15
1263	9	2	0	15
1264	9	3	0	15
1265	9	4	0	15
1266	9	5	0	15
1267	9	6	0	15
1268	9	7	0	15
1269	9	8	0	15
1270	9	9	0	15
1271	9	10	0	15
1272	9	11	1	15
1273	9	12	1	15
1274	9	13	1	15
1275	9	14	0	15
1276	9	15	0	15
1277	9	16	0	15
1278	9	17	0	15
1279	9	18	0	15
1280	9	19	0	15
1281	9	20	0	15
1282	9	21	2	15
1283	9	22	2	15
1284	9	23	2	15
1285	9	24	0	15
1286	9	25	2	15
1287	9	26	0	15
1288	9	27	0	15
1289	9	28	0	15
1290	3	1	0	15
1291	3	2	1	15
1292	3	3	0	15
1293	3	4	0	15
1294	3	5	1	15
1295	3	6	0	15
1296	3	7	0	15
1297	3	8	0	15
1298	3	9	2	15
1299	3	10	2	15
1300	3	11	2	15
1301	3	12	2	15
1302	3	13	2	15
1303	3	14	2	15
1304	3	15	0	15
1305	3	16	1	15
1306	3	17	0	15
1307	3	18	0	15
1308	3	19	0	15
1309	3	20	0	15
1310	3	21	0	15
1311	3	22	0	15
1312	3	23	0	15
1313	3	24	0	15
1314	3	25	0	15
1315	3	26	0	15
1316	3	27	0	15
1317	3	28	0	15
1318	2	1	0	15
1319	2	2	2	15
1320	2	3	0	15
1321	2	4	0	15
1322	2	5	1	15
1323	2	6	0	15
1324	2	7	0	15
1325	2	8	0	15
1326	2	9	0	15
1327	2	10	0	15
1328	2	11	2	15
1329	2	12	1	15
1330	2	13	1	15
1331	2	14	1	15
1332	2	15	0	15
1333	2	16	1	15
1334	2	17	2	15
1335	2	18	2	15
1336	2	19	2	15
1337	2	20	1	15
1338	2	21	1	15
1339	2	22	0	15
1340	2	23	0	15
1341	2	24	1	15
1342	2	25	1	15
1343	2	26	2	15
1344	2	27	1	15
1345	2	28	0	15
1346	1	1	0	15
1347	1	2	0	15
1348	1	3	0	15
1349	1	4	0	15
1350	1	5	0	15
1351	1	6	0	15
1352	1	7	0	15
1353	1	8	0	15
1354	1	9	0	15
1355	1	10	0	15
1356	1	11	0	15
1357	1	12	0	15
1358	1	13	0	15
1359	1	14	0	15
1360	1	15	0	15
1361	1	16	0	15
1362	1	17	0	15
1363	1	18	0	15
1364	1	19	0	15
1365	1	20	0	15
1366	1	21	0	15
1367	1	22	0	15
1368	1	23	0	15
1369	1	24	0	15
1370	1	25	0	15
1371	1	26	2	15
1372	1	27	1	15
1373	1	28	2	15
1374	6	1	2	15
1375	6	2	1	15
1376	6	3	0	15
1377	6	4	0	15
1378	6	5	0	15
1379	6	6	0	15
1380	6	7	0	15
1381	6	8	0	15
1382	6	9	0	15
1383	6	10	0	15
1384	6	11	1	15
1385	6	12	1	15
1386	6	13	0	15
1387	6	14	0	15
1388	6	15	0	15
1389	6	16	0	15
1390	6	17	0	15
1391	6	18	0	15
1392	6	19	0	15
1393	6	20	0	15
1394	6	21	0	15
1395	6	22	0	15
1396	6	23	2	15
1397	6	24	1	15
1398	6	25	0	15
1399	6	26	2	15
1400	6	27	0	15
1401	6	28	0	15
1402	7	1	0	15
1403	7	2	0	15
1404	7	3	0	15
1405	7	4	0	15
1406	7	5	0	15
1407	7	6	0	15
1408	7	7	0	15
1409	7	8	0	15
1410	7	9	0	15
1411	7	10	0	15
1412	7	11	0	15
1413	7	12	0	15
1414	7	13	0	15
1415	7	14	0	15
1416	7	15	0	15
1417	7	16	0	15
1418	7	17	0	15
1419	7	18	0	15
1420	7	19	0	15
1421	7	20	0	15
1422	7	21	0	15
1423	7	22	0	15
1424	7	23	2	15
1425	7	24	2	15
1426	7	25	0	15
1427	7	26	0	15
1428	7	27	0	15
1429	7	28	0	15
1430	8	1	0	15
1431	8	2	0	15
1432	8	3	0	15
1433	8	4	0	15
1434	8	5	0	15
1435	8	6	0	15
1436	8	7	2	15
1437	8	8	0	15
1438	8	9	0	15
1439	8	10	0	15
1440	8	11	0	15
1441	8	12	1	15
1442	8	13	0	15
1443	8	14	0	15
1444	8	15	0	15
1445	8	16	2	15
1446	8	17	0	15
1447	8	18	0	15
1448	8	19	0	15
1449	8	20	0	15
1450	8	21	0	15
1451	8	22	0	15
1452	8	23	0	15
1453	8	24	0	15
1454	8	25	1	15
1455	8	26	0	15
1456	8	27	1	15
1457	8	28	0	15
1458	10	1	0	15
1459	10	2	1	15
1460	10	3	0	15
1461	10	4	0	15
1462	10	5	0	15
1463	10	6	0	15
1464	10	7	0	15
1465	10	8	0	15
1466	10	9	0	15
1467	10	10	0	15
1468	10	11	0	15
1469	10	12	0	15
1470	10	13	0	15
1471	10	14	0	15
1472	10	15	0	15
1473	10	16	0	15
1474	10	17	0	15
1475	10	18	0	15
1476	10	19	0	15
1477	10	20	0	15
1478	10	21	0	15
1479	10	22	0	15
1480	10	23	0	15
1481	10	24	0	15
1482	10	25	0	15
1483	10	26	2	15
1484	10	27	0	15
1485	10	28	1	15
1486	11	1	3	15
1487	11	2	3	15
1488	11	3	3	15
1489	11	4	3	15
1490	11	5	3	15
1491	11	6	3	15
1492	11	7	3	15
1493	11	8	3	15
1494	11	9	3	15
1495	11	10	3	15
1496	11	11	3	15
1497	11	12	3	15
1498	11	13	3	15
1499	11	14	3	15
1500	11	15	3	15
1501	11	16	3	15
1502	11	17	3	15
1503	11	18	3	15
1504	11	19	3	15
1505	11	20	3	15
1506	11	21	3	15
1507	11	22	3	15
1508	11	23	3	15
1509	11	24	3	15
1510	11	25	3	15
1511	11	26	3	15
1512	11	27	3	15
1513	11	28	3	15
1514	12	1	0	15
1515	12	2	0	15
1516	12	3	1	15
1517	12	4	2	15
1518	12	5	0	15
1519	12	6	2	15
1520	12	7	0	15
1521	12	8	2	15
1522	12	9	0	15
1523	12	10	0	15
1524	12	11	0	15
1525	12	12	0	15
1526	12	13	0	15
1527	12	14	0	15
1528	12	15	0	15
1529	12	16	0	15
1530	12	17	0	15
1531	12	18	0	15
1532	12	19	0	15
1533	12	20	0	15
1534	12	21	0	15
1535	12	22	0	15
1536	12	23	0	15
1537	12	24	0	15
1538	12	25	0	15
1539	12	26	0	15
1540	12	27	0	15
1541	12	28	0	15
1542	13	1	0	15
1543	13	2	0	15
1544	13	3	0	15
1545	13	4	0	15
1546	13	5	2	15
1547	13	6	0	15
1548	13	7	0	15
1549	13	8	0	15
1550	13	9	0	15
1551	13	10	0	15
1552	13	11	1	15
1553	13	12	0	15
1554	13	13	0	15
1555	13	14	0	15
1556	13	15	0	15
1557	13	16	0	15
1558	13	17	2	15
1559	13	18	0	15
1560	13	19	0	15
1561	13	20	0	15
1562	13	21	0	15
1563	13	22	0	15
1564	13	23	0	15
1565	13	24	0	15
1566	13	25	0	15
1567	13	26	0	15
1568	13	27	0	15
1569	13	28	0	15
1570	14	1	0	15
1571	14	2	0	15
1572	14	3	0	15
1573	14	4	0	15
1574	14	5	1	15
1575	14	6	1	15
1576	14	7	0	15
1577	14	8	0	15
1578	14	9	0	15
1579	14	10	1	15
1580	14	11	2	15
1581	14	12	0	15
1582	14	13	0	15
1583	14	14	0	15
1584	14	15	0	15
1585	14	16	0	15
1586	14	17	1	15
1587	14	18	0	15
1588	14	19	0	15
1589	14	20	0	15
1590	14	21	0	15
1591	14	22	0	15
1592	14	23	0	15
1593	14	24	0	15
1594	14	25	0	15
1595	14	26	0	15
1596	14	27	0	15
1597	14	28	0	15
1598	4	1	1	11
1599	4	2	1	11
1600	4	3	0	11
1601	4	4	0	11
1602	4	5	0	11
1603	4	6	0	11
1604	4	7	0	11
1605	4	8	0	11
1606	4	9	0	11
1607	4	10	0	11
1608	4	11	2	11
1609	4	12	2	11
1610	4	13	2	11
1611	4	14	1	11
1612	4	15	0	11
1613	4	16	0	11
1614	4	17	0	11
1615	4	18	1	11
1616	4	19	2	11
1617	4	20	2	11
1618	4	21	2	11
1619	4	22	1	11
1620	4	23	0	11
1621	4	24	0	11
1622	4	25	1	11
1623	4	26	0	11
1624	4	27	0	11
1625	4	28	1	11
1626	5	1	0	11
1627	5	2	0	11
1628	5	3	0	11
1629	5	4	0	11
1630	5	5	0	11
1631	5	6	0	11
1632	5	7	1	11
1633	5	8	0	11
1634	5	9	0	11
1635	5	10	0	11
1636	5	11	1	11
1637	5	12	1	11
1638	5	13	1	11
1639	5	14	1	11
1640	5	15	0	11
1641	5	16	0	11
1642	5	17	2	11
1643	5	18	2	11
1644	5	19	0	11
1645	5	20	0	11
1646	5	21	1	11
1647	5	22	2	11
1648	5	23	0	11
1649	5	24	0	11
1650	5	25	0	11
1651	5	26	0	11
1652	5	27	0	11
1653	5	28	0	11
1654	9	1	0	11
1655	9	2	0	11
1656	9	3	0	11
1657	9	4	0	11
1658	9	5	0	11
1659	9	6	0	11
1660	9	7	0	11
1661	9	8	0	11
1662	9	9	0	11
1663	9	10	0	11
1664	9	11	1	11
1665	9	12	1	11
1666	9	13	1	11
1667	9	14	0	11
1668	9	15	0	11
1669	9	16	0	11
1670	9	17	0	11
1671	9	18	0	11
1672	9	19	0	11
1673	9	20	0	11
1674	9	21	2	11
1675	9	22	2	11
1676	9	23	2	11
1677	9	24	0	11
1678	9	25	2	11
1679	9	26	0	11
1680	9	27	0	11
1681	9	28	0	11
1682	3	1	0	11
1683	3	2	1	11
1684	3	3	0	11
1685	3	4	0	11
1686	3	5	1	11
1687	3	6	0	11
1688	3	7	0	11
1689	3	8	0	11
1690	3	9	2	11
1691	3	10	2	11
1692	3	11	2	11
1693	3	12	2	11
1694	3	13	2	11
1695	3	14	2	11
1696	3	15	0	11
1697	3	16	1	11
1698	3	17	0	11
1699	3	18	0	11
1700	3	19	0	11
1701	3	20	0	11
1702	3	21	0	11
1703	3	22	0	11
1704	3	23	0	11
1705	3	24	0	11
1706	3	25	0	11
1707	3	26	0	11
1708	3	27	0	11
1709	3	28	0	11
1710	2	1	0	11
1711	2	2	2	11
1712	2	3	0	11
1713	2	4	0	11
1714	2	5	1	11
1715	2	6	0	11
1716	2	7	0	11
1717	2	8	0	11
1718	2	9	0	11
1719	2	10	0	11
1720	2	11	2	11
1721	2	12	1	11
1722	2	13	1	11
1723	2	14	1	11
1724	2	15	0	11
1725	2	16	1	11
1726	2	17	2	11
1727	2	18	2	11
1728	2	19	2	11
1729	2	20	1	11
1730	2	21	1	11
1731	2	22	0	11
1732	2	23	0	11
1733	2	24	1	11
1734	2	25	1	11
1735	2	26	2	11
1736	2	27	1	11
1737	2	28	0	11
1738	1	1	0	11
1739	1	2	0	11
1740	1	3	0	11
1741	1	4	0	11
1742	1	5	0	11
1743	1	6	0	11
1744	1	7	0	11
1745	1	8	0	11
1746	1	9	0	11
1747	1	10	0	11
1748	1	11	0	11
1749	1	12	0	11
1750	1	13	0	11
1751	1	14	0	11
1752	1	15	0	11
1753	1	16	0	11
1754	1	17	0	11
1755	1	18	0	11
1756	1	19	0	11
1757	1	20	0	11
1758	1	21	0	11
1759	1	22	0	11
1760	1	23	0	11
1761	1	24	0	11
1762	1	25	0	11
1763	1	26	2	11
1764	1	27	1	11
1765	1	28	2	11
1766	6	1	2	11
1767	6	2	1	11
1768	6	3	0	11
1769	6	4	0	11
1770	6	5	0	11
1771	6	6	0	11
1772	6	7	0	11
1773	6	8	0	11
1774	6	9	0	11
1775	6	10	0	11
1776	6	11	1	11
1777	6	12	1	11
1778	6	13	0	11
1779	6	14	0	11
1780	6	15	0	11
1781	6	16	0	11
1782	6	17	0	11
1783	6	18	0	11
1784	6	19	0	11
1785	6	20	0	11
1786	6	21	0	11
1787	6	22	0	11
1788	6	23	2	11
1789	6	24	1	11
1790	6	25	0	11
1791	6	26	2	11
1792	6	27	0	11
1793	6	28	0	11
1794	7	1	0	11
1795	7	2	0	11
1796	7	3	0	11
1797	7	4	0	11
1798	7	5	0	11
1799	7	6	0	11
1800	7	7	0	11
1801	7	8	0	11
1802	7	9	0	11
1803	7	10	0	11
1804	7	11	0	11
1805	7	12	0	11
1806	7	13	0	11
1807	7	14	0	11
1808	7	15	0	11
1809	7	16	0	11
1810	7	17	0	11
1811	7	18	0	11
1812	7	19	0	11
1813	7	20	0	11
1814	7	21	0	11
1815	7	22	0	11
1816	7	23	2	11
1817	7	24	2	11
1818	7	25	0	11
1819	7	26	0	11
1820	7	27	0	11
1821	7	28	0	11
1822	8	1	0	11
1823	8	2	0	11
1824	8	3	0	11
1825	8	4	0	11
1826	8	5	0	11
1827	8	6	0	11
1828	8	7	2	11
1829	8	8	0	11
1830	8	9	0	11
1831	8	10	0	11
1832	8	11	0	11
1833	8	12	1	11
1834	8	13	0	11
1835	8	14	0	11
1836	8	15	0	11
1837	8	16	2	11
1838	8	17	0	11
1839	8	18	0	11
1840	8	19	0	11
1841	8	20	0	11
1842	8	21	0	11
1843	8	22	0	11
1844	8	23	0	11
1845	8	24	0	11
1846	8	25	1	11
1847	8	26	0	11
1848	8	27	1	11
1849	8	28	0	11
1850	10	1	0	11
1851	10	2	1	11
1852	10	3	0	11
1853	10	4	0	11
1854	10	5	0	11
1855	10	6	0	11
1856	10	7	0	11
1857	10	8	0	11
1858	10	9	0	11
1859	10	10	0	11
1860	10	11	0	11
1861	10	12	0	11
1862	10	13	0	11
1863	10	14	0	11
1864	10	15	0	11
1865	10	16	0	11
1866	10	17	0	11
1867	10	18	0	11
1868	10	19	0	11
1869	10	20	0	11
1870	10	21	0	11
1871	10	22	0	11
1872	10	23	0	11
1873	10	24	0	11
1874	10	25	0	11
1875	10	26	2	11
1876	10	27	0	11
1877	10	28	1	11
1878	11	1	3	11
1879	11	2	3	11
1880	11	3	3	11
1881	11	4	3	11
1882	11	5	3	11
1883	11	6	3	11
1884	11	7	3	11
1885	11	8	3	11
1886	11	9	3	11
1887	11	10	3	11
1888	11	11	3	11
1889	11	12	3	11
1890	11	13	3	11
1891	11	14	3	11
1892	11	15	3	11
1893	11	16	3	11
1894	11	17	3	11
1895	11	18	3	11
1896	11	19	3	11
1897	11	20	3	11
1898	11	21	3	11
1899	11	22	3	11
1900	11	23	3	11
1901	11	24	3	11
1902	11	25	3	11
1903	11	26	3	11
1904	11	27	3	11
1905	11	28	3	11
1906	12	1	0	11
1907	12	2	0	11
1908	12	3	1	11
1909	12	4	2	11
1910	12	5	0	11
1911	12	6	2	11
1912	12	7	0	11
1913	12	8	2	11
1914	12	9	0	11
1915	12	10	0	11
1916	12	11	0	11
1917	12	12	0	11
1918	12	13	0	11
1919	12	14	0	11
1920	12	15	0	11
1921	12	16	0	11
1922	12	17	0	11
1923	12	18	0	11
1924	12	19	0	11
1925	12	20	0	11
1926	12	21	0	11
1927	12	22	0	11
1928	12	23	0	11
1929	12	24	0	11
1930	12	25	0	11
1931	12	26	0	11
1932	12	27	0	11
1933	12	28	0	11
1934	13	1	0	11
1935	13	2	0	11
1936	13	3	0	11
1937	13	4	0	11
1938	13	5	2	11
1939	13	6	0	11
1940	13	7	0	11
1941	13	8	0	11
1942	13	9	0	11
1943	13	10	0	11
1944	13	11	1	11
1945	13	12	0	11
1946	13	13	0	11
1947	13	14	0	11
1948	13	15	0	11
1949	13	16	0	11
1950	13	17	2	11
1951	13	18	0	11
1952	13	19	0	11
1953	13	20	0	11
1954	13	21	0	11
1955	13	22	0	11
1956	13	23	0	11
1957	13	24	0	11
1958	13	25	0	11
1959	13	26	0	11
1960	13	27	0	11
1961	13	28	0	11
1962	14	1	0	11
1963	14	2	0	11
1964	14	3	0	11
1965	14	4	0	11
1966	14	5	1	11
1967	14	6	1	11
1968	14	7	0	11
1969	14	8	0	11
1970	14	9	0	11
1971	14	10	1	11
1972	14	11	2	11
1973	14	12	0	11
1974	14	13	0	11
1975	14	14	0	11
1976	14	15	0	11
1977	14	16	0	11
1978	14	17	1	11
1979	14	18	0	11
1980	14	19	0	11
1981	14	20	0	11
1982	14	21	0	11
1983	14	22	0	11
1984	14	23	0	11
1985	14	24	0	11
1986	14	25	0	11
1987	14	26	0	11
1988	14	27	0	11
1989	14	28	0	11
1991	4	1	1	16
1992	4	2	1	16
1993	4	3	0	16
1994	4	4	0	16
1995	4	5	0	16
1996	4	6	0	16
1997	4	7	0	16
1998	4	8	0	16
1999	4	9	0	16
2000	4	10	0	16
2001	4	11	2	16
2002	4	12	2	16
2003	4	13	2	16
2004	4	14	1	16
2005	4	15	0	16
2006	4	16	0	16
2007	4	17	0	16
2008	4	18	1	16
2009	4	19	2	16
2010	4	20	2	16
2011	4	21	2	16
2012	4	22	1	16
2013	4	23	0	16
2014	4	24	0	16
2015	4	25	1	16
2016	4	26	0	16
2017	4	27	0	16
2018	4	28	1	16
2019	5	1	0	16
2020	5	2	0	16
2021	5	3	0	16
2022	5	4	0	16
2023	5	5	0	16
2024	5	6	0	16
2025	5	7	1	16
2026	5	8	0	16
2027	5	9	0	16
2028	5	10	0	16
2029	5	11	1	16
2030	5	12	1	16
2031	5	13	1	16
2032	5	14	1	16
2033	5	15	0	16
2034	5	16	0	16
2035	5	17	2	16
2036	5	18	2	16
2037	5	19	0	16
2038	5	20	0	16
2039	5	21	1	16
2040	5	22	2	16
2041	5	23	0	16
2042	5	24	0	16
2043	5	25	0	16
2044	5	26	0	16
2045	5	27	0	16
2046	5	28	0	16
2047	9	1	0	16
2048	9	2	0	16
2049	9	3	0	16
2050	9	4	0	16
2051	9	5	0	16
2052	9	6	0	16
2053	9	7	0	16
2054	9	8	0	16
2055	9	9	0	16
2056	9	10	0	16
2057	9	11	1	16
2058	9	12	1	16
2059	9	13	1	16
2060	9	14	0	16
2061	9	15	0	16
2062	9	16	0	16
2063	9	17	0	16
2064	9	18	0	16
2065	9	19	0	16
2066	9	20	0	16
2067	9	21	2	16
2068	9	22	2	16
2069	9	23	2	16
2070	9	24	0	16
2071	9	25	2	16
2072	9	26	0	16
2073	9	27	0	16
2074	9	28	0	16
2075	3	1	0	16
2076	3	2	1	16
2077	3	3	0	16
2078	3	4	0	16
2079	3	5	1	16
2080	3	6	0	16
2081	3	7	0	16
2082	3	8	0	16
2083	3	9	2	16
2084	3	10	2	16
2085	3	11	2	16
2086	3	12	2	16
2087	3	13	2	16
2088	3	14	2	16
2089	3	15	0	16
2090	3	16	1	16
2091	3	17	0	16
2092	3	18	0	16
2093	3	19	0	16
2094	3	20	0	16
2095	3	21	0	16
2096	3	22	0	16
2097	3	23	0	16
2098	3	24	0	16
2099	3	25	0	16
2100	3	26	0	16
2101	3	27	0	16
2102	3	28	0	16
2103	2	1	0	16
2104	2	2	2	16
2105	2	3	0	16
2106	2	4	0	16
2107	2	5	1	16
2108	2	6	0	16
2109	2	7	0	16
2110	2	8	0	16
2111	2	9	0	16
2112	2	10	0	16
2113	2	11	2	16
2114	2	12	1	16
2115	2	13	1	16
2116	2	14	1	16
2117	2	15	0	16
2118	2	16	1	16
2119	2	17	2	16
2120	2	18	2	16
2121	2	19	2	16
2122	2	20	1	16
2123	2	21	1	16
2124	2	22	0	16
2125	2	23	0	16
2126	2	24	1	16
2127	2	25	1	16
2128	2	26	2	16
2129	2	27	1	16
2130	2	28	0	16
2132	1	2	0	16
2133	1	3	0	16
2134	1	4	0	16
2135	1	5	0	16
2136	1	6	0	16
2137	1	7	0	16
2138	1	8	0	16
2139	1	9	0	16
2140	1	10	0	16
2141	1	11	0	16
2142	1	12	0	16
2143	1	13	0	16
2144	1	14	0	16
2145	1	15	0	16
2146	1	16	0	16
2147	1	17	0	16
2148	1	18	0	16
2149	1	19	0	16
2150	1	20	0	16
2151	1	21	0	16
2152	1	22	0	16
2153	1	23	0	16
2154	1	24	0	16
2155	1	25	0	16
2156	1	26	2	16
2157	1	27	1	16
2158	1	28	2	16
2159	6	1	2	16
2160	6	2	1	16
2161	6	3	0	16
2162	6	4	0	16
2163	6	5	0	16
2164	6	6	0	16
2165	6	7	0	16
2166	6	8	0	16
2167	6	9	0	16
2168	6	10	0	16
2169	6	11	1	16
2170	6	12	1	16
2171	6	13	0	16
2172	6	14	0	16
2173	6	15	0	16
2174	6	16	0	16
2175	6	17	0	16
2176	6	18	0	16
2177	6	19	0	16
2178	6	20	0	16
2179	6	21	0	16
2180	6	22	0	16
2181	6	23	2	16
2182	6	24	1	16
2183	6	25	0	16
2184	6	26	2	16
2185	6	27	0	16
2186	6	28	0	16
2187	7	1	0	16
2188	7	2	0	16
2189	7	3	0	16
2190	7	4	0	16
2191	7	5	0	16
2192	7	6	0	16
2193	7	7	0	16
2194	7	8	0	16
2195	7	9	0	16
2196	7	10	0	16
2197	7	11	0	16
2198	7	12	0	16
2199	7	13	0	16
2200	7	14	0	16
2201	7	15	0	16
2202	7	16	0	16
2203	7	17	0	16
2204	7	18	0	16
2205	7	19	0	16
2206	7	20	0	16
2207	7	21	0	16
2208	7	22	0	16
2209	7	23	2	16
2210	7	24	2	16
2211	7	25	0	16
2212	7	26	0	16
2213	7	27	0	16
2214	7	28	0	16
2215	8	1	0	16
2216	8	2	0	16
2217	8	3	0	16
2218	8	4	0	16
2219	8	5	0	16
2220	8	6	0	16
2221	8	7	2	16
2222	8	8	0	16
2223	8	9	0	16
2224	8	10	0	16
2225	8	11	0	16
2226	8	12	1	16
2227	8	13	0	16
2228	8	14	0	16
2229	8	15	0	16
2230	8	16	2	16
2231	8	17	0	16
2232	8	18	0	16
2233	8	19	0	16
2234	8	20	0	16
2235	8	21	0	16
2236	8	22	0	16
2237	8	23	0	16
2238	8	24	0	16
2239	8	25	1	16
2240	8	26	0	16
2241	8	27	1	16
2242	8	28	0	16
2243	10	1	0	16
2244	10	2	1	16
2245	10	3	0	16
2246	10	4	0	16
2247	10	5	0	16
2248	10	6	0	16
2249	10	7	0	16
2250	10	8	0	16
2251	10	9	0	16
2252	10	10	0	16
2253	10	11	0	16
2254	10	12	0	16
2255	10	13	0	16
2256	10	14	0	16
2257	10	15	0	16
2258	10	16	0	16
2259	10	17	0	16
2260	10	18	0	16
2261	10	19	0	16
2262	10	20	0	16
2263	10	21	0	16
2264	10	22	0	16
2265	10	23	0	16
2266	10	24	0	16
2267	10	25	0	16
2268	10	26	2	16
2269	10	27	0	16
2270	10	28	1	16
2271	11	1	3	16
2272	11	2	3	16
2273	11	3	3	16
2274	11	4	3	16
2275	11	5	3	16
2276	11	6	3	16
2277	11	7	3	16
2278	11	8	3	16
2279	11	9	3	16
2280	11	10	3	16
2281	11	11	3	16
2282	11	12	3	16
2283	11	13	3	16
2284	11	14	3	16
2285	11	15	3	16
2286	11	16	3	16
2287	11	17	3	16
2288	11	18	3	16
2289	11	19	3	16
2290	11	20	3	16
2291	11	21	3	16
2292	11	22	3	16
2293	11	23	3	16
2294	11	24	3	16
2295	11	25	3	16
2296	11	26	3	16
2297	11	27	3	16
2298	11	28	3	16
2299	12	1	0	16
2300	12	2	0	16
2301	12	3	1	16
2302	12	4	2	16
2303	12	5	0	16
2304	12	6	2	16
2305	12	7	0	16
2306	12	8	2	16
2307	12	9	0	16
2308	12	10	0	16
2309	12	11	0	16
2310	12	12	0	16
2311	12	13	0	16
2312	12	14	0	16
2313	12	15	0	16
2314	12	16	0	16
2315	12	17	0	16
2316	12	18	0	16
2317	12	19	0	16
2318	12	20	0	16
2319	12	21	0	16
2320	12	22	0	16
2321	12	23	0	16
2322	12	24	0	16
2323	12	25	0	16
2324	12	26	0	16
2325	12	27	0	16
2326	12	28	0	16
2327	13	1	0	16
2328	13	2	0	16
2329	13	3	0	16
2330	13	4	0	16
2331	13	5	2	16
2332	13	6	0	16
2333	13	7	0	16
2334	13	8	0	16
2335	13	9	0	16
2336	13	10	0	16
2337	13	11	1	16
2338	13	12	0	16
2339	13	13	0	16
2340	13	14	0	16
2341	13	15	0	16
2342	13	16	0	16
2343	13	17	2	16
2344	13	18	0	16
2345	13	19	0	16
2346	13	20	0	16
2347	13	21	0	16
2348	13	22	0	16
2349	13	23	0	16
2350	13	24	0	16
2351	13	25	0	16
2352	13	26	0	16
2353	13	27	0	16
2354	13	28	0	16
2355	14	1	0	16
2356	14	2	0	16
2357	14	3	0	16
2358	14	4	0	16
2359	14	5	1	16
2360	14	6	1	16
2361	14	7	0	16
2362	14	8	0	16
2363	14	9	0	16
2364	14	10	1	16
2365	14	11	2	16
2366	14	12	0	16
2367	14	13	0	16
2368	14	14	0	16
2369	14	15	0	16
2370	14	16	0	16
2371	14	17	1	16
2372	14	18	0	16
2373	14	19	0	16
2374	14	20	0	16
2375	14	21	0	16
2376	14	22	0	16
2377	14	23	0	16
2378	14	24	0	16
2379	14	25	0	16
2380	14	26	0	16
2381	14	27	0	16
2382	14	28	0	16
2131	1	1	2	16
2383	1	29	0	16
2384	1	30	0	16
2385	4	1	1	17
2386	4	2	1	17
2387	4	3	0	17
2388	4	4	0	17
2389	4	5	0	17
2390	4	6	0	17
2391	4	7	0	17
2392	4	8	0	17
2393	4	9	0	17
2394	4	10	0	17
2395	4	11	2	17
2396	4	12	2	17
2397	4	13	2	17
2398	4	14	1	17
2399	4	15	0	17
2400	4	16	0	17
2401	4	17	0	17
2402	4	18	1	17
2403	4	19	2	17
2404	4	20	2	17
2405	4	21	2	17
2406	4	22	1	17
2407	4	23	0	17
2408	4	24	0	17
2409	4	25	1	17
2410	4	26	0	17
2411	4	27	0	17
2412	4	28	1	17
2413	5	1	0	17
2414	5	2	0	17
2415	5	3	0	17
2416	5	4	0	17
2417	5	5	0	17
2418	5	6	0	17
2419	5	7	1	17
2420	5	8	0	17
2421	5	9	0	17
2422	5	10	0	17
2423	5	11	1	17
2424	5	12	1	17
2425	5	13	1	17
2426	5	14	1	17
2427	5	15	0	17
2428	5	16	0	17
2429	5	17	2	17
2430	5	18	2	17
2431	5	19	0	17
2432	5	20	0	17
2433	5	21	1	17
2434	5	22	2	17
2435	5	23	0	17
2436	5	24	0	17
2437	5	25	0	17
2438	5	26	0	17
2439	5	27	0	17
2440	5	28	0	17
2441	9	1	0	17
2442	9	2	0	17
2443	9	3	0	17
2444	9	4	0	17
2445	9	5	0	17
2446	9	6	0	17
2447	9	7	0	17
2448	9	8	0	17
2449	9	9	0	17
2450	9	10	0	17
2451	9	11	1	17
2452	9	12	1	17
2453	9	13	1	17
2454	9	14	0	17
2455	9	15	0	17
2456	9	16	0	17
2457	9	17	0	17
2458	9	18	0	17
2459	9	19	0	17
2460	9	20	0	17
2461	9	21	2	17
2462	9	22	2	17
2463	9	23	2	17
2464	9	24	0	17
2465	9	25	2	17
2466	9	26	0	17
2467	9	27	0	17
2468	9	28	0	17
2469	3	1	0	17
2470	3	2	1	17
2471	3	3	0	17
2472	3	4	0	17
2473	3	5	1	17
2474	3	6	0	17
2475	3	7	0	17
2476	3	8	0	17
2477	3	9	2	17
2478	3	10	2	17
2479	3	11	2	17
2480	3	12	2	17
2481	3	13	2	17
2482	3	14	2	17
2483	3	15	0	17
2484	3	16	1	17
2485	3	17	0	17
2486	3	18	0	17
2487	3	19	0	17
2488	3	20	0	17
2489	3	21	0	17
2490	3	22	0	17
2491	3	23	0	17
2492	3	24	0	17
2493	3	25	0	17
2494	3	26	0	17
2495	3	27	0	17
2496	3	28	0	17
2497	2	1	0	17
2498	2	2	2	17
2499	2	3	0	17
2500	2	4	0	17
2501	2	5	1	17
2502	2	6	0	17
2503	2	7	0	17
2504	2	8	0	17
2505	2	9	0	17
2506	2	10	0	17
2507	2	11	2	17
2508	2	12	1	17
2509	2	13	1	17
2510	2	14	1	17
2511	2	15	0	17
2512	2	16	1	17
2513	2	17	2	17
2514	2	18	2	17
2515	2	19	2	17
2516	2	20	1	17
2517	2	21	1	17
2518	2	22	0	17
2519	2	23	0	17
2520	2	24	1	17
2521	2	25	1	17
2522	2	26	2	17
2523	2	27	1	17
2524	2	28	0	17
2525	1	1	0	17
2526	1	2	0	17
2527	1	3	0	17
2528	1	4	0	17
2529	1	5	0	17
2530	1	6	0	17
2531	1	7	0	17
2532	1	8	0	17
2533	1	9	0	17
2534	1	10	0	17
2535	1	11	0	17
2536	1	12	0	17
2537	1	13	0	17
2538	1	14	0	17
2539	1	15	0	17
2540	1	16	0	17
2541	1	17	0	17
2542	1	18	0	17
2543	1	19	0	17
2544	1	20	0	17
2545	1	21	0	17
2546	1	22	0	17
2547	1	23	0	17
2548	1	24	0	17
2549	1	25	0	17
2550	1	26	2	17
2551	1	27	1	17
2552	1	28	2	17
2553	6	1	2	17
2554	6	2	1	17
2555	6	3	0	17
2556	6	4	0	17
2557	6	5	0	17
2558	6	6	0	17
2559	6	7	0	17
2560	6	8	0	17
2561	6	9	0	17
2562	6	10	0	17
2563	6	11	1	17
2564	6	12	1	17
2565	6	13	0	17
2566	6	14	0	17
2567	6	15	0	17
2568	6	16	0	17
2569	6	17	0	17
2570	6	18	0	17
2571	6	19	0	17
2572	6	20	0	17
2573	6	21	0	17
2574	6	22	0	17
2575	6	23	2	17
2576	6	24	1	17
2577	6	25	0	17
2578	6	26	2	17
2579	6	27	0	17
2580	6	28	0	17
2581	7	1	0	17
2582	7	2	0	17
2583	7	3	0	17
2584	7	4	0	17
2585	7	5	0	17
2586	7	6	0	17
2587	7	7	0	17
2588	7	8	0	17
2589	7	9	0	17
2590	7	10	0	17
2591	7	11	0	17
2592	7	12	0	17
2593	7	13	0	17
2594	7	14	0	17
2595	7	15	0	17
2596	7	16	0	17
2597	7	17	0	17
2598	7	18	0	17
2599	7	19	0	17
2600	7	20	0	17
2601	7	21	0	17
2602	7	22	0	17
2603	7	23	2	17
2604	7	24	2	17
2605	7	25	0	17
2606	7	26	0	17
2607	7	27	0	17
2608	7	28	0	17
2609	8	1	0	17
2610	8	2	0	17
2611	8	3	0	17
2612	8	4	0	17
2613	8	5	0	17
2614	8	6	0	17
2615	8	7	2	17
2616	8	8	0	17
2617	8	9	0	17
2618	8	10	0	17
2619	8	11	0	17
2620	8	12	1	17
2621	8	13	0	17
2622	8	14	0	17
2623	8	15	0	17
2624	8	16	2	17
2625	8	17	0	17
2626	8	18	0	17
2627	8	19	0	17
2628	8	20	0	17
2629	8	21	0	17
2630	8	22	0	17
2631	8	23	0	17
2632	8	24	0	17
2633	8	25	1	17
2634	8	26	0	17
2635	8	27	1	17
2636	8	28	0	17
2637	10	1	0	17
2638	10	2	1	17
2639	10	3	0	17
2640	10	4	0	17
2641	10	5	0	17
2642	10	6	0	17
2643	10	7	0	17
2644	10	8	0	17
2645	10	9	0	17
2646	10	10	0	17
2647	10	11	0	17
2648	10	12	0	17
2649	10	13	0	17
2650	10	14	0	17
2651	10	15	0	17
2652	10	16	0	17
2653	10	17	0	17
2654	10	18	0	17
2655	10	19	0	17
2656	10	20	0	17
2657	10	21	0	17
2658	10	22	0	17
2659	10	23	0	17
2660	10	24	0	17
2661	10	25	0	17
2662	10	26	2	17
2663	10	27	0	17
2664	10	28	1	17
2665	11	1	3	17
2666	11	2	3	17
2667	11	3	3	17
2668	11	4	3	17
2669	11	5	3	17
2670	11	6	3	17
2671	11	7	3	17
2672	11	8	3	17
2673	11	9	3	17
2674	11	10	3	17
2675	11	11	3	17
2676	11	12	3	17
2677	11	13	3	17
2678	11	14	3	17
2679	11	15	3	17
2680	11	16	3	17
2681	11	17	3	17
2682	11	18	3	17
2683	11	19	3	17
2684	11	20	3	17
2685	11	21	3	17
2686	11	22	3	17
2687	11	23	3	17
2688	11	24	3	17
2689	11	25	3	17
2690	11	26	3	17
2691	11	27	3	17
2692	11	28	3	17
2693	12	1	0	17
2694	12	2	0	17
2695	12	3	1	17
2696	12	4	2	17
2697	12	5	0	17
2698	12	6	2	17
2699	12	7	0	17
2700	12	8	2	17
2701	12	9	0	17
2702	12	10	0	17
2703	12	11	0	17
2704	12	12	0	17
2705	12	13	0	17
2706	12	14	0	17
2707	12	15	0	17
2708	12	16	0	17
2709	12	17	0	17
2710	12	18	0	17
2711	12	19	0	17
2712	12	20	0	17
2713	12	21	0	17
2714	12	22	0	17
2715	12	23	0	17
2716	12	24	0	17
2717	12	25	0	17
2718	12	26	0	17
2719	12	27	0	17
2720	12	28	0	17
2721	13	1	0	17
2722	13	2	0	17
2723	13	3	0	17
2724	13	4	0	17
2725	13	5	2	17
2726	13	6	0	17
2727	13	7	0	17
2728	13	8	0	17
2729	13	9	0	17
2730	13	10	0	17
2731	13	11	1	17
2732	13	12	0	17
2733	13	13	0	17
2734	13	14	0	17
2735	13	15	0	17
2736	13	16	0	17
2737	13	17	2	17
2738	13	18	0	17
2739	13	19	0	17
2740	13	20	0	17
2741	13	21	0	17
2742	13	22	0	17
2743	13	23	0	17
2744	13	24	0	17
2745	13	25	0	17
2746	13	26	0	17
2747	13	27	0	17
2748	13	28	0	17
2749	14	1	0	17
2750	14	2	0	17
2751	14	3	0	17
2752	14	4	0	17
2753	14	5	1	17
2754	14	6	1	17
2755	14	7	0	17
2756	14	8	0	17
2757	14	9	0	17
2758	14	10	1	17
2759	14	11	2	17
2760	14	12	0	17
2761	14	13	0	17
2762	14	14	0	17
2763	14	15	0	17
2764	14	16	0	17
2765	14	17	1	17
2766	14	18	0	17
2767	14	19	0	17
2768	14	20	0	17
2769	14	21	0	17
2770	14	22	0	17
2771	14	23	0	17
2772	14	24	0	17
2773	14	25	0	17
2774	14	26	0	17
2775	14	27	0	17
2776	14	28	0	17
2777	4	1	1	18
2778	4	2	1	18
2779	4	3	0	18
2780	4	4	0	18
2781	4	5	0	18
2782	4	6	0	18
2783	4	7	0	18
2784	4	8	0	18
2785	4	9	0	18
2786	4	10	0	18
2787	4	11	2	18
2788	4	12	2	18
2789	4	13	2	18
2790	4	14	1	18
2791	4	15	0	18
2792	4	16	0	18
2793	4	17	0	18
2794	4	18	1	18
2795	4	19	2	18
2796	4	20	2	18
2797	4	21	2	18
2798	4	22	1	18
2799	4	23	0	18
2800	4	24	0	18
2801	4	25	1	18
2802	4	26	0	18
2803	4	27	0	18
2804	4	28	1	18
2805	5	1	0	18
2806	5	2	0	18
2807	5	3	0	18
2808	5	4	0	18
2809	5	5	0	18
2810	5	6	0	18
2811	5	7	1	18
2812	5	8	0	18
2813	5	9	0	18
2814	5	10	0	18
2815	5	11	1	18
2816	5	12	1	18
2817	5	13	1	18
2818	5	14	1	18
2819	5	15	0	18
2820	5	16	0	18
2821	5	17	2	18
2822	5	18	2	18
2823	5	19	0	18
2824	5	20	0	18
2825	5	21	1	18
2826	5	22	2	18
2827	5	23	0	18
2828	5	24	0	18
2829	5	25	0	18
2830	5	26	0	18
2831	5	27	0	18
2832	5	28	0	18
2833	9	1	0	18
2834	9	2	0	18
2835	9	3	0	18
2836	9	4	0	18
2837	9	5	0	18
2838	9	6	0	18
2839	9	7	0	18
2840	9	8	0	18
2841	9	9	0	18
2842	9	10	0	18
2843	9	11	1	18
2844	9	12	1	18
2845	9	13	1	18
2846	9	14	0	18
2847	9	15	0	18
2848	9	16	0	18
2849	9	17	0	18
2850	9	18	0	18
2851	9	19	0	18
2852	9	20	0	18
2853	9	21	2	18
2854	9	22	2	18
2855	9	23	2	18
2856	9	24	0	18
2857	9	25	2	18
2858	9	26	0	18
2859	9	27	0	18
2860	9	28	0	18
2861	3	1	0	18
2862	3	2	1	18
2863	3	3	0	18
2864	3	4	0	18
2865	3	5	1	18
2866	3	6	0	18
2867	3	7	0	18
2868	3	8	0	18
2869	3	9	2	18
2870	3	10	2	18
2871	3	11	2	18
2872	3	12	2	18
2873	3	13	2	18
2874	3	14	2	18
2875	3	15	0	18
2876	3	16	1	18
2877	3	17	0	18
2878	3	18	0	18
2879	3	19	0	18
2880	3	20	0	18
2881	3	21	0	18
2882	3	22	0	18
2883	3	23	0	18
2884	3	24	0	18
2885	3	25	0	18
2886	3	26	0	18
2887	3	27	0	18
2888	3	28	0	18
2889	2	1	0	18
2890	2	2	2	18
2891	2	3	0	18
2892	2	4	0	18
2893	2	5	1	18
2894	2	6	0	18
2895	2	7	0	18
2896	2	8	0	18
2897	2	9	0	18
2898	2	10	0	18
2899	2	11	2	18
2900	2	12	1	18
2901	2	13	1	18
2902	2	14	1	18
2903	2	15	0	18
2904	2	16	1	18
2905	2	17	2	18
2906	2	18	2	18
2907	2	19	2	18
2908	2	20	1	18
2909	2	21	1	18
2910	2	22	0	18
2911	2	23	0	18
2912	2	24	1	18
2913	2	25	1	18
2914	2	26	2	18
2915	2	27	1	18
2916	2	28	0	18
2917	1	1	0	18
2918	1	2	0	18
2919	1	3	0	18
2920	1	4	0	18
2921	1	5	0	18
2922	1	6	0	18
2923	1	7	0	18
2924	1	8	0	18
2925	1	9	0	18
2926	1	10	0	18
2927	1	11	0	18
2928	1	12	0	18
2929	1	13	0	18
2930	1	14	0	18
2931	1	15	0	18
2932	1	16	0	18
2933	1	17	0	18
2934	1	18	0	18
2935	1	19	0	18
2936	1	20	0	18
2937	1	21	0	18
2938	1	22	0	18
2939	1	23	0	18
2940	1	24	0	18
2941	1	25	0	18
2942	1	26	2	18
2943	1	27	1	18
2944	1	28	2	18
2945	6	1	2	18
2946	6	2	1	18
2947	6	3	0	18
2948	6	4	0	18
2949	6	5	0	18
2950	6	6	0	18
2951	6	7	0	18
2952	6	8	0	18
2953	6	9	0	18
2954	6	10	0	18
2955	6	11	1	18
2956	6	12	1	18
2957	6	13	0	18
2958	6	14	0	18
2959	6	15	0	18
2960	6	16	0	18
2961	6	17	0	18
2962	6	18	0	18
2963	6	19	0	18
2964	6	20	0	18
2965	6	21	0	18
2966	6	22	0	18
2967	6	23	2	18
2968	6	24	1	18
2969	6	25	0	18
2970	6	26	2	18
2971	6	27	0	18
2972	6	28	0	18
2973	7	1	0	18
2974	7	2	0	18
2975	7	3	0	18
2976	7	4	0	18
2977	7	5	0	18
2978	7	6	0	18
2979	7	7	0	18
2980	7	8	0	18
2981	7	9	0	18
2982	7	10	0	18
2983	7	11	0	18
2984	7	12	0	18
2985	7	13	0	18
2986	7	14	0	18
2987	7	15	0	18
2988	7	16	0	18
2989	7	17	0	18
2990	7	18	0	18
2991	7	19	0	18
2992	7	20	0	18
2993	7	21	0	18
2994	7	22	0	18
2995	7	23	2	18
2996	7	24	2	18
2997	7	25	0	18
2998	7	26	0	18
2999	7	27	0	18
3000	7	28	0	18
3001	8	1	0	18
3002	8	2	0	18
3003	8	3	0	18
3004	8	4	0	18
3005	8	5	0	18
3006	8	6	0	18
3007	8	7	2	18
3008	8	8	0	18
3009	8	9	0	18
3010	8	10	0	18
3011	8	11	0	18
3012	8	12	1	18
3013	8	13	0	18
3014	8	14	0	18
3015	8	15	0	18
3016	8	16	2	18
3017	8	17	0	18
3018	8	18	0	18
3019	8	19	0	18
3020	8	20	0	18
3021	8	21	0	18
3022	8	22	0	18
3023	8	23	0	18
3024	8	24	0	18
3025	8	25	1	18
3026	8	26	0	18
3027	8	27	1	18
3028	8	28	0	18
3029	10	1	0	18
3030	10	2	1	18
3031	10	3	0	18
3032	10	4	0	18
3033	10	5	0	18
3034	10	6	0	18
3035	10	7	0	18
3036	10	8	0	18
3037	10	9	0	18
3038	10	10	0	18
3039	10	11	0	18
3040	10	12	0	18
3041	10	13	0	18
3042	10	14	0	18
3043	10	15	0	18
3044	10	16	0	18
3045	10	17	0	18
3046	10	18	0	18
3047	10	19	0	18
3048	10	20	0	18
3049	10	21	0	18
3050	10	22	0	18
3051	10	23	0	18
3052	10	24	0	18
3053	10	25	0	18
3054	10	26	2	18
3055	10	27	0	18
3056	10	28	1	18
3057	11	1	3	18
3058	11	2	3	18
3059	11	3	3	18
3060	11	4	3	18
3061	11	5	3	18
3062	11	6	3	18
3063	11	7	3	18
3064	11	8	3	18
3065	11	9	3	18
3066	11	10	3	18
3067	11	11	3	18
3068	11	12	3	18
3069	11	13	3	18
3070	11	14	3	18
3071	11	15	3	18
3072	11	16	3	18
3073	11	17	3	18
3074	11	18	3	18
3075	11	19	3	18
3076	11	20	3	18
3077	11	21	3	18
3078	11	22	3	18
3079	11	23	3	18
3080	11	24	3	18
3081	11	25	3	18
3082	11	26	3	18
3083	11	27	3	18
3084	11	28	3	18
3085	12	1	0	18
3086	12	2	0	18
3087	12	3	1	18
3088	12	4	2	18
3089	12	5	0	18
3090	12	6	2	18
3091	12	7	0	18
3092	12	8	2	18
3093	12	9	0	18
3094	12	10	0	18
3095	12	11	0	18
3096	12	12	0	18
3097	12	13	0	18
3098	12	14	0	18
3099	12	15	0	18
3100	12	16	0	18
3101	12	17	0	18
3102	12	18	0	18
3103	12	19	0	18
3104	12	20	0	18
3105	12	21	0	18
3106	12	22	0	18
3107	12	23	0	18
3108	12	24	0	18
3109	12	25	0	18
3110	12	26	0	18
3111	12	27	0	18
3112	12	28	0	18
3113	13	1	0	18
3114	13	2	0	18
3115	13	3	0	18
3116	13	4	0	18
3117	13	5	2	18
3118	13	6	0	18
3119	13	7	0	18
3120	13	8	0	18
3121	13	9	0	18
3122	13	10	0	18
3123	13	11	1	18
3124	13	12	0	18
3125	13	13	0	18
3126	13	14	0	18
3127	13	15	0	18
3128	13	16	0	18
3129	13	17	2	18
3130	13	18	0	18
3131	13	19	0	18
3132	13	20	0	18
3133	13	21	0	18
3134	13	22	0	18
3135	13	23	0	18
3136	13	24	0	18
3137	13	25	0	18
3138	13	26	0	18
3139	13	27	0	18
3140	13	28	0	18
3141	14	1	0	18
3142	14	2	0	18
3143	14	3	0	18
3144	14	4	0	18
3145	14	5	1	18
3146	14	6	1	18
3147	14	7	0	18
3148	14	8	0	18
3149	14	9	0	18
3150	14	10	1	18
3151	14	11	2	18
3152	14	12	0	18
3153	14	13	0	18
3154	14	14	0	18
3155	14	15	0	18
3156	14	16	0	18
3157	14	17	1	18
3158	14	18	0	18
3159	14	19	0	18
3160	14	20	0	18
3161	14	21	0	18
3162	14	22	0	18
3163	14	23	0	18
3164	14	24	0	18
3165	14	25	0	18
3166	14	26	0	18
3167	14	27	0	18
3168	14	28	0	18
3169	4	1	1	19
3170	4	2	1	19
3171	4	3	0	19
3172	4	4	0	19
3173	4	5	0	19
3174	4	6	0	19
3175	4	7	0	19
3176	4	8	0	19
3177	4	9	0	19
3178	4	10	0	19
3179	4	11	2	19
3180	4	12	2	19
3181	4	13	2	19
3182	4	14	1	19
3183	4	15	0	19
3184	4	16	0	19
3185	4	17	0	19
3186	4	18	1	19
3187	4	19	2	19
3188	4	20	2	19
3189	4	21	2	19
3190	4	22	1	19
3191	4	23	0	19
3192	4	24	0	19
3193	4	25	1	19
3194	4	26	0	19
3195	4	27	0	19
3196	4	28	1	19
3197	5	1	0	19
3198	5	2	0	19
3199	5	3	0	19
3200	5	4	0	19
3201	5	5	0	19
3202	5	6	0	19
3203	5	7	1	19
3204	5	8	0	19
3205	5	9	0	19
3206	5	10	0	19
3207	5	11	1	19
3208	5	12	1	19
3209	5	13	1	19
3210	5	14	1	19
3211	5	15	0	19
3212	5	16	0	19
3213	5	17	2	19
3214	5	18	2	19
3215	5	19	0	19
3216	5	20	0	19
3217	5	21	1	19
3218	5	22	2	19
3219	5	23	0	19
3220	5	24	0	19
3221	5	25	0	19
3222	5	26	0	19
3223	5	27	0	19
3224	5	28	0	19
3225	9	1	0	19
3226	9	2	0	19
3227	9	3	0	19
3228	9	4	0	19
3229	9	5	0	19
3230	9	6	0	19
3231	9	7	0	19
3232	9	8	0	19
3233	9	9	0	19
3234	9	10	0	19
3235	9	11	1	19
3236	9	12	1	19
3237	9	13	1	19
3238	9	14	0	19
3239	9	15	0	19
3240	9	16	0	19
3241	9	17	0	19
3242	9	18	0	19
3243	9	19	0	19
3244	9	20	0	19
3245	9	21	2	19
3246	9	22	2	19
3247	9	23	2	19
3248	9	24	0	19
3249	9	25	2	19
3250	9	26	0	19
3251	9	27	0	19
3252	9	28	0	19
3253	3	1	0	19
3254	3	2	1	19
3255	3	3	0	19
3256	3	4	0	19
3257	3	5	1	19
3258	3	6	0	19
3259	3	7	0	19
3260	3	8	0	19
3261	3	9	2	19
3262	3	10	2	19
3263	3	11	2	19
3264	3	12	2	19
3265	3	13	2	19
3266	3	14	2	19
3267	3	15	0	19
3268	3	16	1	19
3269	3	17	0	19
3270	3	18	0	19
3271	3	19	0	19
3272	3	20	0	19
3273	3	21	0	19
3274	3	22	0	19
3275	3	23	0	19
3276	3	24	0	19
3277	3	25	0	19
3278	3	26	0	19
3279	3	27	0	19
3280	3	28	0	19
3281	2	1	0	19
3282	2	2	2	19
3283	2	3	0	19
3284	2	4	0	19
3285	2	5	1	19
3286	2	6	0	19
3287	2	7	0	19
3288	2	8	0	19
3289	2	9	0	19
3290	2	10	0	19
3291	2	11	2	19
3292	2	12	1	19
3293	2	13	1	19
3294	2	14	1	19
3295	2	15	0	19
3296	2	16	1	19
3297	2	17	2	19
3298	2	18	2	19
3299	2	19	2	19
3300	2	20	1	19
3301	2	21	1	19
3302	2	22	0	19
3303	2	23	0	19
3304	2	24	1	19
3305	2	25	1	19
3306	2	26	2	19
3307	2	27	1	19
3308	2	28	0	19
3310	1	2	0	19
3311	1	3	0	19
3312	1	4	0	19
3313	1	5	0	19
3314	1	6	0	19
3315	1	7	0	19
3316	1	8	0	19
3317	1	9	0	19
3318	1	10	0	19
3319	1	11	0	19
3320	1	12	0	19
3321	1	13	0	19
3322	1	14	0	19
3323	1	15	0	19
3324	1	16	0	19
3325	1	17	0	19
3326	1	18	0	19
3327	1	19	0	19
3328	1	20	0	19
3329	1	21	0	19
3330	1	22	0	19
3331	1	23	0	19
3332	1	24	0	19
3333	1	25	0	19
3334	1	26	2	19
3335	1	27	1	19
3336	1	28	2	19
3337	6	1	2	19
3338	6	2	1	19
3339	6	3	0	19
3340	6	4	0	19
3341	6	5	0	19
3342	6	6	0	19
3343	6	7	0	19
3344	6	8	0	19
3345	6	9	0	19
3346	6	10	0	19
3347	6	11	1	19
3348	6	12	1	19
3349	6	13	0	19
3350	6	14	0	19
3351	6	15	0	19
3352	6	16	0	19
3353	6	17	0	19
3354	6	18	0	19
3355	6	19	0	19
3356	6	20	0	19
3357	6	21	0	19
3358	6	22	0	19
3359	6	23	2	19
3360	6	24	1	19
3361	6	25	0	19
3362	6	26	2	19
3363	6	27	0	19
3364	6	28	0	19
3365	7	1	0	19
3366	7	2	0	19
3367	7	3	0	19
3368	7	4	0	19
3369	7	5	0	19
3370	7	6	0	19
3371	7	7	0	19
3372	7	8	0	19
3373	7	9	0	19
3374	7	10	0	19
3375	7	11	0	19
3376	7	12	0	19
3377	7	13	0	19
3378	7	14	0	19
3379	7	15	0	19
3380	7	16	0	19
3381	7	17	0	19
3382	7	18	0	19
3383	7	19	0	19
3384	7	20	0	19
3385	7	21	0	19
3386	7	22	0	19
3387	7	23	2	19
3388	7	24	2	19
3389	7	25	0	19
3390	7	26	0	19
3391	7	27	0	19
3392	7	28	0	19
3393	8	1	0	19
3394	8	2	0	19
3395	8	3	0	19
3396	8	4	0	19
3397	8	5	0	19
3398	8	6	0	19
3399	8	7	2	19
3400	8	8	0	19
3401	8	9	0	19
3402	8	10	0	19
3403	8	11	0	19
3404	8	12	1	19
3405	8	13	0	19
3406	8	14	0	19
3407	8	15	0	19
3408	8	16	2	19
3409	8	17	0	19
3410	8	18	0	19
3411	8	19	0	19
3412	8	20	0	19
3413	8	21	0	19
3414	8	22	0	19
3415	8	23	0	19
3416	8	24	0	19
3417	8	25	1	19
3418	8	26	0	19
3419	8	27	1	19
3420	8	28	0	19
3421	10	1	0	19
3422	10	2	1	19
3423	10	3	0	19
3424	10	4	0	19
3425	10	5	0	19
3426	10	6	0	19
3427	10	7	0	19
3428	10	8	0	19
3429	10	9	0	19
3430	10	10	0	19
3431	10	11	0	19
3432	10	12	0	19
3433	10	13	0	19
3434	10	14	0	19
3435	10	15	0	19
3436	10	16	0	19
3437	10	17	0	19
3438	10	18	0	19
3439	10	19	0	19
3440	10	20	0	19
3441	10	21	0	19
3442	10	22	0	19
3443	10	23	0	19
3444	10	24	0	19
3445	10	25	0	19
3446	10	26	2	19
3447	10	27	0	19
3448	10	28	1	19
3449	11	1	3	19
3450	11	2	3	19
3451	11	3	3	19
3452	11	4	3	19
3453	11	5	3	19
3454	11	6	3	19
3455	11	7	3	19
3456	11	8	3	19
3457	11	9	3	19
3458	11	10	3	19
3459	11	11	3	19
3460	11	12	3	19
3461	11	13	3	19
3462	11	14	3	19
3463	11	15	3	19
3464	11	16	3	19
3465	11	17	3	19
3466	11	18	3	19
3467	11	19	3	19
3468	11	20	3	19
3469	11	21	3	19
3470	11	22	3	19
3471	11	23	3	19
3472	11	24	3	19
3473	11	25	3	19
3474	11	26	3	19
3475	11	27	3	19
3476	11	28	3	19
3477	12	1	0	19
3478	12	2	0	19
3479	12	3	1	19
3480	12	4	2	19
3481	12	5	0	19
3482	12	6	2	19
3483	12	7	0	19
3484	12	8	2	19
3485	12	9	0	19
3486	12	10	0	19
3487	12	11	0	19
3488	12	12	0	19
3489	12	13	0	19
3490	12	14	0	19
3491	12	15	0	19
3492	12	16	0	19
3493	12	17	0	19
3494	12	18	0	19
3495	12	19	0	19
3496	12	20	0	19
3497	12	21	0	19
3498	12	22	0	19
3499	12	23	0	19
3500	12	24	0	19
3501	12	25	0	19
3502	12	26	0	19
3503	12	27	0	19
3504	12	28	0	19
3505	13	1	0	19
3506	13	2	0	19
3507	13	3	0	19
3508	13	4	0	19
3509	13	5	2	19
3510	13	6	0	19
3511	13	7	0	19
3512	13	8	0	19
3513	13	9	0	19
3514	13	10	0	19
3515	13	11	1	19
3516	13	12	0	19
3517	13	13	0	19
3518	13	14	0	19
3519	13	15	0	19
3520	13	16	0	19
3521	13	17	2	19
3522	13	18	0	19
3523	13	19	0	19
3524	13	20	0	19
3525	13	21	0	19
3526	13	22	0	19
3527	13	23	0	19
3528	13	24	0	19
3529	13	25	0	19
3530	13	26	0	19
3531	13	27	0	19
3532	13	28	0	19
3533	14	1	0	19
3534	14	2	0	19
3535	14	3	0	19
3536	14	4	0	19
3537	14	5	1	19
3538	14	6	1	19
3539	14	7	0	19
3540	14	8	0	19
3541	14	9	0	19
3542	14	10	1	19
3543	14	11	2	19
3544	14	12	0	19
3545	14	13	0	19
3546	14	14	0	19
3547	14	15	0	19
3548	14	16	0	19
3549	14	17	1	19
3550	14	18	0	19
3551	14	19	0	19
3552	14	20	0	19
3553	14	21	0	19
3554	14	22	0	19
3555	14	23	0	19
3556	14	24	0	19
3557	14	25	0	19
3558	14	26	0	19
3559	14	27	0	19
3560	14	28	0	19
3561	1	29	0	19
3562	1	30	0	19
3309	1	1	2	19
3563	4	1	1	20
3564	4	2	1	20
3565	4	3	0	20
3566	4	4	0	20
3567	4	5	0	20
3568	4	6	0	20
3569	4	7	0	20
3570	4	8	0	20
3571	4	9	0	20
3572	4	10	0	20
3573	4	11	2	20
3574	4	12	2	20
3575	4	13	2	20
3576	4	14	1	20
3577	4	15	0	20
3578	4	16	0	20
3579	4	17	0	20
3580	4	18	1	20
3581	4	19	2	20
3582	4	20	2	20
3583	4	21	2	20
3584	4	22	1	20
3585	4	23	0	20
3586	4	24	0	20
3587	4	25	1	20
3588	4	26	0	20
3589	4	27	0	20
3590	4	28	1	20
3591	5	1	0	20
3592	5	2	0	20
3593	5	3	0	20
3594	5	4	0	20
3595	5	5	0	20
3596	5	6	0	20
3597	5	7	1	20
3598	5	8	0	20
3599	5	9	0	20
3600	5	10	0	20
3601	5	11	1	20
3602	5	12	1	20
3603	5	13	1	20
3604	5	14	1	20
3605	5	15	0	20
3606	5	16	0	20
3607	5	17	2	20
3608	5	18	2	20
3609	5	19	0	20
3610	5	20	0	20
3611	5	21	1	20
3612	5	22	2	20
3613	5	23	0	20
3614	5	24	0	20
3615	5	25	0	20
3616	5	26	0	20
3617	5	27	0	20
3618	5	28	0	20
3619	9	1	0	20
3620	9	2	0	20
3621	9	3	0	20
3622	9	4	0	20
3623	9	5	0	20
3624	9	6	0	20
3625	9	7	0	20
3626	9	8	0	20
3627	9	9	0	20
3628	9	10	0	20
3629	9	11	1	20
3630	9	12	1	20
3631	9	13	1	20
3632	9	14	0	20
3633	9	15	0	20
3634	9	16	0	20
3635	9	17	0	20
3636	9	18	0	20
3637	9	19	0	20
3638	9	20	0	20
3639	9	21	2	20
3640	9	22	2	20
3641	9	23	2	20
3642	9	24	0	20
3643	9	25	2	20
3644	9	26	0	20
3645	9	27	0	20
3646	9	28	0	20
3647	3	1	0	20
3648	3	2	1	20
3649	3	3	0	20
3650	3	4	0	20
3651	3	5	1	20
3652	3	6	0	20
3653	3	7	0	20
3654	3	8	0	20
3655	3	9	2	20
3656	3	10	2	20
3657	3	11	2	20
3658	3	12	2	20
3659	3	13	2	20
3660	3	14	2	20
3661	3	15	0	20
3662	3	16	1	20
3663	3	17	0	20
3664	3	18	0	20
3665	3	19	0	20
3666	3	20	0	20
3667	3	21	0	20
3668	3	22	0	20
3669	3	23	0	20
3670	3	24	0	20
3671	3	25	0	20
3672	3	26	0	20
3673	3	27	0	20
3674	3	28	0	20
3675	2	1	0	20
3676	2	2	2	20
3677	2	3	0	20
3678	2	4	0	20
3679	2	5	1	20
3680	2	6	0	20
3681	2	7	0	20
3682	2	8	0	20
3683	2	9	0	20
3684	2	10	0	20
3685	2	11	2	20
3686	2	12	1	20
3687	2	13	1	20
3688	2	14	1	20
3689	2	15	0	20
3690	2	16	1	20
3691	2	17	2	20
3692	2	18	2	20
3693	2	19	2	20
3694	2	20	1	20
3695	2	21	1	20
3696	2	22	0	20
3697	2	23	0	20
3698	2	24	1	20
3699	2	25	1	20
3700	2	26	2	20
3701	2	27	1	20
3702	2	28	0	20
3703	1	1	0	20
3704	1	2	0	20
3705	1	3	0	20
3706	1	4	0	20
3707	1	5	0	20
3708	1	6	0	20
3709	1	7	0	20
3710	1	8	0	20
3711	1	9	0	20
3712	1	10	0	20
3713	1	11	0	20
3714	1	12	0	20
3715	1	13	0	20
3716	1	14	0	20
3717	1	15	0	20
3718	1	16	0	20
3719	1	17	0	20
3720	1	18	0	20
3721	1	19	0	20
3722	1	20	0	20
3723	1	21	0	20
3724	1	22	0	20
3725	1	23	0	20
3726	1	24	0	20
3727	1	25	0	20
3728	1	26	2	20
3729	1	27	1	20
3730	1	28	2	20
3731	6	1	2	20
3732	6	2	1	20
3733	6	3	0	20
3734	6	4	0	20
3735	6	5	0	20
3736	6	6	0	20
3737	6	7	0	20
3738	6	8	0	20
3739	6	9	0	20
3740	6	10	0	20
3741	6	11	1	20
3742	6	12	1	20
3743	6	13	0	20
3744	6	14	0	20
3745	6	15	0	20
3746	6	16	0	20
3747	6	17	0	20
3748	6	18	0	20
3749	6	19	0	20
3750	6	20	0	20
3751	6	21	0	20
3752	6	22	0	20
3753	6	23	2	20
3754	6	24	1	20
3755	6	25	0	20
3756	6	26	2	20
3757	6	27	0	20
3758	6	28	0	20
3759	7	1	0	20
3760	7	2	0	20
3761	7	3	0	20
3762	7	4	0	20
3763	7	5	0	20
3764	7	6	0	20
3765	7	7	0	20
3766	7	8	0	20
3767	7	9	0	20
3768	7	10	0	20
3769	7	11	0	20
3770	7	12	0	20
3771	7	13	0	20
3772	7	14	0	20
3773	7	15	0	20
3774	7	16	0	20
3775	7	17	0	20
3776	7	18	0	20
3777	7	19	0	20
3778	7	20	0	20
3779	7	21	0	20
3780	7	22	0	20
3781	7	23	2	20
3782	7	24	2	20
3783	7	25	0	20
3784	7	26	0	20
3785	7	27	0	20
3786	7	28	0	20
3787	8	1	0	20
3788	8	2	0	20
3789	8	3	0	20
3790	8	4	0	20
3791	8	5	0	20
3792	8	6	0	20
3793	8	7	2	20
3794	8	8	0	20
3795	8	9	0	20
3796	8	10	0	20
3797	8	11	0	20
3798	8	12	1	20
3799	8	13	0	20
3800	8	14	0	20
3801	8	15	0	20
3802	8	16	2	20
3803	8	17	0	20
3804	8	18	0	20
3805	8	19	0	20
3806	8	20	0	20
3807	8	21	0	20
3808	8	22	0	20
3809	8	23	0	20
3810	8	24	0	20
3811	8	25	1	20
3812	8	26	0	20
3813	8	27	1	20
3814	8	28	0	20
3815	10	1	0	20
3816	10	2	1	20
3817	10	3	0	20
3818	10	4	0	20
3819	10	5	0	20
3820	10	6	0	20
3821	10	7	0	20
3822	10	8	0	20
3823	10	9	0	20
3824	10	10	0	20
3825	10	11	0	20
3826	10	12	0	20
3827	10	13	0	20
3828	10	14	0	20
3829	10	15	0	20
3830	10	16	0	20
3831	10	17	0	20
3832	10	18	0	20
3833	10	19	0	20
3834	10	20	0	20
3835	10	21	0	20
3836	10	22	0	20
3837	10	23	0	20
3838	10	24	0	20
3839	10	25	0	20
3840	10	26	2	20
3841	10	27	0	20
3842	10	28	1	20
3843	11	1	3	20
3844	11	2	3	20
3845	11	3	3	20
3846	11	4	3	20
3847	11	5	3	20
3848	11	6	3	20
3849	11	7	3	20
3850	11	8	3	20
3851	11	9	3	20
3852	11	10	3	20
3853	11	11	3	20
3854	11	12	3	20
3855	11	13	3	20
3856	11	14	3	20
3857	11	15	3	20
3858	11	16	3	20
3859	11	17	3	20
3860	11	18	3	20
3861	11	19	3	20
3862	11	20	3	20
3863	11	21	3	20
3864	11	22	3	20
3865	11	23	3	20
3866	11	24	3	20
3867	11	25	3	20
3868	11	26	3	20
3869	11	27	3	20
3870	11	28	3	20
3871	12	1	0	20
3872	12	2	0	20
3873	12	3	1	20
3874	12	4	2	20
3875	12	5	0	20
3876	12	6	2	20
3877	12	7	0	20
3878	12	8	2	20
3879	12	9	0	20
3880	12	10	0	20
3881	12	11	0	20
3882	12	12	0	20
3883	12	13	0	20
3884	12	14	0	20
3885	12	15	0	20
3886	12	16	0	20
3887	12	17	0	20
3888	12	18	0	20
3889	12	19	0	20
3890	12	20	0	20
3891	12	21	0	20
3892	12	22	0	20
3893	12	23	0	20
3894	12	24	0	20
3895	12	25	0	20
3896	12	26	0	20
3897	12	27	0	20
3898	12	28	0	20
3899	13	1	0	20
3900	13	2	0	20
3901	13	3	0	20
3902	13	4	0	20
3903	13	5	2	20
3904	13	6	0	20
3905	13	7	0	20
3906	13	8	0	20
3907	13	9	0	20
3908	13	10	0	20
3909	13	11	1	20
3910	13	12	0	20
3911	13	13	0	20
3912	13	14	0	20
3913	13	15	0	20
3914	13	16	0	20
3915	13	17	2	20
3916	13	18	0	20
3917	13	19	0	20
3918	13	20	0	20
3919	13	21	0	20
3920	13	22	0	20
3921	13	23	0	20
3922	13	24	0	20
3923	13	25	0	20
3924	13	26	0	20
3925	13	27	0	20
3926	13	28	0	20
3927	14	1	0	20
3928	14	2	0	20
3929	14	3	0	20
3930	14	4	0	20
3931	14	5	1	20
3932	14	6	1	20
3933	14	7	0	20
3934	14	8	0	20
3935	14	9	0	20
3936	14	10	1	20
3937	14	11	2	20
3938	14	12	0	20
3939	14	13	0	20
3940	14	14	0	20
3941	14	15	0	20
3942	14	16	0	20
3943	14	17	1	20
3944	14	18	0	20
3945	14	19	0	20
3946	14	20	0	20
3947	14	21	0	20
3948	14	22	0	20
3949	14	23	0	20
3950	14	24	0	20
3951	14	25	0	20
3952	14	26	0	20
3953	14	27	0	20
3954	14	28	0	20
\.


--
-- Data for Name: unknown_role_competency_matrix; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.unknown_role_competency_matrix (id, user_name, competency_id, role_competency_value, organization_id) FROM stdin;
1	test_dev_user_final	1	6	1
2	test_dev_user_final	4	6	1
3	test_dev_user_final	5	6	1
4	test_dev_user_final	6	6	1
5	test_dev_user_final	7	6	1
6	test_dev_user_final	8	3	1
7	test_dev_user_final	9	6	1
8	test_dev_user_final	10	3	1
9	test_dev_user_final	11	3	1
10	test_dev_user_final	12	3	1
11	test_dev_user_final	13	3	1
12	test_dev_user_final	14	6	1
13	test_dev_user_final	15	4	1
14	test_dev_user_final	16	3	1
15	test_dev_user_final	17	1	1
16	test_dev_user_final	18	6	1
17	phase1_temp_1761022046062_v7jottit1	4	4	15
18	phase1_temp_1761022046062_v7jottit1	14	4	15
19	phase1_temp_1761022046062_v7jottit1	17	2	15
20	phase1_temp_1761022046062_v7jottit1	13	2	15
21	phase1_temp_1761022046062_v7jottit1	10	2	15
22	phase1_temp_1761022046062_v7jottit1	7	4	15
23	phase1_temp_1761022046062_v7jottit1	9	4	15
24	phase1_temp_1761022046062_v7jottit1	1	4	15
25	phase1_temp_1761022046062_v7jottit1	5	4	15
26	phase1_temp_1761022046062_v7jottit1	18	4	15
27	phase1_temp_1761022046062_v7jottit1	16	4	15
28	phase1_temp_1761022046062_v7jottit1	15	2	15
29	phase1_temp_1761022046062_v7jottit1	6	4	15
30	phase1_temp_1761022046062_v7jottit1	12	2	15
31	phase1_temp_1761022046062_v7jottit1	11	2	15
32	phase1_temp_1761022046062_v7jottit1	8	2	15
33	phase1_temp_1761022051588_cv9cw1szj	4	4	15
34	phase1_temp_1761022051588_cv9cw1szj	14	2	15
35	phase1_temp_1761022051588_cv9cw1szj	17	2	15
36	phase1_temp_1761022051588_cv9cw1szj	13	2	15
37	phase1_temp_1761022051588_cv9cw1szj	10	4	15
38	phase1_temp_1761022051588_cv9cw1szj	7	4	15
39	phase1_temp_1761022051588_cv9cw1szj	9	4	15
40	phase1_temp_1761022051588_cv9cw1szj	1	4	15
41	phase1_temp_1761022051588_cv9cw1szj	5	4	15
42	phase1_temp_1761022051588_cv9cw1szj	18	4	15
43	phase1_temp_1761022051588_cv9cw1szj	16	2	15
44	phase1_temp_1761022051588_cv9cw1szj	15	2	15
45	phase1_temp_1761022051588_cv9cw1szj	6	2	15
46	phase1_temp_1761022051588_cv9cw1szj	12	4	15
47	phase1_temp_1761022051588_cv9cw1szj	11	4	15
48	phase1_temp_1761022051588_cv9cw1szj	8	4	15
49	test_pm_user	4	6	1
50	test_pm_user	14	6	1
51	test_pm_user	17	1	1
52	test_pm_user	13	3	1
53	test_pm_user	10	3	1
54	test_pm_user	7	6	1
55	test_pm_user	9	6	1
56	test_pm_user	1	6	1
57	test_pm_user	5	6	1
58	test_pm_user	18	6	1
59	test_pm_user	16	3	1
60	test_pm_user	15	3	1
61	test_pm_user	6	6	1
62	test_pm_user	12	4	1
63	test_pm_user	11	4	1
64	test_pm_user	8	3	1
65	phase1_temp_1761023242629_z1lje4wmy	4	4	15
66	phase1_temp_1761023242629_z1lje4wmy	14	4	15
67	phase1_temp_1761023242629_z1lje4wmy	17	2	15
68	phase1_temp_1761023242629_z1lje4wmy	13	2	15
69	phase1_temp_1761023242629_z1lje4wmy	10	2	15
70	phase1_temp_1761023242629_z1lje4wmy	7	4	15
71	phase1_temp_1761023242629_z1lje4wmy	9	4	15
72	phase1_temp_1761023242629_z1lje4wmy	1	4	15
73	phase1_temp_1761023242629_z1lje4wmy	5	4	15
74	phase1_temp_1761023242629_z1lje4wmy	18	4	15
75	phase1_temp_1761023242629_z1lje4wmy	16	4	15
76	phase1_temp_1761023242629_z1lje4wmy	15	2	15
77	phase1_temp_1761023242629_z1lje4wmy	6	4	15
78	phase1_temp_1761023242629_z1lje4wmy	12	2	15
79	phase1_temp_1761023242629_z1lje4wmy	11	2	15
80	phase1_temp_1761023242629_z1lje4wmy	8	2	15
81	phase1_temp_1761023558262_ktxyh5e7v	4	4	15
82	phase1_temp_1761023558262_ktxyh5e7v	14	4	15
83	phase1_temp_1761023558262_ktxyh5e7v	17	2	15
84	phase1_temp_1761023558262_ktxyh5e7v	13	2	15
85	phase1_temp_1761023558262_ktxyh5e7v	10	2	15
86	phase1_temp_1761023558262_ktxyh5e7v	7	4	15
87	phase1_temp_1761023558262_ktxyh5e7v	9	4	15
88	phase1_temp_1761023558262_ktxyh5e7v	1	4	15
89	phase1_temp_1761023558262_ktxyh5e7v	5	4	15
90	phase1_temp_1761023558262_ktxyh5e7v	18	4	15
91	phase1_temp_1761023558262_ktxyh5e7v	16	4	15
92	phase1_temp_1761023558262_ktxyh5e7v	15	2	15
93	phase1_temp_1761023558262_ktxyh5e7v	6	4	15
94	phase1_temp_1761023558262_ktxyh5e7v	12	2	15
95	phase1_temp_1761023558262_ktxyh5e7v	11	2	15
96	phase1_temp_1761023558262_ktxyh5e7v	8	2	15
97	phase1_temp_1761023785415_mly1fd5ro	4	4	15
98	phase1_temp_1761023785415_mly1fd5ro	14	4	15
99	phase1_temp_1761023785415_mly1fd5ro	17	2	15
100	phase1_temp_1761023785415_mly1fd5ro	13	2	15
101	phase1_temp_1761023785415_mly1fd5ro	10	2	15
102	phase1_temp_1761023785415_mly1fd5ro	7	4	15
103	phase1_temp_1761023785415_mly1fd5ro	9	4	15
104	phase1_temp_1761023785415_mly1fd5ro	1	4	15
105	phase1_temp_1761023785415_mly1fd5ro	5	4	15
106	phase1_temp_1761023785415_mly1fd5ro	18	4	15
107	phase1_temp_1761023785415_mly1fd5ro	16	4	15
108	phase1_temp_1761023785415_mly1fd5ro	15	2	15
109	phase1_temp_1761023785415_mly1fd5ro	6	4	15
110	phase1_temp_1761023785415_mly1fd5ro	12	2	15
111	phase1_temp_1761023785415_mly1fd5ro	11	2	15
112	phase1_temp_1761023785415_mly1fd5ro	8	2	15
113	phase1_temp_1761024051893_qzgu7tktl	4	4	15
114	phase1_temp_1761024051893_qzgu7tktl	14	4	15
115	phase1_temp_1761024051893_qzgu7tktl	17	2	15
116	phase1_temp_1761024051893_qzgu7tktl	13	2	15
117	phase1_temp_1761024051893_qzgu7tktl	10	2	15
118	phase1_temp_1761024051893_qzgu7tktl	7	4	15
119	phase1_temp_1761024051893_qzgu7tktl	9	4	15
120	phase1_temp_1761024051893_qzgu7tktl	1	4	15
121	phase1_temp_1761024051893_qzgu7tktl	5	4	15
122	phase1_temp_1761024051893_qzgu7tktl	18	4	15
123	phase1_temp_1761024051893_qzgu7tktl	16	4	15
124	phase1_temp_1761024051893_qzgu7tktl	15	2	15
125	phase1_temp_1761024051893_qzgu7tktl	6	4	15
126	phase1_temp_1761024051893_qzgu7tktl	12	2	15
127	phase1_temp_1761024051893_qzgu7tktl	11	2	15
128	phase1_temp_1761024051893_qzgu7tktl	8	2	15
129	phase1_temp_1761057021036_74cqxdcfq	4	6	16
130	phase1_temp_1761057021036_74cqxdcfq	14	6	16
131	phase1_temp_1761057021036_74cqxdcfq	17	1	16
132	phase1_temp_1761057021036_74cqxdcfq	13	3	16
133	phase1_temp_1761057021036_74cqxdcfq	10	3	16
134	phase1_temp_1761057021036_74cqxdcfq	7	6	16
135	phase1_temp_1761057021036_74cqxdcfq	9	6	16
136	phase1_temp_1761057021036_74cqxdcfq	1	6	16
137	phase1_temp_1761057021036_74cqxdcfq	5	6	16
138	phase1_temp_1761057021036_74cqxdcfq	18	6	16
139	phase1_temp_1761057021036_74cqxdcfq	16	3	16
140	phase1_temp_1761057021036_74cqxdcfq	15	4	16
141	phase1_temp_1761057021036_74cqxdcfq	6	6	16
142	phase1_temp_1761057021036_74cqxdcfq	12	3	16
143	phase1_temp_1761057021036_74cqxdcfq	11	3	16
144	phase1_temp_1761057021036_74cqxdcfq	8	3	16
145	phase1_temp_1761057030704_hbwtow498	4	6	16
146	phase1_temp_1761057030704_hbwtow498	14	6	16
147	phase1_temp_1761057030704_hbwtow498	17	0	16
148	phase1_temp_1761057030704_hbwtow498	13	3	16
149	phase1_temp_1761057030704_hbwtow498	10	3	16
150	phase1_temp_1761057030704_hbwtow498	7	6	16
151	phase1_temp_1761057030704_hbwtow498	9	6	16
152	phase1_temp_1761057030704_hbwtow498	1	6	16
153	phase1_temp_1761057030704_hbwtow498	5	6	16
154	phase1_temp_1761057030704_hbwtow498	18	6	16
155	phase1_temp_1761057030704_hbwtow498	16	3	16
156	phase1_temp_1761057030704_hbwtow498	15	3	16
157	phase1_temp_1761057030704_hbwtow498	6	6	16
158	phase1_temp_1761057030704_hbwtow498	12	3	16
159	phase1_temp_1761057030704_hbwtow498	11	3	16
160	phase1_temp_1761057030704_hbwtow498	8	3	16
161	phase1_temp_1761057039476_g388bl1qc	4	2	16
162	phase1_temp_1761057039476_g388bl1qc	14	4	16
163	phase1_temp_1761057039476_g388bl1qc	17	2	16
164	phase1_temp_1761057039476_g388bl1qc	13	2	16
165	phase1_temp_1761057039476_g388bl1qc	10	4	16
166	phase1_temp_1761057039476_g388bl1qc	7	2	16
167	phase1_temp_1761057039476_g388bl1qc	9	4	16
168	phase1_temp_1761057039476_g388bl1qc	1	2	16
169	phase1_temp_1761057039476_g388bl1qc	5	2	16
170	phase1_temp_1761057039476_g388bl1qc	18	4	16
171	phase1_temp_1761057039476_g388bl1qc	16	4	16
172	phase1_temp_1761057039476_g388bl1qc	15	4	16
173	phase1_temp_1761057039476_g388bl1qc	6	2	16
174	phase1_temp_1761057039476_g388bl1qc	12	2	16
175	phase1_temp_1761057039476_g388bl1qc	11	2	16
176	phase1_temp_1761057039476_g388bl1qc	8	2	16
177	phase1_temp_1761057050092_048hecu33	4	4	16
178	phase1_temp_1761057050092_048hecu33	14	2	16
179	phase1_temp_1761057050092_048hecu33	17	2	16
180	phase1_temp_1761057050092_048hecu33	13	0	16
181	phase1_temp_1761057050092_048hecu33	10	4	16
182	phase1_temp_1761057050092_048hecu33	7	4	16
183	phase1_temp_1761057050092_048hecu33	9	4	16
184	phase1_temp_1761057050092_048hecu33	1	4	16
185	phase1_temp_1761057050092_048hecu33	5	4	16
186	phase1_temp_1761057050092_048hecu33	18	4	16
187	phase1_temp_1761057050092_048hecu33	16	2	16
188	phase1_temp_1761057050092_048hecu33	15	2	16
189	phase1_temp_1761057050092_048hecu33	6	2	16
190	phase1_temp_1761057050092_048hecu33	12	4	16
191	phase1_temp_1761057050092_048hecu33	11	4	16
192	phase1_temp_1761057050092_048hecu33	8	4	16
193	phase1_temp_1761057058677_i8goreoi3	4	4	16
194	phase1_temp_1761057058677_i8goreoi3	14	4	16
195	phase1_temp_1761057058677_i8goreoi3	17	2	16
196	phase1_temp_1761057058677_i8goreoi3	13	2	16
197	phase1_temp_1761057058677_i8goreoi3	10	2	16
198	phase1_temp_1761057058677_i8goreoi3	7	4	16
199	phase1_temp_1761057058677_i8goreoi3	9	4	16
200	phase1_temp_1761057058677_i8goreoi3	1	4	16
201	phase1_temp_1761057058677_i8goreoi3	5	4	16
202	phase1_temp_1761057058677_i8goreoi3	18	4	16
203	phase1_temp_1761057058677_i8goreoi3	16	4	16
204	phase1_temp_1761057058677_i8goreoi3	15	2	16
205	phase1_temp_1761057058677_i8goreoi3	6	4	16
206	phase1_temp_1761057058677_i8goreoi3	12	2	16
207	phase1_temp_1761057058677_i8goreoi3	11	2	16
208	phase1_temp_1761057058677_i8goreoi3	8	2	16
209	phase1_temp_1761058418802_i0r81j20u	4	6	16
210	phase1_temp_1761058418802_i0r81j20u	14	6	16
211	phase1_temp_1761058418802_i0r81j20u	17	1	16
212	phase1_temp_1761058418802_i0r81j20u	13	3	16
213	phase1_temp_1761058418802_i0r81j20u	10	3	16
214	phase1_temp_1761058418802_i0r81j20u	7	6	16
215	phase1_temp_1761058418802_i0r81j20u	9	6	16
216	phase1_temp_1761058418802_i0r81j20u	1	6	16
217	phase1_temp_1761058418802_i0r81j20u	5	6	16
218	phase1_temp_1761058418802_i0r81j20u	18	6	16
219	phase1_temp_1761058418802_i0r81j20u	16	3	16
220	phase1_temp_1761058418802_i0r81j20u	15	4	16
221	phase1_temp_1761058418802_i0r81j20u	6	6	16
222	phase1_temp_1761058418802_i0r81j20u	12	3	16
223	phase1_temp_1761058418802_i0r81j20u	11	3	16
224	phase1_temp_1761058418802_i0r81j20u	8	3	16
225	phase1_temp_1761058427860_w3j0i6ysi	4	4	16
226	phase1_temp_1761058427860_w3j0i6ysi	14	4	16
227	phase1_temp_1761058427860_w3j0i6ysi	17	2	16
228	phase1_temp_1761058427860_w3j0i6ysi	13	2	16
229	phase1_temp_1761058427860_w3j0i6ysi	10	2	16
230	phase1_temp_1761058427860_w3j0i6ysi	7	4	16
231	phase1_temp_1761058427860_w3j0i6ysi	9	4	16
232	phase1_temp_1761058427860_w3j0i6ysi	1	4	16
233	phase1_temp_1761058427860_w3j0i6ysi	5	4	16
234	phase1_temp_1761058427860_w3j0i6ysi	18	4	16
235	phase1_temp_1761058427860_w3j0i6ysi	16	4	16
236	phase1_temp_1761058427860_w3j0i6ysi	15	2	16
237	phase1_temp_1761058427860_w3j0i6ysi	6	4	16
238	phase1_temp_1761058427860_w3j0i6ysi	12	2	16
239	phase1_temp_1761058427860_w3j0i6ysi	11	2	16
240	phase1_temp_1761058427860_w3j0i6ysi	8	2	16
241	phase1_temp_1761058437297_6rn30413r	4	6	16
242	phase1_temp_1761058437297_6rn30413r	14	6	16
243	phase1_temp_1761058437297_6rn30413r	17	0	16
244	phase1_temp_1761058437297_6rn30413r	13	3	16
245	phase1_temp_1761058437297_6rn30413r	10	3	16
246	phase1_temp_1761058437297_6rn30413r	7	6	16
247	phase1_temp_1761058437297_6rn30413r	9	6	16
248	phase1_temp_1761058437297_6rn30413r	1	6	16
249	phase1_temp_1761058437297_6rn30413r	5	6	16
250	phase1_temp_1761058437297_6rn30413r	18	6	16
251	phase1_temp_1761058437297_6rn30413r	16	3	16
252	phase1_temp_1761058437297_6rn30413r	15	3	16
253	phase1_temp_1761058437297_6rn30413r	6	6	16
254	phase1_temp_1761058437297_6rn30413r	12	3	16
255	phase1_temp_1761058437297_6rn30413r	11	3	16
256	phase1_temp_1761058437297_6rn30413r	8	3	16
257	phase1_temp_1761058445927_ro8e19kc7	4	2	16
258	phase1_temp_1761058445927_ro8e19kc7	14	4	16
259	phase1_temp_1761058445927_ro8e19kc7	17	2	16
260	phase1_temp_1761058445927_ro8e19kc7	13	2	16
261	phase1_temp_1761058445927_ro8e19kc7	10	4	16
262	phase1_temp_1761058445927_ro8e19kc7	7	2	16
263	phase1_temp_1761058445927_ro8e19kc7	9	4	16
264	phase1_temp_1761058445927_ro8e19kc7	1	2	16
265	phase1_temp_1761058445927_ro8e19kc7	5	2	16
266	phase1_temp_1761058445927_ro8e19kc7	18	4	16
267	phase1_temp_1761058445927_ro8e19kc7	16	4	16
268	phase1_temp_1761058445927_ro8e19kc7	15	4	16
269	phase1_temp_1761058445927_ro8e19kc7	6	2	16
270	phase1_temp_1761058445927_ro8e19kc7	12	2	16
271	phase1_temp_1761058445927_ro8e19kc7	11	2	16
272	phase1_temp_1761058445927_ro8e19kc7	8	2	16
273	phase1_temp_1761058857887_jq1gjvhfe	4	6	16
274	phase1_temp_1761058857887_jq1gjvhfe	14	6	16
275	phase1_temp_1761058857887_jq1gjvhfe	17	1	16
276	phase1_temp_1761058857887_jq1gjvhfe	13	3	16
277	phase1_temp_1761058857887_jq1gjvhfe	10	3	16
278	phase1_temp_1761058857887_jq1gjvhfe	7	6	16
279	phase1_temp_1761058857887_jq1gjvhfe	9	6	16
280	phase1_temp_1761058857887_jq1gjvhfe	1	6	16
281	phase1_temp_1761058857887_jq1gjvhfe	5	6	16
282	phase1_temp_1761058857887_jq1gjvhfe	18	6	16
283	phase1_temp_1761058857887_jq1gjvhfe	16	3	16
284	phase1_temp_1761058857887_jq1gjvhfe	15	4	16
285	phase1_temp_1761058857887_jq1gjvhfe	6	6	16
286	phase1_temp_1761058857887_jq1gjvhfe	12	3	16
287	phase1_temp_1761058857887_jq1gjvhfe	11	3	16
288	phase1_temp_1761058857887_jq1gjvhfe	8	3	16
289	phase1_temp_1761058868486_76ngtoc35	4	4	16
290	phase1_temp_1761058868486_76ngtoc35	14	4	16
291	phase1_temp_1761058868486_76ngtoc35	17	2	16
292	phase1_temp_1761058868486_76ngtoc35	13	2	16
293	phase1_temp_1761058868486_76ngtoc35	10	2	16
294	phase1_temp_1761058868486_76ngtoc35	7	4	16
295	phase1_temp_1761058868486_76ngtoc35	9	4	16
296	phase1_temp_1761058868486_76ngtoc35	1	4	16
297	phase1_temp_1761058868486_76ngtoc35	5	4	16
298	phase1_temp_1761058868486_76ngtoc35	18	4	16
299	phase1_temp_1761058868486_76ngtoc35	16	4	16
300	phase1_temp_1761058868486_76ngtoc35	15	2	16
301	phase1_temp_1761058868486_76ngtoc35	6	4	16
302	phase1_temp_1761058868486_76ngtoc35	12	2	16
303	phase1_temp_1761058868486_76ngtoc35	11	2	16
304	phase1_temp_1761058868486_76ngtoc35	8	2	16
305	phase1_temp_1761058880386_uewnxr99n	4	6	16
306	phase1_temp_1761058880386_uewnxr99n	14	6	16
307	phase1_temp_1761058880386_uewnxr99n	17	0	16
308	phase1_temp_1761058880386_uewnxr99n	13	3	16
309	phase1_temp_1761058880386_uewnxr99n	10	3	16
310	phase1_temp_1761058880386_uewnxr99n	7	6	16
311	phase1_temp_1761058880386_uewnxr99n	9	6	16
312	phase1_temp_1761058880386_uewnxr99n	1	6	16
313	phase1_temp_1761058880386_uewnxr99n	5	6	16
314	phase1_temp_1761058880386_uewnxr99n	18	6	16
315	phase1_temp_1761058880386_uewnxr99n	16	3	16
316	phase1_temp_1761058880386_uewnxr99n	15	3	16
317	phase1_temp_1761058880386_uewnxr99n	6	6	16
318	phase1_temp_1761058880386_uewnxr99n	12	3	16
319	phase1_temp_1761058880386_uewnxr99n	11	3	16
320	phase1_temp_1761058880386_uewnxr99n	8	3	16
321	phase1_temp_1761058892469_dkvv4jw2w	4	6	16
322	phase1_temp_1761058892469_dkvv4jw2w	14	6	16
323	phase1_temp_1761058892469_dkvv4jw2w	17	2	16
324	phase1_temp_1761058892469_dkvv4jw2w	13	3	16
325	phase1_temp_1761058892469_dkvv4jw2w	10	4	16
326	phase1_temp_1761058892469_dkvv4jw2w	7	6	16
327	phase1_temp_1761058892469_dkvv4jw2w	9	6	16
328	phase1_temp_1761058892469_dkvv4jw2w	1	6	16
329	phase1_temp_1761058892469_dkvv4jw2w	5	6	16
330	phase1_temp_1761058892469_dkvv4jw2w	18	6	16
331	phase1_temp_1761058892469_dkvv4jw2w	16	4	16
332	phase1_temp_1761058892469_dkvv4jw2w	15	4	16
333	phase1_temp_1761058892469_dkvv4jw2w	6	6	16
334	phase1_temp_1761058892469_dkvv4jw2w	12	4	16
335	phase1_temp_1761058892469_dkvv4jw2w	11	3	16
336	phase1_temp_1761058892469_dkvv4jw2w	8	3	16
337	phase1_temp_1761058904862_neaktu63o	4	4	16
338	phase1_temp_1761058904862_neaktu63o	14	2	16
339	phase1_temp_1761058904862_neaktu63o	17	2	16
340	phase1_temp_1761058904862_neaktu63o	13	2	16
341	phase1_temp_1761058904862_neaktu63o	10	4	16
342	phase1_temp_1761058904862_neaktu63o	7	4	16
343	phase1_temp_1761058904862_neaktu63o	9	4	16
344	phase1_temp_1761058904862_neaktu63o	1	4	16
345	phase1_temp_1761058904862_neaktu63o	5	4	16
346	phase1_temp_1761058904862_neaktu63o	18	4	16
347	phase1_temp_1761058904862_neaktu63o	16	2	16
348	phase1_temp_1761058904862_neaktu63o	15	2	16
349	phase1_temp_1761058904862_neaktu63o	6	2	16
350	phase1_temp_1761058904862_neaktu63o	12	4	16
351	phase1_temp_1761058904862_neaktu63o	11	4	16
352	phase1_temp_1761058904862_neaktu63o	8	4	16
353	phase1_temp_1761061461738_5nzjxk66a	4	6	16
354	phase1_temp_1761061461738_5nzjxk66a	14	6	16
355	phase1_temp_1761061461738_5nzjxk66a	17	1	16
356	phase1_temp_1761061461738_5nzjxk66a	13	3	16
357	phase1_temp_1761061461738_5nzjxk66a	10	3	16
358	phase1_temp_1761061461738_5nzjxk66a	7	6	16
359	phase1_temp_1761061461738_5nzjxk66a	9	6	16
360	phase1_temp_1761061461738_5nzjxk66a	1	6	16
361	phase1_temp_1761061461738_5nzjxk66a	5	6	16
362	phase1_temp_1761061461738_5nzjxk66a	18	6	16
363	phase1_temp_1761061461738_5nzjxk66a	16	3	16
364	phase1_temp_1761061461738_5nzjxk66a	15	4	16
365	phase1_temp_1761061461738_5nzjxk66a	6	6	16
366	phase1_temp_1761061461738_5nzjxk66a	12	3	16
367	phase1_temp_1761061461738_5nzjxk66a	11	3	16
368	phase1_temp_1761061461738_5nzjxk66a	8	3	16
369	phase1_temp_1761061469190_c1ndkxpzj	4	6	16
370	phase1_temp_1761061469190_c1ndkxpzj	14	6	16
371	phase1_temp_1761061469190_c1ndkxpzj	17	0	16
372	phase1_temp_1761061469190_c1ndkxpzj	13	3	16
373	phase1_temp_1761061469190_c1ndkxpzj	10	4	16
374	phase1_temp_1761061469190_c1ndkxpzj	7	6	16
375	phase1_temp_1761061469190_c1ndkxpzj	9	6	16
376	phase1_temp_1761061469190_c1ndkxpzj	1	6	16
377	phase1_temp_1761061469190_c1ndkxpzj	5	6	16
378	phase1_temp_1761061469190_c1ndkxpzj	18	6	16
379	phase1_temp_1761061469190_c1ndkxpzj	16	3	16
380	phase1_temp_1761061469190_c1ndkxpzj	15	3	16
381	phase1_temp_1761061469190_c1ndkxpzj	6	6	16
382	phase1_temp_1761061469190_c1ndkxpzj	12	3	16
383	phase1_temp_1761061469190_c1ndkxpzj	11	3	16
384	phase1_temp_1761061469190_c1ndkxpzj	8	3	16
385	phase1_temp_1761061475576_eus6x8un3	4	2	16
386	phase1_temp_1761061475576_eus6x8un3	14	4	16
387	phase1_temp_1761061475576_eus6x8un3	17	2	16
388	phase1_temp_1761061475576_eus6x8un3	13	2	16
389	phase1_temp_1761061475576_eus6x8un3	10	4	16
390	phase1_temp_1761061475576_eus6x8un3	7	2	16
391	phase1_temp_1761061475576_eus6x8un3	9	4	16
392	phase1_temp_1761061475576_eus6x8un3	1	2	16
393	phase1_temp_1761061475576_eus6x8un3	5	2	16
394	phase1_temp_1761061475576_eus6x8un3	18	4	16
395	phase1_temp_1761061475576_eus6x8un3	16	4	16
396	phase1_temp_1761061475576_eus6x8un3	15	4	16
397	phase1_temp_1761061475576_eus6x8un3	6	2	16
398	phase1_temp_1761061475576_eus6x8un3	12	2	16
399	phase1_temp_1761061475576_eus6x8un3	11	2	16
400	phase1_temp_1761061475576_eus6x8un3	8	2	16
401	phase1_temp_1761061483959_7qkd7249m	4	4	16
402	phase1_temp_1761061483959_7qkd7249m	14	2	16
403	phase1_temp_1761061483959_7qkd7249m	17	2	16
404	phase1_temp_1761061483959_7qkd7249m	13	2	16
405	phase1_temp_1761061483959_7qkd7249m	10	4	16
406	phase1_temp_1761061483959_7qkd7249m	7	4	16
407	phase1_temp_1761061483959_7qkd7249m	9	4	16
408	phase1_temp_1761061483959_7qkd7249m	1	4	16
409	phase1_temp_1761061483959_7qkd7249m	5	4	16
410	phase1_temp_1761061483959_7qkd7249m	18	4	16
411	phase1_temp_1761061483959_7qkd7249m	16	2	16
412	phase1_temp_1761061483959_7qkd7249m	15	2	16
413	phase1_temp_1761061483959_7qkd7249m	6	2	16
414	phase1_temp_1761061483959_7qkd7249m	12	4	16
415	phase1_temp_1761061483959_7qkd7249m	11	4	16
416	phase1_temp_1761061483959_7qkd7249m	8	4	16
417	phase1_temp_1761061489973_pa2zogxxg	4	4	16
418	phase1_temp_1761061489973_pa2zogxxg	14	4	16
419	phase1_temp_1761061489973_pa2zogxxg	17	2	16
420	phase1_temp_1761061489973_pa2zogxxg	13	2	16
421	phase1_temp_1761061489973_pa2zogxxg	10	2	16
422	phase1_temp_1761061489973_pa2zogxxg	7	4	16
423	phase1_temp_1761061489973_pa2zogxxg	9	4	16
424	phase1_temp_1761061489973_pa2zogxxg	1	4	16
425	phase1_temp_1761061489973_pa2zogxxg	5	4	16
426	phase1_temp_1761061489973_pa2zogxxg	18	4	16
427	phase1_temp_1761061489973_pa2zogxxg	16	4	16
428	phase1_temp_1761061489973_pa2zogxxg	15	2	16
429	phase1_temp_1761061489973_pa2zogxxg	6	4	16
430	phase1_temp_1761061489973_pa2zogxxg	12	2	16
431	phase1_temp_1761061489973_pa2zogxxg	11	2	16
432	phase1_temp_1761061489973_pa2zogxxg	8	2	16
433	phase1_temp_1761062683560_lefw4cz6n	4	6	16
434	phase1_temp_1761062683560_lefw4cz6n	14	6	16
435	phase1_temp_1761062683560_lefw4cz6n	17	0	16
436	phase1_temp_1761062683560_lefw4cz6n	13	3	16
437	phase1_temp_1761062683560_lefw4cz6n	10	3	16
438	phase1_temp_1761062683560_lefw4cz6n	7	6	16
439	phase1_temp_1761062683560_lefw4cz6n	9	6	16
440	phase1_temp_1761062683560_lefw4cz6n	1	6	16
441	phase1_temp_1761062683560_lefw4cz6n	5	6	16
442	phase1_temp_1761062683560_lefw4cz6n	18	6	16
443	phase1_temp_1761062683560_lefw4cz6n	16	3	16
444	phase1_temp_1761062683560_lefw4cz6n	15	4	16
445	phase1_temp_1761062683560_lefw4cz6n	6	6	16
446	phase1_temp_1761062683560_lefw4cz6n	12	3	16
447	phase1_temp_1761062683560_lefw4cz6n	11	3	16
448	phase1_temp_1761062683560_lefw4cz6n	8	3	16
449	phase1_temp_1761062690705_zo4swt982	4	6	16
450	phase1_temp_1761062690705_zo4swt982	14	6	16
451	phase1_temp_1761062690705_zo4swt982	17	0	16
452	phase1_temp_1761062690705_zo4swt982	13	3	16
453	phase1_temp_1761062690705_zo4swt982	10	4	16
454	phase1_temp_1761062690705_zo4swt982	7	6	16
455	phase1_temp_1761062690705_zo4swt982	9	6	16
456	phase1_temp_1761062690705_zo4swt982	1	6	16
457	phase1_temp_1761062690705_zo4swt982	5	6	16
458	phase1_temp_1761062690705_zo4swt982	18	6	16
459	phase1_temp_1761062690705_zo4swt982	16	3	16
460	phase1_temp_1761062690705_zo4swt982	15	3	16
461	phase1_temp_1761062690705_zo4swt982	6	6	16
462	phase1_temp_1761062690705_zo4swt982	12	3	16
463	phase1_temp_1761062690705_zo4swt982	11	3	16
464	phase1_temp_1761062690705_zo4swt982	8	3	16
465	phase1_temp_1761062699334_gvxbn8cbb	4	2	16
466	phase1_temp_1761062699334_gvxbn8cbb	14	4	16
467	phase1_temp_1761062699334_gvxbn8cbb	17	2	16
468	phase1_temp_1761062699334_gvxbn8cbb	13	2	16
469	phase1_temp_1761062699334_gvxbn8cbb	10	4	16
470	phase1_temp_1761062699334_gvxbn8cbb	7	2	16
471	phase1_temp_1761062699334_gvxbn8cbb	9	4	16
472	phase1_temp_1761062699334_gvxbn8cbb	1	2	16
473	phase1_temp_1761062699334_gvxbn8cbb	5	2	16
474	phase1_temp_1761062699334_gvxbn8cbb	18	4	16
475	phase1_temp_1761062699334_gvxbn8cbb	16	4	16
476	phase1_temp_1761062699334_gvxbn8cbb	15	4	16
477	phase1_temp_1761062699334_gvxbn8cbb	6	2	16
478	phase1_temp_1761062699334_gvxbn8cbb	12	2	16
479	phase1_temp_1761062699334_gvxbn8cbb	11	2	16
480	phase1_temp_1761062699334_gvxbn8cbb	8	2	16
481	phase1_temp_1761062706216_f6ivgf8gv	4	4	16
482	phase1_temp_1761062706216_f6ivgf8gv	14	2	16
483	phase1_temp_1761062706216_f6ivgf8gv	17	2	16
484	phase1_temp_1761062706216_f6ivgf8gv	13	0	16
485	phase1_temp_1761062706216_f6ivgf8gv	10	4	16
486	phase1_temp_1761062706216_f6ivgf8gv	7	4	16
487	phase1_temp_1761062706216_f6ivgf8gv	9	4	16
488	phase1_temp_1761062706216_f6ivgf8gv	1	4	16
489	phase1_temp_1761062706216_f6ivgf8gv	5	4	16
490	phase1_temp_1761062706216_f6ivgf8gv	18	4	16
491	phase1_temp_1761062706216_f6ivgf8gv	16	2	16
492	phase1_temp_1761062706216_f6ivgf8gv	15	2	16
493	phase1_temp_1761062706216_f6ivgf8gv	6	2	16
494	phase1_temp_1761062706216_f6ivgf8gv	12	4	16
495	phase1_temp_1761062706216_f6ivgf8gv	11	4	16
496	phase1_temp_1761062706216_f6ivgf8gv	8	4	16
497	phase1_temp_1761062715043_q55x2575a	4	4	16
498	phase1_temp_1761062715043_q55x2575a	14	4	16
499	phase1_temp_1761062715043_q55x2575a	17	1	16
500	phase1_temp_1761062715043_q55x2575a	13	2	16
501	phase1_temp_1761062715043_q55x2575a	10	2	16
502	phase1_temp_1761062715043_q55x2575a	7	4	16
503	phase1_temp_1761062715043_q55x2575a	9	4	16
504	phase1_temp_1761062715043_q55x2575a	1	4	16
505	phase1_temp_1761062715043_q55x2575a	5	4	16
506	phase1_temp_1761062715043_q55x2575a	18	4	16
507	phase1_temp_1761062715043_q55x2575a	16	2	16
508	phase1_temp_1761062715043_q55x2575a	15	2	16
509	phase1_temp_1761062715043_q55x2575a	6	4	16
510	phase1_temp_1761062715043_q55x2575a	12	2	16
511	phase1_temp_1761062715043_q55x2575a	11	2	16
512	phase1_temp_1761062715043_q55x2575a	8	2	16
513	phase1_temp_1761063409422_4to8nfz47	4	4	16
514	phase1_temp_1761063409422_4to8nfz47	14	4	16
515	phase1_temp_1761063409422_4to8nfz47	17	2	16
516	phase1_temp_1761063409422_4to8nfz47	13	2	16
517	phase1_temp_1761063409422_4to8nfz47	10	2	16
518	phase1_temp_1761063409422_4to8nfz47	7	4	16
519	phase1_temp_1761063409422_4to8nfz47	9	4	16
520	phase1_temp_1761063409422_4to8nfz47	1	4	16
521	phase1_temp_1761063409422_4to8nfz47	5	4	16
522	phase1_temp_1761063409422_4to8nfz47	18	4	16
523	phase1_temp_1761063409422_4to8nfz47	16	4	16
524	phase1_temp_1761063409422_4to8nfz47	15	2	16
525	phase1_temp_1761063409422_4to8nfz47	6	4	16
526	phase1_temp_1761063409422_4to8nfz47	12	2	16
527	phase1_temp_1761063409422_4to8nfz47	11	2	16
528	phase1_temp_1761063409422_4to8nfz47	8	2	16
529	phase1_temp_1761063416296_9vtaktfao	4	4	16
530	phase1_temp_1761063416296_9vtaktfao	14	2	16
531	phase1_temp_1761063416296_9vtaktfao	17	2	16
532	phase1_temp_1761063416296_9vtaktfao	13	0	16
533	phase1_temp_1761063416296_9vtaktfao	10	4	16
534	phase1_temp_1761063416296_9vtaktfao	7	4	16
535	phase1_temp_1761063416296_9vtaktfao	9	4	16
536	phase1_temp_1761063416296_9vtaktfao	1	4	16
537	phase1_temp_1761063416296_9vtaktfao	5	4	16
538	phase1_temp_1761063416296_9vtaktfao	18	4	16
539	phase1_temp_1761063416296_9vtaktfao	16	2	16
540	phase1_temp_1761063416296_9vtaktfao	15	2	16
541	phase1_temp_1761063416296_9vtaktfao	6	2	16
542	phase1_temp_1761063416296_9vtaktfao	12	4	16
543	phase1_temp_1761063416296_9vtaktfao	11	4	16
544	phase1_temp_1761063416296_9vtaktfao	8	4	16
545	phase1_temp_1761063421806_leanyldrm	4	2	16
546	phase1_temp_1761063421806_leanyldrm	14	4	16
547	phase1_temp_1761063421806_leanyldrm	17	2	16
548	phase1_temp_1761063421806_leanyldrm	13	2	16
549	phase1_temp_1761063421806_leanyldrm	10	4	16
550	phase1_temp_1761063421806_leanyldrm	7	2	16
551	phase1_temp_1761063421806_leanyldrm	9	4	16
552	phase1_temp_1761063421806_leanyldrm	1	2	16
553	phase1_temp_1761063421806_leanyldrm	5	2	16
554	phase1_temp_1761063421806_leanyldrm	18	4	16
555	phase1_temp_1761063421806_leanyldrm	16	4	16
556	phase1_temp_1761063421806_leanyldrm	15	4	16
557	phase1_temp_1761063421806_leanyldrm	6	2	16
558	phase1_temp_1761063421806_leanyldrm	12	2	16
559	phase1_temp_1761063421806_leanyldrm	11	2	16
560	phase1_temp_1761063421806_leanyldrm	8	2	16
561	phase1_temp_1761063428009_9w44gmbtu	1	6	16
562	phase1_temp_1761063428009_9w44gmbtu	4	6	16
563	phase1_temp_1761063428009_9w44gmbtu	5	6	16
564	phase1_temp_1761063428009_9w44gmbtu	6	6	16
565	phase1_temp_1761063428009_9w44gmbtu	7	6	16
566	phase1_temp_1761063428009_9w44gmbtu	8	3	16
567	phase1_temp_1761063428009_9w44gmbtu	9	6	16
568	phase1_temp_1761063428009_9w44gmbtu	10	4	16
569	phase1_temp_1761063428009_9w44gmbtu	11	3	16
570	phase1_temp_1761063428009_9w44gmbtu	12	3	16
571	phase1_temp_1761063428009_9w44gmbtu	13	3	16
572	phase1_temp_1761063428009_9w44gmbtu	14	6	16
573	phase1_temp_1761063428009_9w44gmbtu	15	4	16
574	phase1_temp_1761063428009_9w44gmbtu	16	3	16
575	phase1_temp_1761063428009_9w44gmbtu	17	0	16
576	phase1_temp_1761063428009_9w44gmbtu	18	6	16
577	phase1_temp_1761063435278_hp7acer76	1	6	16
578	phase1_temp_1761063435278_hp7acer76	4	6	16
579	phase1_temp_1761063435278_hp7acer76	5	6	16
580	phase1_temp_1761063435278_hp7acer76	6	6	16
581	phase1_temp_1761063435278_hp7acer76	7	6	16
582	phase1_temp_1761063435278_hp7acer76	8	3	16
583	phase1_temp_1761063435278_hp7acer76	9	6	16
584	phase1_temp_1761063435278_hp7acer76	10	3	16
585	phase1_temp_1761063435278_hp7acer76	11	3	16
586	phase1_temp_1761063435278_hp7acer76	12	3	16
587	phase1_temp_1761063435278_hp7acer76	13	3	16
588	phase1_temp_1761063435278_hp7acer76	14	6	16
589	phase1_temp_1761063435278_hp7acer76	15	4	16
590	phase1_temp_1761063435278_hp7acer76	16	3	16
591	phase1_temp_1761063435278_hp7acer76	17	0	16
592	phase1_temp_1761063435278_hp7acer76	18	6	16
593	phase1_temp_1761064141578_pup8hlew7	4	6	16
594	phase1_temp_1761064141578_pup8hlew7	14	6	16
595	phase1_temp_1761064141578_pup8hlew7	17	0	16
596	phase1_temp_1761064141578_pup8hlew7	13	3	16
597	phase1_temp_1761064141578_pup8hlew7	10	3	16
598	phase1_temp_1761064141578_pup8hlew7	7	6	16
599	phase1_temp_1761064141578_pup8hlew7	9	6	16
600	phase1_temp_1761064141578_pup8hlew7	1	6	16
601	phase1_temp_1761064141578_pup8hlew7	5	6	16
602	phase1_temp_1761064141578_pup8hlew7	18	6	16
603	phase1_temp_1761064141578_pup8hlew7	16	3	16
604	phase1_temp_1761064141578_pup8hlew7	15	4	16
605	phase1_temp_1761064141578_pup8hlew7	6	6	16
606	phase1_temp_1761064141578_pup8hlew7	12	3	16
607	phase1_temp_1761064141578_pup8hlew7	11	3	16
608	phase1_temp_1761064141578_pup8hlew7	8	3	16
609	phase1_temp_1761064149514_9taacpaas	4	6	16
610	phase1_temp_1761064149514_9taacpaas	14	6	16
611	phase1_temp_1761064149514_9taacpaas	17	0	16
612	phase1_temp_1761064149514_9taacpaas	13	3	16
613	phase1_temp_1761064149514_9taacpaas	10	3	16
614	phase1_temp_1761064149514_9taacpaas	7	6	16
615	phase1_temp_1761064149514_9taacpaas	9	6	16
616	phase1_temp_1761064149514_9taacpaas	1	6	16
617	phase1_temp_1761064149514_9taacpaas	5	6	16
618	phase1_temp_1761064149514_9taacpaas	18	6	16
619	phase1_temp_1761064149514_9taacpaas	16	3	16
620	phase1_temp_1761064149514_9taacpaas	15	3	16
621	phase1_temp_1761064149514_9taacpaas	6	6	16
622	phase1_temp_1761064149514_9taacpaas	12	3	16
623	phase1_temp_1761064149514_9taacpaas	11	3	16
624	phase1_temp_1761064149514_9taacpaas	8	3	16
625	phase1_temp_1761064157722_qm1j25eg0	4	6	16
626	phase1_temp_1761064157722_qm1j25eg0	14	6	16
627	phase1_temp_1761064157722_qm1j25eg0	17	2	16
628	phase1_temp_1761064157722_qm1j25eg0	13	3	16
629	phase1_temp_1761064157722_qm1j25eg0	10	4	16
630	phase1_temp_1761064157722_qm1j25eg0	7	6	16
631	phase1_temp_1761064157722_qm1j25eg0	9	6	16
632	phase1_temp_1761064157722_qm1j25eg0	1	6	16
633	phase1_temp_1761064157722_qm1j25eg0	5	6	16
634	phase1_temp_1761064157722_qm1j25eg0	18	6	16
635	phase1_temp_1761064157722_qm1j25eg0	16	4	16
636	phase1_temp_1761064157722_qm1j25eg0	15	4	16
637	phase1_temp_1761064157722_qm1j25eg0	6	6	16
638	phase1_temp_1761064157722_qm1j25eg0	12	3	16
639	phase1_temp_1761064157722_qm1j25eg0	11	3	16
640	phase1_temp_1761064157722_qm1j25eg0	8	3	16
641	phase1_temp_1761064164058_flphdqg5d	4	4	16
642	phase1_temp_1761064164058_flphdqg5d	14	2	16
643	phase1_temp_1761064164058_flphdqg5d	17	2	16
644	phase1_temp_1761064164058_flphdqg5d	13	0	16
645	phase1_temp_1761064164058_flphdqg5d	10	4	16
646	phase1_temp_1761064164058_flphdqg5d	7	4	16
647	phase1_temp_1761064164058_flphdqg5d	9	4	16
648	phase1_temp_1761064164058_flphdqg5d	1	4	16
649	phase1_temp_1761064164058_flphdqg5d	5	4	16
650	phase1_temp_1761064164058_flphdqg5d	18	4	16
651	phase1_temp_1761064164058_flphdqg5d	16	2	16
652	phase1_temp_1761064164058_flphdqg5d	15	2	16
653	phase1_temp_1761064164058_flphdqg5d	6	2	16
654	phase1_temp_1761064164058_flphdqg5d	12	4	16
655	phase1_temp_1761064164058_flphdqg5d	11	4	16
656	phase1_temp_1761064164058_flphdqg5d	8	4	16
657	phase1_temp_1761064170989_4jumw966c	1	6	16
658	phase1_temp_1761064170989_4jumw966c	4	6	16
659	phase1_temp_1761064170989_4jumw966c	5	6	16
660	phase1_temp_1761064170989_4jumw966c	6	6	16
661	phase1_temp_1761064170989_4jumw966c	7	6	16
662	phase1_temp_1761064170989_4jumw966c	8	3	16
663	phase1_temp_1761064170989_4jumw966c	9	6	16
664	phase1_temp_1761064170989_4jumw966c	10	3	16
665	phase1_temp_1761064170989_4jumw966c	11	3	16
666	phase1_temp_1761064170989_4jumw966c	12	3	16
667	phase1_temp_1761064170989_4jumw966c	13	3	16
668	phase1_temp_1761064170989_4jumw966c	14	6	16
669	phase1_temp_1761064170989_4jumw966c	15	3	16
670	phase1_temp_1761064170989_4jumw966c	16	4	16
671	phase1_temp_1761064170989_4jumw966c	17	2	16
672	phase1_temp_1761064170989_4jumw966c	18	6	16
673	phase1_temp_1761064575744_haxprvrhs	1	6	16
674	phase1_temp_1761064575744_haxprvrhs	4	6	16
675	phase1_temp_1761064575744_haxprvrhs	5	6	16
676	phase1_temp_1761064575744_haxprvrhs	6	6	16
677	phase1_temp_1761064575744_haxprvrhs	7	6	16
678	phase1_temp_1761064575744_haxprvrhs	8	3	16
679	phase1_temp_1761064575744_haxprvrhs	9	6	16
680	phase1_temp_1761064575744_haxprvrhs	10	3	16
681	phase1_temp_1761064575744_haxprvrhs	11	3	16
682	phase1_temp_1761064575744_haxprvrhs	12	3	16
683	phase1_temp_1761064575744_haxprvrhs	13	3	16
684	phase1_temp_1761064575744_haxprvrhs	14	6	16
685	phase1_temp_1761064575744_haxprvrhs	15	4	16
686	phase1_temp_1761064575744_haxprvrhs	16	3	16
687	phase1_temp_1761064575744_haxprvrhs	17	1	16
688	phase1_temp_1761064575744_haxprvrhs	18	6	16
689	phase1_temp_1761064584793_myi9fjk1m	1	6	16
690	phase1_temp_1761064584793_myi9fjk1m	4	6	16
691	phase1_temp_1761064584793_myi9fjk1m	5	6	16
692	phase1_temp_1761064584793_myi9fjk1m	6	6	16
693	phase1_temp_1761064584793_myi9fjk1m	7	6	16
694	phase1_temp_1761064584793_myi9fjk1m	8	3	16
695	phase1_temp_1761064584793_myi9fjk1m	9	6	16
696	phase1_temp_1761064584793_myi9fjk1m	10	4	16
697	phase1_temp_1761064584793_myi9fjk1m	11	3	16
698	phase1_temp_1761064584793_myi9fjk1m	12	3	16
699	phase1_temp_1761064584793_myi9fjk1m	13	3	16
700	phase1_temp_1761064584793_myi9fjk1m	14	6	16
701	phase1_temp_1761064584793_myi9fjk1m	15	4	16
702	phase1_temp_1761064584793_myi9fjk1m	16	3	16
703	phase1_temp_1761064584793_myi9fjk1m	17	0	16
704	phase1_temp_1761064584793_myi9fjk1m	18	6	16
705	phase1_temp_1761064591945_9g10clo4b	1	2	16
706	phase1_temp_1761064591945_9g10clo4b	4	2	16
707	phase1_temp_1761064591945_9g10clo4b	5	2	16
708	phase1_temp_1761064591945_9g10clo4b	6	2	16
709	phase1_temp_1761064591945_9g10clo4b	7	2	16
710	phase1_temp_1761064591945_9g10clo4b	8	2	16
711	phase1_temp_1761064591945_9g10clo4b	9	4	16
712	phase1_temp_1761064591945_9g10clo4b	10	4	16
713	phase1_temp_1761064591945_9g10clo4b	11	2	16
714	phase1_temp_1761064591945_9g10clo4b	12	2	16
715	phase1_temp_1761064591945_9g10clo4b	13	2	16
716	phase1_temp_1761064591945_9g10clo4b	14	4	16
717	phase1_temp_1761064591945_9g10clo4b	15	4	16
718	phase1_temp_1761064591945_9g10clo4b	16	4	16
719	phase1_temp_1761064591945_9g10clo4b	17	2	16
720	phase1_temp_1761064591945_9g10clo4b	18	4	16
721	phase1_temp_1761064598792_q6hoc3xy5	1	4	16
722	phase1_temp_1761064598792_q6hoc3xy5	4	4	16
723	phase1_temp_1761064598792_q6hoc3xy5	5	4	16
724	phase1_temp_1761064598792_q6hoc3xy5	6	2	16
725	phase1_temp_1761064598792_q6hoc3xy5	7	4	16
726	phase1_temp_1761064598792_q6hoc3xy5	8	4	16
727	phase1_temp_1761064598792_q6hoc3xy5	9	4	16
728	phase1_temp_1761064598792_q6hoc3xy5	10	4	16
729	phase1_temp_1761064598792_q6hoc3xy5	11	4	16
730	phase1_temp_1761064598792_q6hoc3xy5	12	4	16
731	phase1_temp_1761064598792_q6hoc3xy5	13	0	16
732	phase1_temp_1761064598792_q6hoc3xy5	14	2	16
733	phase1_temp_1761064598792_q6hoc3xy5	15	2	16
734	phase1_temp_1761064598792_q6hoc3xy5	16	2	16
735	phase1_temp_1761064598792_q6hoc3xy5	17	2	16
736	phase1_temp_1761064598792_q6hoc3xy5	18	4	16
737	phase1_temp_1761064605689_1uv0ivb7x	1	4	16
738	phase1_temp_1761064605689_1uv0ivb7x	4	4	16
739	phase1_temp_1761064605689_1uv0ivb7x	5	4	16
740	phase1_temp_1761064605689_1uv0ivb7x	6	4	16
741	phase1_temp_1761064605689_1uv0ivb7x	7	4	16
742	phase1_temp_1761064605689_1uv0ivb7x	8	2	16
743	phase1_temp_1761064605689_1uv0ivb7x	9	4	16
744	phase1_temp_1761064605689_1uv0ivb7x	10	2	16
745	phase1_temp_1761064605689_1uv0ivb7x	11	2	16
746	phase1_temp_1761064605689_1uv0ivb7x	12	2	16
747	phase1_temp_1761064605689_1uv0ivb7x	13	2	16
748	phase1_temp_1761064605689_1uv0ivb7x	14	4	16
749	phase1_temp_1761064605689_1uv0ivb7x	15	2	16
750	phase1_temp_1761064605689_1uv0ivb7x	16	4	16
751	phase1_temp_1761064605689_1uv0ivb7x	17	2	16
752	phase1_temp_1761064605689_1uv0ivb7x	18	4	16
753	phase1_temp_1761065301703_juefozczj	1	6	16
754	phase1_temp_1761065301703_juefozczj	4	6	16
755	phase1_temp_1761065301703_juefozczj	5	6	16
756	phase1_temp_1761065301703_juefozczj	6	6	16
757	phase1_temp_1761065301703_juefozczj	7	6	16
758	phase1_temp_1761065301703_juefozczj	8	3	16
759	phase1_temp_1761065301703_juefozczj	9	6	16
760	phase1_temp_1761065301703_juefozczj	10	3	16
761	phase1_temp_1761065301703_juefozczj	11	3	16
762	phase1_temp_1761065301703_juefozczj	12	3	16
763	phase1_temp_1761065301703_juefozczj	13	3	16
764	phase1_temp_1761065301703_juefozczj	14	6	16
765	phase1_temp_1761065301703_juefozczj	15	4	16
766	phase1_temp_1761065301703_juefozczj	16	3	16
767	phase1_temp_1761065301703_juefozczj	17	0	16
768	phase1_temp_1761065301703_juefozczj	18	6	16
769	phase1_temp_1761065309731_e894p7q60	1	4	16
770	phase1_temp_1761065309731_e894p7q60	4	4	16
771	phase1_temp_1761065309731_e894p7q60	5	4	16
772	phase1_temp_1761065309731_e894p7q60	6	4	16
773	phase1_temp_1761065309731_e894p7q60	7	4	16
774	phase1_temp_1761065309731_e894p7q60	8	2	16
775	phase1_temp_1761065309731_e894p7q60	9	4	16
776	phase1_temp_1761065309731_e894p7q60	10	2	16
777	phase1_temp_1761065309731_e894p7q60	11	2	16
778	phase1_temp_1761065309731_e894p7q60	12	2	16
779	phase1_temp_1761065309731_e894p7q60	13	2	16
780	phase1_temp_1761065309731_e894p7q60	14	4	16
781	phase1_temp_1761065309731_e894p7q60	15	2	16
782	phase1_temp_1761065309731_e894p7q60	16	2	16
783	phase1_temp_1761065309731_e894p7q60	17	0	16
784	phase1_temp_1761065309731_e894p7q60	18	4	16
785	phase1_temp_1761065317016_8uuc897nx	1	2	16
786	phase1_temp_1761065317016_8uuc897nx	4	2	16
787	phase1_temp_1761065317016_8uuc897nx	5	2	16
788	phase1_temp_1761065317016_8uuc897nx	6	2	16
789	phase1_temp_1761065317016_8uuc897nx	7	2	16
790	phase1_temp_1761065317016_8uuc897nx	8	2	16
791	phase1_temp_1761065317016_8uuc897nx	9	4	16
792	phase1_temp_1761065317016_8uuc897nx	10	4	16
793	phase1_temp_1761065317016_8uuc897nx	11	2	16
794	phase1_temp_1761065317016_8uuc897nx	12	2	16
795	phase1_temp_1761065317016_8uuc897nx	13	2	16
796	phase1_temp_1761065317016_8uuc897nx	14	4	16
797	phase1_temp_1761065317016_8uuc897nx	15	4	16
798	phase1_temp_1761065317016_8uuc897nx	16	4	16
799	phase1_temp_1761065317016_8uuc897nx	17	2	16
800	phase1_temp_1761065317016_8uuc897nx	18	4	16
801	phase1_temp_1761065324347_qxttlquhj	1	4	16
802	phase1_temp_1761065324347_qxttlquhj	4	4	16
803	phase1_temp_1761065324347_qxttlquhj	5	4	16
804	phase1_temp_1761065324347_qxttlquhj	6	2	16
805	phase1_temp_1761065324347_qxttlquhj	7	4	16
806	phase1_temp_1761065324347_qxttlquhj	8	4	16
807	phase1_temp_1761065324347_qxttlquhj	9	4	16
808	phase1_temp_1761065324347_qxttlquhj	10	4	16
809	phase1_temp_1761065324347_qxttlquhj	11	4	16
810	phase1_temp_1761065324347_qxttlquhj	12	4	16
811	phase1_temp_1761065324347_qxttlquhj	13	2	16
812	phase1_temp_1761065324347_qxttlquhj	14	2	16
813	phase1_temp_1761065324347_qxttlquhj	15	2	16
814	phase1_temp_1761065324347_qxttlquhj	16	2	16
815	phase1_temp_1761065324347_qxttlquhj	17	2	16
816	phase1_temp_1761065324347_qxttlquhj	18	4	16
817	phase1_temp_1761065332763_yjl4oe5wm	1	4	16
818	phase1_temp_1761065332763_yjl4oe5wm	4	4	16
819	phase1_temp_1761065332763_yjl4oe5wm	5	4	16
820	phase1_temp_1761065332763_yjl4oe5wm	6	4	16
821	phase1_temp_1761065332763_yjl4oe5wm	7	4	16
822	phase1_temp_1761065332763_yjl4oe5wm	8	2	16
823	phase1_temp_1761065332763_yjl4oe5wm	9	4	16
824	phase1_temp_1761065332763_yjl4oe5wm	10	2	16
825	phase1_temp_1761065332763_yjl4oe5wm	11	2	16
826	phase1_temp_1761065332763_yjl4oe5wm	12	2	16
827	phase1_temp_1761065332763_yjl4oe5wm	13	2	16
828	phase1_temp_1761065332763_yjl4oe5wm	14	4	16
829	phase1_temp_1761065332763_yjl4oe5wm	15	2	16
830	phase1_temp_1761065332763_yjl4oe5wm	16	4	16
831	phase1_temp_1761065332763_yjl4oe5wm	17	2	16
832	phase1_temp_1761065332763_yjl4oe5wm	18	4	16
833	phase1_temp_1761065655490_w4f146y19	1	4	16
834	phase1_temp_1761065655490_w4f146y19	4	4	16
835	phase1_temp_1761065655490_w4f146y19	5	4	16
836	phase1_temp_1761065655490_w4f146y19	6	4	16
837	phase1_temp_1761065655490_w4f146y19	7	4	16
838	phase1_temp_1761065655490_w4f146y19	8	2	16
839	phase1_temp_1761065655490_w4f146y19	9	4	16
840	phase1_temp_1761065655490_w4f146y19	10	2	16
841	phase1_temp_1761065655490_w4f146y19	11	2	16
842	phase1_temp_1761065655490_w4f146y19	12	2	16
843	phase1_temp_1761065655490_w4f146y19	13	2	16
844	phase1_temp_1761065655490_w4f146y19	14	4	16
845	phase1_temp_1761065655490_w4f146y19	15	2	16
846	phase1_temp_1761065655490_w4f146y19	16	4	16
847	phase1_temp_1761065655490_w4f146y19	17	2	16
848	phase1_temp_1761065655490_w4f146y19	18	4	16
849	phase1_temp_1761066006974_nunzoua03	1	4	16
850	phase1_temp_1761066006974_nunzoua03	4	4	16
851	phase1_temp_1761066006974_nunzoua03	5	4	16
852	phase1_temp_1761066006974_nunzoua03	6	4	16
853	phase1_temp_1761066006974_nunzoua03	7	4	16
854	phase1_temp_1761066006974_nunzoua03	8	2	16
855	phase1_temp_1761066006974_nunzoua03	9	4	16
856	phase1_temp_1761066006974_nunzoua03	10	2	16
857	phase1_temp_1761066006974_nunzoua03	11	2	16
858	phase1_temp_1761066006974_nunzoua03	12	2	16
859	phase1_temp_1761066006974_nunzoua03	13	2	16
860	phase1_temp_1761066006974_nunzoua03	14	4	16
861	phase1_temp_1761066006974_nunzoua03	15	2	16
862	phase1_temp_1761066006974_nunzoua03	16	4	16
863	phase1_temp_1761066006974_nunzoua03	17	2	16
864	phase1_temp_1761066006974_nunzoua03	18	4	16
865	phase1_temp_1761066471322_og7qw5ixe	1	6	16
866	phase1_temp_1761066471322_og7qw5ixe	4	6	16
867	phase1_temp_1761066471322_og7qw5ixe	5	6	16
868	phase1_temp_1761066471322_og7qw5ixe	6	6	16
869	phase1_temp_1761066471322_og7qw5ixe	7	6	16
870	phase1_temp_1761066471322_og7qw5ixe	8	3	16
871	phase1_temp_1761066471322_og7qw5ixe	9	6	16
872	phase1_temp_1761066471322_og7qw5ixe	10	3	16
873	phase1_temp_1761066471322_og7qw5ixe	11	3	16
874	phase1_temp_1761066471322_og7qw5ixe	12	3	16
875	phase1_temp_1761066471322_og7qw5ixe	13	3	16
876	phase1_temp_1761066471322_og7qw5ixe	14	6	16
877	phase1_temp_1761066471322_og7qw5ixe	15	4	16
878	phase1_temp_1761066471322_og7qw5ixe	16	3	16
879	phase1_temp_1761066471322_og7qw5ixe	17	0	16
880	phase1_temp_1761066471322_og7qw5ixe	18	6	16
881	phase1_temp_1761066480657_nm72hejhf	1	6	16
882	phase1_temp_1761066480657_nm72hejhf	4	6	16
883	phase1_temp_1761066480657_nm72hejhf	5	6	16
884	phase1_temp_1761066480657_nm72hejhf	6	6	16
885	phase1_temp_1761066480657_nm72hejhf	7	6	16
886	phase1_temp_1761066480657_nm72hejhf	8	3	16
887	phase1_temp_1761066480657_nm72hejhf	9	6	16
888	phase1_temp_1761066480657_nm72hejhf	10	3	16
889	phase1_temp_1761066480657_nm72hejhf	11	3	16
890	phase1_temp_1761066480657_nm72hejhf	12	3	16
891	phase1_temp_1761066480657_nm72hejhf	13	3	16
892	phase1_temp_1761066480657_nm72hejhf	14	6	16
893	phase1_temp_1761066480657_nm72hejhf	15	3	16
894	phase1_temp_1761066480657_nm72hejhf	16	3	16
895	phase1_temp_1761066480657_nm72hejhf	17	0	16
896	phase1_temp_1761066480657_nm72hejhf	18	6	16
897	phase1_temp_1761066488385_h3r2r3fef	1	6	16
898	phase1_temp_1761066488385_h3r2r3fef	4	6	16
899	phase1_temp_1761066488385_h3r2r3fef	5	6	16
900	phase1_temp_1761066488385_h3r2r3fef	6	6	16
901	phase1_temp_1761066488385_h3r2r3fef	7	6	16
902	phase1_temp_1761066488385_h3r2r3fef	8	3	16
903	phase1_temp_1761066488385_h3r2r3fef	9	6	16
904	phase1_temp_1761066488385_h3r2r3fef	10	4	16
905	phase1_temp_1761066488385_h3r2r3fef	11	3	16
906	phase1_temp_1761066488385_h3r2r3fef	12	4	16
907	phase1_temp_1761066488385_h3r2r3fef	13	3	16
908	phase1_temp_1761066488385_h3r2r3fef	14	6	16
909	phase1_temp_1761066488385_h3r2r3fef	15	4	16
910	phase1_temp_1761066488385_h3r2r3fef	16	4	16
911	phase1_temp_1761066488385_h3r2r3fef	17	2	16
912	phase1_temp_1761066488385_h3r2r3fef	18	6	16
913	phase1_temp_1761066496450_nbqr68c4z	1	6	16
914	phase1_temp_1761066496450_nbqr68c4z	4	6	16
915	phase1_temp_1761066496450_nbqr68c4z	5	6	16
916	phase1_temp_1761066496450_nbqr68c4z	6	6	16
917	phase1_temp_1761066496450_nbqr68c4z	7	6	16
918	phase1_temp_1761066496450_nbqr68c4z	8	4	16
919	phase1_temp_1761066496450_nbqr68c4z	9	6	16
920	phase1_temp_1761066496450_nbqr68c4z	10	4	16
921	phase1_temp_1761066496450_nbqr68c4z	11	4	16
922	phase1_temp_1761066496450_nbqr68c4z	12	4	16
923	phase1_temp_1761066496450_nbqr68c4z	13	3	16
924	phase1_temp_1761066496450_nbqr68c4z	14	6	16
925	phase1_temp_1761066496450_nbqr68c4z	15	3	16
926	phase1_temp_1761066496450_nbqr68c4z	16	3	16
927	phase1_temp_1761066496450_nbqr68c4z	17	2	16
928	phase1_temp_1761066496450_nbqr68c4z	18	6	16
929	phase1_temp_1761066505736_3xakhlj37	1	4	16
930	phase1_temp_1761066505736_3xakhlj37	4	4	16
931	phase1_temp_1761066505736_3xakhlj37	5	4	16
932	phase1_temp_1761066505736_3xakhlj37	6	4	16
933	phase1_temp_1761066505736_3xakhlj37	7	4	16
934	phase1_temp_1761066505736_3xakhlj37	8	2	16
935	phase1_temp_1761066505736_3xakhlj37	9	4	16
936	phase1_temp_1761066505736_3xakhlj37	10	2	16
937	phase1_temp_1761066505736_3xakhlj37	11	2	16
938	phase1_temp_1761066505736_3xakhlj37	12	2	16
939	phase1_temp_1761066505736_3xakhlj37	13	2	16
940	phase1_temp_1761066505736_3xakhlj37	14	4	16
941	phase1_temp_1761066505736_3xakhlj37	15	2	16
942	phase1_temp_1761066505736_3xakhlj37	16	4	16
943	phase1_temp_1761066505736_3xakhlj37	17	2	16
944	phase1_temp_1761066505736_3xakhlj37	18	4	16
945	phase1_temp_1761067175225_rrin4mxsz	1	4	16
946	phase1_temp_1761067175225_rrin4mxsz	4	4	16
947	phase1_temp_1761067175225_rrin4mxsz	5	4	16
948	phase1_temp_1761067175225_rrin4mxsz	6	4	16
949	phase1_temp_1761067175225_rrin4mxsz	7	4	16
950	phase1_temp_1761067175225_rrin4mxsz	8	2	16
951	phase1_temp_1761067175225_rrin4mxsz	9	4	16
952	phase1_temp_1761067175225_rrin4mxsz	10	2	16
953	phase1_temp_1761067175225_rrin4mxsz	11	2	16
954	phase1_temp_1761067175225_rrin4mxsz	12	2	16
955	phase1_temp_1761067175225_rrin4mxsz	13	2	16
956	phase1_temp_1761067175225_rrin4mxsz	14	4	16
957	phase1_temp_1761067175225_rrin4mxsz	15	2	16
958	phase1_temp_1761067175225_rrin4mxsz	16	4	16
959	phase1_temp_1761067175225_rrin4mxsz	17	2	16
960	phase1_temp_1761067175225_rrin4mxsz	18	4	16
961	phase1_temp_1761067185881_5unpi01nr	1	2	16
962	phase1_temp_1761067185881_5unpi01nr	4	2	16
963	phase1_temp_1761067185881_5unpi01nr	5	2	16
964	phase1_temp_1761067185881_5unpi01nr	6	2	16
965	phase1_temp_1761067185881_5unpi01nr	7	2	16
966	phase1_temp_1761067185881_5unpi01nr	8	2	16
967	phase1_temp_1761067185881_5unpi01nr	9	4	16
968	phase1_temp_1761067185881_5unpi01nr	10	4	16
969	phase1_temp_1761067185881_5unpi01nr	11	2	16
970	phase1_temp_1761067185881_5unpi01nr	12	2	16
971	phase1_temp_1761067185881_5unpi01nr	13	2	16
972	phase1_temp_1761067185881_5unpi01nr	14	4	16
973	phase1_temp_1761067185881_5unpi01nr	15	4	16
974	phase1_temp_1761067185881_5unpi01nr	16	4	16
975	phase1_temp_1761067185881_5unpi01nr	17	2	16
976	phase1_temp_1761067185881_5unpi01nr	18	4	16
977	phase1_temp_1761067289219_wk56rjtrb	1	6	16
978	phase1_temp_1761067289219_wk56rjtrb	4	6	16
979	phase1_temp_1761067289219_wk56rjtrb	5	6	16
980	phase1_temp_1761067289219_wk56rjtrb	6	6	16
981	phase1_temp_1761067289219_wk56rjtrb	7	6	16
982	phase1_temp_1761067289219_wk56rjtrb	8	3	16
983	phase1_temp_1761067289219_wk56rjtrb	9	6	16
984	phase1_temp_1761067289219_wk56rjtrb	10	3	16
985	phase1_temp_1761067289219_wk56rjtrb	11	3	16
986	phase1_temp_1761067289219_wk56rjtrb	12	3	16
987	phase1_temp_1761067289219_wk56rjtrb	13	3	16
988	phase1_temp_1761067289219_wk56rjtrb	14	6	16
989	phase1_temp_1761067289219_wk56rjtrb	15	3	16
990	phase1_temp_1761067289219_wk56rjtrb	16	3	16
991	phase1_temp_1761067289219_wk56rjtrb	17	0	16
992	phase1_temp_1761067289219_wk56rjtrb	18	6	16
993	phase1_temp_1761067299128_fmegejpqf	1	6	16
994	phase1_temp_1761067299128_fmegejpqf	4	6	16
995	phase1_temp_1761067299128_fmegejpqf	5	6	16
996	phase1_temp_1761067299128_fmegejpqf	6	6	16
997	phase1_temp_1761067299128_fmegejpqf	7	6	16
998	phase1_temp_1761067299128_fmegejpqf	8	3	16
999	phase1_temp_1761067299128_fmegejpqf	9	6	16
1000	phase1_temp_1761067299128_fmegejpqf	10	3	16
1001	phase1_temp_1761067299128_fmegejpqf	11	3	16
1002	phase1_temp_1761067299128_fmegejpqf	12	3	16
1003	phase1_temp_1761067299128_fmegejpqf	13	3	16
1004	phase1_temp_1761067299128_fmegejpqf	14	6	16
1005	phase1_temp_1761067299128_fmegejpqf	15	4	16
1006	phase1_temp_1761067299128_fmegejpqf	16	3	16
1007	phase1_temp_1761067299128_fmegejpqf	17	0	16
1008	phase1_temp_1761067299128_fmegejpqf	18	6	16
1249	debug_test_user	4	4	11
1250	debug_test_user	14	0	11
1251	debug_test_user	17	0	11
1252	debug_test_user	13	4	11
1253	debug_test_user	10	4	11
1254	debug_test_user	7	2	11
1255	debug_test_user	9	4	11
1256	debug_test_user	1	2	11
1257	debug_test_user	5	4	11
1258	debug_test_user	18	4	11
1259	debug_test_user	16	4	11
1260	debug_test_user	15	4	11
1261	debug_test_user	6	4	11
1262	debug_test_user	12	4	11
1263	debug_test_user	11	4	11
1264	debug_test_user	8	4	11
1041	test_sw_dev_faiss	4	0	11
1042	test_sw_dev_faiss	14	0	11
1043	test_sw_dev_faiss	17	0	11
1044	test_sw_dev_faiss	13	0	11
1045	test_sw_dev_faiss	10	0	11
1046	test_sw_dev_faiss	7	0	11
1047	test_sw_dev_faiss	9	0	11
1048	test_sw_dev_faiss	1	0	11
1049	test_sw_dev_faiss	5	0	11
1050	test_sw_dev_faiss	18	0	11
1051	test_sw_dev_faiss	16	0	11
1052	test_sw_dev_faiss	15	0	11
1053	test_sw_dev_faiss	6	0	11
1054	test_sw_dev_faiss	12	0	11
1055	test_sw_dev_faiss	11	0	11
1056	test_sw_dev_faiss	8	0	11
1089	phase1_temp_1761071366657_vycue5okr	1	0	16
1090	phase1_temp_1761071366657_vycue5okr	4	0	16
1091	phase1_temp_1761071366657_vycue5okr	5	0	16
1092	phase1_temp_1761071366657_vycue5okr	6	0	16
1093	phase1_temp_1761071366657_vycue5okr	7	0	16
1094	phase1_temp_1761071366657_vycue5okr	8	0	16
1095	phase1_temp_1761071366657_vycue5okr	9	0	16
1096	phase1_temp_1761071366657_vycue5okr	10	0	16
1097	phase1_temp_1761071366657_vycue5okr	11	0	16
1098	phase1_temp_1761071366657_vycue5okr	12	0	16
1099	phase1_temp_1761071366657_vycue5okr	13	0	16
1100	phase1_temp_1761071366657_vycue5okr	14	0	16
1101	phase1_temp_1761071366657_vycue5okr	15	0	16
1102	phase1_temp_1761071366657_vycue5okr	16	0	16
1103	phase1_temp_1761071366657_vycue5okr	17	0	16
1104	phase1_temp_1761071366657_vycue5okr	18	0	16
1105	phase1_temp_1761071375895_60ag35lq0	1	0	16
1106	phase1_temp_1761071375895_60ag35lq0	4	0	16
1107	phase1_temp_1761071375895_60ag35lq0	5	0	16
1108	phase1_temp_1761071375895_60ag35lq0	6	0	16
1109	phase1_temp_1761071375895_60ag35lq0	7	0	16
1110	phase1_temp_1761071375895_60ag35lq0	8	0	16
1111	phase1_temp_1761071375895_60ag35lq0	9	0	16
1112	phase1_temp_1761071375895_60ag35lq0	10	0	16
1113	phase1_temp_1761071375895_60ag35lq0	11	0	16
1114	phase1_temp_1761071375895_60ag35lq0	12	0	16
1115	phase1_temp_1761071375895_60ag35lq0	13	0	16
1116	phase1_temp_1761071375895_60ag35lq0	14	0	16
1117	phase1_temp_1761071375895_60ag35lq0	15	0	16
1118	phase1_temp_1761071375895_60ag35lq0	16	0	16
1119	phase1_temp_1761071375895_60ag35lq0	17	0	16
1120	phase1_temp_1761071375895_60ag35lq0	18	0	16
1121	phase1_temp_1761071384786_qoj0q05nw	1	0	16
1122	phase1_temp_1761071384786_qoj0q05nw	4	0	16
1123	phase1_temp_1761071384786_qoj0q05nw	5	0	16
1124	phase1_temp_1761071384786_qoj0q05nw	6	0	16
1125	phase1_temp_1761071384786_qoj0q05nw	7	0	16
1126	phase1_temp_1761071384786_qoj0q05nw	8	0	16
1127	phase1_temp_1761071384786_qoj0q05nw	9	0	16
1128	phase1_temp_1761071384786_qoj0q05nw	10	0	16
1129	phase1_temp_1761071384786_qoj0q05nw	11	0	16
1130	phase1_temp_1761071384786_qoj0q05nw	12	0	16
1131	phase1_temp_1761071384786_qoj0q05nw	13	0	16
1132	phase1_temp_1761071384786_qoj0q05nw	14	0	16
1133	phase1_temp_1761071384786_qoj0q05nw	15	0	16
1134	phase1_temp_1761071384786_qoj0q05nw	16	0	16
1135	phase1_temp_1761071384786_qoj0q05nw	17	0	16
1136	phase1_temp_1761071384786_qoj0q05nw	18	0	16
1137	phase1_temp_1761071395139_7629y4n49	1	0	16
1138	phase1_temp_1761071395139_7629y4n49	4	0	16
1139	phase1_temp_1761071395139_7629y4n49	5	0	16
1140	phase1_temp_1761071395139_7629y4n49	6	0	16
1141	phase1_temp_1761071395139_7629y4n49	7	0	16
1142	phase1_temp_1761071395139_7629y4n49	8	0	16
1143	phase1_temp_1761071395139_7629y4n49	9	0	16
1144	phase1_temp_1761071395139_7629y4n49	10	0	16
1145	phase1_temp_1761071395139_7629y4n49	11	0	16
1146	phase1_temp_1761071395139_7629y4n49	12	0	16
1147	phase1_temp_1761071395139_7629y4n49	13	0	16
1148	phase1_temp_1761071395139_7629y4n49	14	0	16
1149	phase1_temp_1761071395139_7629y4n49	15	0	16
1150	phase1_temp_1761071395139_7629y4n49	16	0	16
1151	phase1_temp_1761071395139_7629y4n49	17	0	16
1152	phase1_temp_1761071395139_7629y4n49	18	0	16
1153	phase1_temp_1761071402915_9wceu3zya	4	0	16
1154	phase1_temp_1761071402915_9wceu3zya	14	0	16
1155	phase1_temp_1761071402915_9wceu3zya	17	0	16
1156	phase1_temp_1761071402915_9wceu3zya	13	0	16
1157	phase1_temp_1761071402915_9wceu3zya	10	0	16
1158	phase1_temp_1761071402915_9wceu3zya	7	0	16
1159	phase1_temp_1761071402915_9wceu3zya	9	0	16
1160	phase1_temp_1761071402915_9wceu3zya	1	0	16
1161	phase1_temp_1761071402915_9wceu3zya	5	0	16
1162	phase1_temp_1761071402915_9wceu3zya	18	0	16
1163	phase1_temp_1761071402915_9wceu3zya	16	0	16
1164	phase1_temp_1761071402915_9wceu3zya	15	0	16
1165	phase1_temp_1761071402915_9wceu3zya	6	0	16
1166	phase1_temp_1761071402915_9wceu3zya	12	0	16
1167	phase1_temp_1761071402915_9wceu3zya	11	0	16
1168	phase1_temp_1761071402915_9wceu3zya	8	0	16
1169	test_role_suggestion_user	4	0	11
1170	test_role_suggestion_user	14	0	11
1171	test_role_suggestion_user	17	0	11
1172	test_role_suggestion_user	13	0	11
1173	test_role_suggestion_user	10	0	11
1174	test_role_suggestion_user	7	0	11
1175	test_role_suggestion_user	9	0	11
1176	test_role_suggestion_user	1	0	11
1177	test_role_suggestion_user	5	0	11
1178	test_role_suggestion_user	18	0	11
1179	test_role_suggestion_user	16	0	11
1180	test_role_suggestion_user	15	0	11
1181	test_role_suggestion_user	6	0	11
1182	test_role_suggestion_user	12	0	11
1183	test_role_suggestion_user	11	0	11
1184	test_role_suggestion_user	8	0	11
1297	e2e_test_user	4	4	11
1298	e2e_test_user	14	4	11
1299	e2e_test_user	17	1	11
1300	e2e_test_user	13	4	11
1301	e2e_test_user	10	4	11
1302	e2e_test_user	7	4	11
1303	e2e_test_user	9	4	11
1304	e2e_test_user	1	4	11
1305	e2e_test_user	5	4	11
1306	e2e_test_user	18	4	11
1307	e2e_test_user	16	4	11
1308	e2e_test_user	15	4	11
1309	e2e_test_user	6	4	11
1310	e2e_test_user	12	4	11
1311	e2e_test_user	11	4	11
1312	e2e_test_user	8	4	11
1313	phase1_temp_1761076421752_dbnyodnuc	1	2	16
1314	phase1_temp_1761076421752_dbnyodnuc	4	4	16
1315	phase1_temp_1761076421752_dbnyodnuc	5	4	16
1316	phase1_temp_1761076421752_dbnyodnuc	6	4	16
1317	phase1_temp_1761076421752_dbnyodnuc	7	2	16
1318	phase1_temp_1761076421752_dbnyodnuc	8	4	16
1319	phase1_temp_1761076421752_dbnyodnuc	9	4	16
1320	phase1_temp_1761076421752_dbnyodnuc	10	4	16
1321	phase1_temp_1761076421752_dbnyodnuc	11	4	16
1322	phase1_temp_1761076421752_dbnyodnuc	12	4	16
1323	phase1_temp_1761076421752_dbnyodnuc	13	4	16
1324	phase1_temp_1761076421752_dbnyodnuc	14	0	16
1325	phase1_temp_1761076421752_dbnyodnuc	15	4	16
1326	phase1_temp_1761076421752_dbnyodnuc	16	4	16
1327	phase1_temp_1761076421752_dbnyodnuc	17	0	16
1328	phase1_temp_1761076421752_dbnyodnuc	18	4	16
1329	phase1_temp_1761078186663_izzurhsx4	1	2	16
1330	phase1_temp_1761078186663_izzurhsx4	4	4	16
1331	phase1_temp_1761078186663_izzurhsx4	5	4	16
1332	phase1_temp_1761078186663_izzurhsx4	6	4	16
1333	phase1_temp_1761078186663_izzurhsx4	7	2	16
1334	phase1_temp_1761078186663_izzurhsx4	8	4	16
1335	phase1_temp_1761078186663_izzurhsx4	9	4	16
1336	phase1_temp_1761078186663_izzurhsx4	10	4	16
1337	phase1_temp_1761078186663_izzurhsx4	11	4	16
1338	phase1_temp_1761078186663_izzurhsx4	12	4	16
1339	phase1_temp_1761078186663_izzurhsx4	13	4	16
1340	phase1_temp_1761078186663_izzurhsx4	14	0	16
1341	phase1_temp_1761078186663_izzurhsx4	15	4	16
1342	phase1_temp_1761078186663_izzurhsx4	16	4	16
1343	phase1_temp_1761078186663_izzurhsx4	17	0	16
1344	phase1_temp_1761078186663_izzurhsx4	18	4	16
1345	phase1_temp_1761078196076_fk7i9uhr8	1	2	16
1346	phase1_temp_1761078196076_fk7i9uhr8	4	2	16
1347	phase1_temp_1761078196076_fk7i9uhr8	5	2	16
1348	phase1_temp_1761078196076_fk7i9uhr8	6	2	16
1349	phase1_temp_1761078196076_fk7i9uhr8	7	2	16
1350	phase1_temp_1761078196076_fk7i9uhr8	8	4	16
1351	phase1_temp_1761078196076_fk7i9uhr8	9	2	16
1352	phase1_temp_1761078196076_fk7i9uhr8	10	4	16
1353	phase1_temp_1761078196076_fk7i9uhr8	11	4	16
1354	phase1_temp_1761078196076_fk7i9uhr8	12	4	16
1355	phase1_temp_1761078196076_fk7i9uhr8	13	4	16
1356	phase1_temp_1761078196076_fk7i9uhr8	14	2	16
1357	phase1_temp_1761078196076_fk7i9uhr8	15	4	16
1358	phase1_temp_1761078196076_fk7i9uhr8	16	4	16
1359	phase1_temp_1761078196076_fk7i9uhr8	17	0	16
1360	phase1_temp_1761078196076_fk7i9uhr8	18	2	16
1361	phase1_temp_1761078205299_50ue3pgd6	1	2	16
1362	phase1_temp_1761078205299_50ue3pgd6	4	2	16
1363	phase1_temp_1761078205299_50ue3pgd6	5	2	16
1364	phase1_temp_1761078205299_50ue3pgd6	6	2	16
1365	phase1_temp_1761078205299_50ue3pgd6	7	2	16
1366	phase1_temp_1761078205299_50ue3pgd6	8	2	16
1367	phase1_temp_1761078205299_50ue3pgd6	9	2	16
1368	phase1_temp_1761078205299_50ue3pgd6	10	2	16
1369	phase1_temp_1761078205299_50ue3pgd6	11	0	16
1370	phase1_temp_1761078205299_50ue3pgd6	12	2	16
1371	phase1_temp_1761078205299_50ue3pgd6	13	2	16
1372	phase1_temp_1761078205299_50ue3pgd6	14	2	16
1373	phase1_temp_1761078205299_50ue3pgd6	15	2	16
1374	phase1_temp_1761078205299_50ue3pgd6	16	0	16
1375	phase1_temp_1761078205299_50ue3pgd6	17	0	16
1376	phase1_temp_1761078205299_50ue3pgd6	18	2	16
1377	phase1_temp_1761078213117_euvzag1wq	1	4	16
1378	phase1_temp_1761078213117_euvzag1wq	4	4	16
1379	phase1_temp_1761078213117_euvzag1wq	5	4	16
1380	phase1_temp_1761078213117_euvzag1wq	6	2	16
1381	phase1_temp_1761078213117_euvzag1wq	7	4	16
1382	phase1_temp_1761078213117_euvzag1wq	8	4	16
1383	phase1_temp_1761078213117_euvzag1wq	9	4	16
1384	phase1_temp_1761078213117_euvzag1wq	10	4	16
1385	phase1_temp_1761078213117_euvzag1wq	11	4	16
1386	phase1_temp_1761078213117_euvzag1wq	12	4	16
1387	phase1_temp_1761078213117_euvzag1wq	13	2	16
1388	phase1_temp_1761078213117_euvzag1wq	14	2	16
1389	phase1_temp_1761078213117_euvzag1wq	15	2	16
1390	phase1_temp_1761078213117_euvzag1wq	16	2	16
1391	phase1_temp_1761078213117_euvzag1wq	17	2	16
1392	phase1_temp_1761078213117_euvzag1wq	18	4	16
1393	phase1_temp_1761078220613_mgy5fhm9t	1	4	16
1394	phase1_temp_1761078220613_mgy5fhm9t	4	4	16
1395	phase1_temp_1761078220613_mgy5fhm9t	5	4	16
1396	phase1_temp_1761078220613_mgy5fhm9t	6	4	16
1397	phase1_temp_1761078220613_mgy5fhm9t	7	4	16
1398	phase1_temp_1761078220613_mgy5fhm9t	8	2	16
1399	phase1_temp_1761078220613_mgy5fhm9t	9	4	16
1400	phase1_temp_1761078220613_mgy5fhm9t	10	2	16
1401	phase1_temp_1761078220613_mgy5fhm9t	11	2	16
1402	phase1_temp_1761078220613_mgy5fhm9t	12	2	16
1403	phase1_temp_1761078220613_mgy5fhm9t	13	2	16
1404	phase1_temp_1761078220613_mgy5fhm9t	14	4	16
1405	phase1_temp_1761078220613_mgy5fhm9t	15	2	16
1406	phase1_temp_1761078220613_mgy5fhm9t	16	2	16
1407	phase1_temp_1761078220613_mgy5fhm9t	17	0	16
1408	phase1_temp_1761078220613_mgy5fhm9t	18	4	16
1409	test_llm_vs_euclidean_1761080097_5532	4	4	11
1410	test_llm_vs_euclidean_1761080097_5532	14	0	11
1411	test_llm_vs_euclidean_1761080097_5532	17	0	11
1412	test_llm_vs_euclidean_1761080097_5532	13	4	11
1413	test_llm_vs_euclidean_1761080097_5532	10	4	11
1414	test_llm_vs_euclidean_1761080097_5532	7	2	11
1415	test_llm_vs_euclidean_1761080097_5532	9	4	11
1416	test_llm_vs_euclidean_1761080097_5532	1	2	11
1417	test_llm_vs_euclidean_1761080097_5532	5	4	11
1418	test_llm_vs_euclidean_1761080097_5532	18	4	11
1419	test_llm_vs_euclidean_1761080097_5532	16	4	11
1420	test_llm_vs_euclidean_1761080097_5532	15	4	11
1421	test_llm_vs_euclidean_1761080097_5532	6	4	11
1422	test_llm_vs_euclidean_1761080097_5532	12	4	11
1423	test_llm_vs_euclidean_1761080097_5532	11	4	11
1424	test_llm_vs_euclidean_1761080097_5532	8	4	11
1425	test_llm_vs_euclidean_1761080140_7134	4	4	11
1426	test_llm_vs_euclidean_1761080140_7134	14	0	11
1427	test_llm_vs_euclidean_1761080140_7134	17	0	11
1428	test_llm_vs_euclidean_1761080140_7134	13	4	11
1429	test_llm_vs_euclidean_1761080140_7134	10	4	11
1430	test_llm_vs_euclidean_1761080140_7134	7	2	11
1431	test_llm_vs_euclidean_1761080140_7134	9	4	11
1432	test_llm_vs_euclidean_1761080140_7134	1	2	11
1433	test_llm_vs_euclidean_1761080140_7134	5	4	11
1434	test_llm_vs_euclidean_1761080140_7134	18	4	11
1435	test_llm_vs_euclidean_1761080140_7134	16	4	11
1436	test_llm_vs_euclidean_1761080140_7134	15	4	11
1437	test_llm_vs_euclidean_1761080140_7134	6	4	11
1438	test_llm_vs_euclidean_1761080140_7134	12	4	11
1439	test_llm_vs_euclidean_1761080140_7134	11	4	11
1440	test_llm_vs_euclidean_1761080140_7134	8	4	11
1441	test_llm_vs_euclidean_1761080164_9703	4	4	11
1442	test_llm_vs_euclidean_1761080164_9703	14	2	11
1443	test_llm_vs_euclidean_1761080164_9703	17	0	11
1444	test_llm_vs_euclidean_1761080164_9703	13	4	11
1445	test_llm_vs_euclidean_1761080164_9703	10	4	11
1446	test_llm_vs_euclidean_1761080164_9703	7	2	11
1447	test_llm_vs_euclidean_1761080164_9703	9	4	11
1448	test_llm_vs_euclidean_1761080164_9703	1	2	11
1449	test_llm_vs_euclidean_1761080164_9703	5	4	11
1450	test_llm_vs_euclidean_1761080164_9703	18	4	11
1451	test_llm_vs_euclidean_1761080164_9703	16	4	11
1452	test_llm_vs_euclidean_1761080164_9703	15	4	11
1453	test_llm_vs_euclidean_1761080164_9703	6	4	11
1454	test_llm_vs_euclidean_1761080164_9703	12	4	11
1455	test_llm_vs_euclidean_1761080164_9703	11	4	11
1456	test_llm_vs_euclidean_1761080164_9703	8	4	11
1457	test_llm_vs_euclidean_1761080185_9069	4	2	11
1458	test_llm_vs_euclidean_1761080185_9069	14	4	11
1459	test_llm_vs_euclidean_1761080185_9069	17	1	11
1460	test_llm_vs_euclidean_1761080185_9069	13	2	11
1461	test_llm_vs_euclidean_1761080185_9069	10	4	11
1462	test_llm_vs_euclidean_1761080185_9069	7	2	11
1463	test_llm_vs_euclidean_1761080185_9069	9	2	11
1464	test_llm_vs_euclidean_1761080185_9069	1	2	11
1465	test_llm_vs_euclidean_1761080185_9069	5	2	11
1466	test_llm_vs_euclidean_1761080185_9069	18	2	11
1467	test_llm_vs_euclidean_1761080185_9069	16	2	11
1468	test_llm_vs_euclidean_1761080185_9069	15	4	11
1469	test_llm_vs_euclidean_1761080185_9069	6	2	11
1470	test_llm_vs_euclidean_1761080185_9069	12	2	11
1471	test_llm_vs_euclidean_1761080185_9069	11	1	11
1472	test_llm_vs_euclidean_1761080185_9069	8	2	11
1473	phase1_temp_1761080345662_5i6al8edx	1	2	16
1474	phase1_temp_1761080345662_5i6al8edx	4	4	16
1475	phase1_temp_1761080345662_5i6al8edx	5	4	16
1476	phase1_temp_1761080345662_5i6al8edx	6	4	16
1477	phase1_temp_1761080345662_5i6al8edx	7	2	16
1478	phase1_temp_1761080345662_5i6al8edx	8	4	16
1479	phase1_temp_1761080345662_5i6al8edx	9	4	16
1480	phase1_temp_1761080345662_5i6al8edx	10	4	16
1481	phase1_temp_1761080345662_5i6al8edx	11	4	16
1482	phase1_temp_1761080345662_5i6al8edx	12	4	16
1483	phase1_temp_1761080345662_5i6al8edx	13	4	16
1484	phase1_temp_1761080345662_5i6al8edx	14	0	16
1485	phase1_temp_1761080345662_5i6al8edx	15	4	16
1486	phase1_temp_1761080345662_5i6al8edx	16	4	16
1487	phase1_temp_1761080345662_5i6al8edx	17	0	16
1488	phase1_temp_1761080345662_5i6al8edx	18	4	16
1489	phase1_temp_1761080585221_a9rn20mov	1	4	16
1490	phase1_temp_1761080585221_a9rn20mov	4	4	16
1491	phase1_temp_1761080585221_a9rn20mov	5	4	16
1492	phase1_temp_1761080585221_a9rn20mov	6	4	16
1493	phase1_temp_1761080585221_a9rn20mov	7	4	16
1494	phase1_temp_1761080585221_a9rn20mov	8	4	16
1495	phase1_temp_1761080585221_a9rn20mov	9	4	16
1496	phase1_temp_1761080585221_a9rn20mov	10	4	16
1497	phase1_temp_1761080585221_a9rn20mov	11	4	16
1498	phase1_temp_1761080585221_a9rn20mov	12	4	16
1499	phase1_temp_1761080585221_a9rn20mov	13	4	16
1500	phase1_temp_1761080585221_a9rn20mov	14	4	16
1501	phase1_temp_1761080585221_a9rn20mov	15	4	16
1502	phase1_temp_1761080585221_a9rn20mov	16	4	16
1503	phase1_temp_1761080585221_a9rn20mov	17	0	16
1504	phase1_temp_1761080585221_a9rn20mov	18	4	16
1505	phase1_temp_1761081052624_0ymt33gyc	1	2	16
1506	phase1_temp_1761081052624_0ymt33gyc	4	2	16
1507	phase1_temp_1761081052624_0ymt33gyc	5	2	16
1508	phase1_temp_1761081052624_0ymt33gyc	6	2	16
1509	phase1_temp_1761081052624_0ymt33gyc	7	2	16
1510	phase1_temp_1761081052624_0ymt33gyc	8	4	16
1511	phase1_temp_1761081052624_0ymt33gyc	9	2	16
1512	phase1_temp_1761081052624_0ymt33gyc	10	4	16
1513	phase1_temp_1761081052624_0ymt33gyc	11	4	16
1514	phase1_temp_1761081052624_0ymt33gyc	12	4	16
1515	phase1_temp_1761081052624_0ymt33gyc	13	4	16
1516	phase1_temp_1761081052624_0ymt33gyc	14	2	16
1517	phase1_temp_1761081052624_0ymt33gyc	15	4	16
1518	phase1_temp_1761081052624_0ymt33gyc	16	4	16
1519	phase1_temp_1761081052624_0ymt33gyc	17	0	16
1520	phase1_temp_1761081052624_0ymt33gyc	18	2	16
1521	phase1_temp_1761081062471_88kplr0oc	1	2	16
1522	phase1_temp_1761081062471_88kplr0oc	4	2	16
1523	phase1_temp_1761081062471_88kplr0oc	5	2	16
1524	phase1_temp_1761081062471_88kplr0oc	6	2	16
1525	phase1_temp_1761081062471_88kplr0oc	7	2	16
1526	phase1_temp_1761081062471_88kplr0oc	8	2	16
1527	phase1_temp_1761081062471_88kplr0oc	9	2	16
1528	phase1_temp_1761081062471_88kplr0oc	10	2	16
1529	phase1_temp_1761081062471_88kplr0oc	11	0	16
1530	phase1_temp_1761081062471_88kplr0oc	12	2	16
1531	phase1_temp_1761081062471_88kplr0oc	13	2	16
1532	phase1_temp_1761081062471_88kplr0oc	14	2	16
1533	phase1_temp_1761081062471_88kplr0oc	15	2	16
1534	phase1_temp_1761081062471_88kplr0oc	16	0	16
1535	phase1_temp_1761081062471_88kplr0oc	17	0	16
1536	phase1_temp_1761081062471_88kplr0oc	18	2	16
1537	phase1_temp_1761081072810_hp4ajoc0b	4	4	16
1538	phase1_temp_1761081072810_hp4ajoc0b	14	2	16
1539	phase1_temp_1761081072810_hp4ajoc0b	17	2	16
1540	phase1_temp_1761081072810_hp4ajoc0b	13	2	16
1541	phase1_temp_1761081072810_hp4ajoc0b	10	4	16
1542	phase1_temp_1761081072810_hp4ajoc0b	7	4	16
1543	phase1_temp_1761081072810_hp4ajoc0b	9	4	16
1544	phase1_temp_1761081072810_hp4ajoc0b	1	4	16
1545	phase1_temp_1761081072810_hp4ajoc0b	5	4	16
1546	phase1_temp_1761081072810_hp4ajoc0b	18	4	16
1547	phase1_temp_1761081072810_hp4ajoc0b	16	2	16
1548	phase1_temp_1761081072810_hp4ajoc0b	15	2	16
1549	phase1_temp_1761081072810_hp4ajoc0b	6	2	16
1550	phase1_temp_1761081072810_hp4ajoc0b	12	4	16
1551	phase1_temp_1761081072810_hp4ajoc0b	11	4	16
1552	phase1_temp_1761081072810_hp4ajoc0b	8	4	16
1553	phase1_temp_1761081084534_c7r10cv4l	4	4	16
1554	phase1_temp_1761081084534_c7r10cv4l	14	4	16
1555	phase1_temp_1761081084534_c7r10cv4l	17	0	16
1556	phase1_temp_1761081084534_c7r10cv4l	13	2	16
1557	phase1_temp_1761081084534_c7r10cv4l	10	2	16
1558	phase1_temp_1761081084534_c7r10cv4l	7	4	16
1559	phase1_temp_1761081084534_c7r10cv4l	9	4	16
1560	phase1_temp_1761081084534_c7r10cv4l	1	4	16
1561	phase1_temp_1761081084534_c7r10cv4l	5	4	16
1562	phase1_temp_1761081084534_c7r10cv4l	18	4	16
1563	phase1_temp_1761081084534_c7r10cv4l	16	2	16
1564	phase1_temp_1761081084534_c7r10cv4l	15	2	16
1565	phase1_temp_1761081084534_c7r10cv4l	6	4	16
1566	phase1_temp_1761081084534_c7r10cv4l	12	2	16
1567	phase1_temp_1761081084534_c7r10cv4l	11	2	16
1568	phase1_temp_1761081084534_c7r10cv4l	8	2	16
1569	phase1_temp_1761084250260_8hl6wh7vx	4	4	17
1570	phase1_temp_1761084250260_8hl6wh7vx	14	2	17
1571	phase1_temp_1761084250260_8hl6wh7vx	17	0	17
1572	phase1_temp_1761084250260_8hl6wh7vx	13	4	17
1573	phase1_temp_1761084250260_8hl6wh7vx	10	4	17
1574	phase1_temp_1761084250260_8hl6wh7vx	7	2	17
1575	phase1_temp_1761084250260_8hl6wh7vx	9	4	17
1576	phase1_temp_1761084250260_8hl6wh7vx	1	2	17
1577	phase1_temp_1761084250260_8hl6wh7vx	5	4	17
1578	phase1_temp_1761084250260_8hl6wh7vx	18	4	17
1579	phase1_temp_1761084250260_8hl6wh7vx	16	4	17
1580	phase1_temp_1761084250260_8hl6wh7vx	15	4	17
1581	phase1_temp_1761084250260_8hl6wh7vx	6	4	17
1582	phase1_temp_1761084250260_8hl6wh7vx	12	4	17
1583	phase1_temp_1761084250260_8hl6wh7vx	11	4	17
1584	phase1_temp_1761084250260_8hl6wh7vx	8	4	17
1585	phase1_temp_1761089467953_w1qx12pv2	4	4	18
1586	phase1_temp_1761089467953_w1qx12pv2	14	4	18
1587	phase1_temp_1761089467953_w1qx12pv2	17	0	18
1588	phase1_temp_1761089467953_w1qx12pv2	13	2	18
1589	phase1_temp_1761089467953_w1qx12pv2	10	2	18
1590	phase1_temp_1761089467953_w1qx12pv2	7	4	18
1591	phase1_temp_1761089467953_w1qx12pv2	9	4	18
1592	phase1_temp_1761089467953_w1qx12pv2	1	4	18
1593	phase1_temp_1761089467953_w1qx12pv2	5	4	18
1594	phase1_temp_1761089467953_w1qx12pv2	18	4	18
1595	phase1_temp_1761089467953_w1qx12pv2	16	2	18
1596	phase1_temp_1761089467953_w1qx12pv2	15	2	18
1597	phase1_temp_1761089467953_w1qx12pv2	6	4	18
1598	phase1_temp_1761089467953_w1qx12pv2	12	2	18
1599	phase1_temp_1761089467953_w1qx12pv2	11	2	18
1600	phase1_temp_1761089467953_w1qx12pv2	8	2	18
1601	phase1_temp_1761089478883_rjy0nk1ah	4	2	18
1602	phase1_temp_1761089478883_rjy0nk1ah	14	2	18
1603	phase1_temp_1761089478883_rjy0nk1ah	17	0	18
1604	phase1_temp_1761089478883_rjy0nk1ah	13	4	18
1605	phase1_temp_1761089478883_rjy0nk1ah	10	4	18
1606	phase1_temp_1761089478883_rjy0nk1ah	7	2	18
1607	phase1_temp_1761089478883_rjy0nk1ah	9	2	18
1608	phase1_temp_1761089478883_rjy0nk1ah	1	2	18
1609	phase1_temp_1761089478883_rjy0nk1ah	5	2	18
1610	phase1_temp_1761089478883_rjy0nk1ah	18	2	18
1611	phase1_temp_1761089478883_rjy0nk1ah	16	4	18
1612	phase1_temp_1761089478883_rjy0nk1ah	15	4	18
1613	phase1_temp_1761089478883_rjy0nk1ah	6	2	18
1614	phase1_temp_1761089478883_rjy0nk1ah	12	4	18
1615	phase1_temp_1761089478883_rjy0nk1ah	11	4	18
1616	phase1_temp_1761089478883_rjy0nk1ah	8	4	18
1617	phase1_temp_1761183318380_zibljjb4o	4	4	20
1618	phase1_temp_1761183318380_zibljjb4o	14	0	20
1619	phase1_temp_1761183318380_zibljjb4o	17	0	20
1620	phase1_temp_1761183318380_zibljjb4o	13	4	20
1621	phase1_temp_1761183318380_zibljjb4o	10	4	20
1622	phase1_temp_1761183318380_zibljjb4o	7	2	20
1623	phase1_temp_1761183318380_zibljjb4o	9	4	20
1624	phase1_temp_1761183318380_zibljjb4o	1	2	20
1625	phase1_temp_1761183318380_zibljjb4o	5	4	20
1626	phase1_temp_1761183318380_zibljjb4o	18	4	20
1627	phase1_temp_1761183318380_zibljjb4o	16	4	20
1628	phase1_temp_1761183318380_zibljjb4o	15	4	20
1629	phase1_temp_1761183318380_zibljjb4o	6	4	20
1630	phase1_temp_1761183318380_zibljjb4o	12	4	20
1631	phase1_temp_1761183318380_zibljjb4o	11	4	20
1632	phase1_temp_1761183318380_zibljjb4o	8	4	20
1633	phase1_temp_1761183329459_83r06dyjq	4	2	20
1634	phase1_temp_1761183329459_83r06dyjq	14	2	20
1635	phase1_temp_1761183329459_83r06dyjq	17	0	20
1636	phase1_temp_1761183329459_83r06dyjq	13	4	20
1637	phase1_temp_1761183329459_83r06dyjq	10	4	20
1638	phase1_temp_1761183329459_83r06dyjq	7	2	20
1639	phase1_temp_1761183329459_83r06dyjq	9	2	20
1640	phase1_temp_1761183329459_83r06dyjq	1	2	20
1641	phase1_temp_1761183329459_83r06dyjq	5	2	20
1642	phase1_temp_1761183329459_83r06dyjq	18	2	20
1643	phase1_temp_1761183329459_83r06dyjq	16	4	20
1644	phase1_temp_1761183329459_83r06dyjq	15	4	20
1645	phase1_temp_1761183329459_83r06dyjq	6	2	20
1646	phase1_temp_1761183329459_83r06dyjq	12	4	20
1647	phase1_temp_1761183329459_83r06dyjq	11	4	20
1648	phase1_temp_1761183329459_83r06dyjq	8	4	20
1649	phase1_temp_1761183338741_u6agh68ox	4	2	20
1650	phase1_temp_1761183338741_u6agh68ox	14	2	20
1651	phase1_temp_1761183338741_u6agh68ox	17	0	20
1652	phase1_temp_1761183338741_u6agh68ox	13	2	20
1653	phase1_temp_1761183338741_u6agh68ox	10	2	20
1654	phase1_temp_1761183338741_u6agh68ox	7	2	20
1655	phase1_temp_1761183338741_u6agh68ox	9	2	20
1656	phase1_temp_1761183338741_u6agh68ox	1	2	20
1657	phase1_temp_1761183338741_u6agh68ox	5	2	20
1658	phase1_temp_1761183338741_u6agh68ox	18	2	20
1659	phase1_temp_1761183338741_u6agh68ox	16	0	20
1660	phase1_temp_1761183338741_u6agh68ox	15	2	20
1661	phase1_temp_1761183338741_u6agh68ox	6	2	20
1662	phase1_temp_1761183338741_u6agh68ox	12	2	20
1663	phase1_temp_1761183338741_u6agh68ox	11	0	20
1664	phase1_temp_1761183338741_u6agh68ox	8	2	20
1665	phase1_temp_1761183348360_zhem1a57f	4	4	20
1666	phase1_temp_1761183348360_zhem1a57f	14	4	20
1667	phase1_temp_1761183348360_zhem1a57f	17	0	20
1668	phase1_temp_1761183348360_zhem1a57f	13	2	20
1669	phase1_temp_1761183348360_zhem1a57f	10	2	20
1670	phase1_temp_1761183348360_zhem1a57f	7	4	20
1671	phase1_temp_1761183348360_zhem1a57f	9	4	20
1672	phase1_temp_1761183348360_zhem1a57f	1	4	20
1673	phase1_temp_1761183348360_zhem1a57f	5	4	20
1674	phase1_temp_1761183348360_zhem1a57f	18	4	20
1675	phase1_temp_1761183348360_zhem1a57f	16	2	20
1676	phase1_temp_1761183348360_zhem1a57f	15	2	20
1677	phase1_temp_1761183348360_zhem1a57f	6	4	20
1678	phase1_temp_1761183348360_zhem1a57f	12	2	20
1679	phase1_temp_1761183348360_zhem1a57f	11	2	20
1680	phase1_temp_1761183348360_zhem1a57f	8	2	20
\.


--
-- Data for Name: unknown_role_process_matrix; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.unknown_role_process_matrix (id, user_name, iso_process_id, role_process_value, organization_id) FROM stdin;
1	test_dev_user	1	0	1
2	test_dev_user	2	0	1
3	test_dev_user	3	0	1
4	test_dev_user	4	0	1
5	test_dev_user	5	0	1
6	test_dev_user	6	0	1
7	test_dev_user	7	0	1
8	test_dev_user	8	0	1
9	test_dev_user	9	0	1
10	test_dev_user	10	0	1
11	test_dev_user	11	0	1
12	test_dev_user	12	0	1
13	test_dev_user	13	0	1
14	test_dev_user	14	0	1
15	test_dev_user	15	0	1
16	test_dev_user	16	0	1
17	test_dev_user	17	0	1
18	test_dev_user	18	2	1
20	test_dev_user	20	0	1
21	test_dev_user	21	2	1
22	test_dev_user	22	1	1
23	test_dev_user	23	1	1
24	test_dev_user	24	0	1
25	test_dev_user	25	1	1
26	test_dev_user	26	0	1
27	test_dev_user	27	0	1
28	test_dev_user	28	0	1
29	test_dev_user_final	1	0	1
30	test_dev_user_final	2	0	1
31	test_dev_user_final	3	0	1
32	test_dev_user_final	4	0	1
33	test_dev_user_final	5	0	1
34	test_dev_user_final	6	0	1
35	test_dev_user_final	7	0	1
36	test_dev_user_final	8	0	1
37	test_dev_user_final	9	0	1
38	test_dev_user_final	10	0	1
39	test_dev_user_final	11	0	1
40	test_dev_user_final	12	0	1
41	test_dev_user_final	13	0	1
42	test_dev_user_final	14	0	1
43	test_dev_user_final	15	0	1
44	test_dev_user_final	16	0	1
45	test_dev_user_final	17	0	1
2747	test_llm_vs_euclidean_1761080164_9703	1	0	11
2748	test_llm_vs_euclidean_1761080164_9703	2	0	11
48	test_dev_user_final	20	0	1
49	test_dev_user_final	21	2	1
50	test_dev_user_final	22	1	1
51	test_dev_user_final	23	1	1
52	test_dev_user_final	24	0	1
53	test_dev_user_final	25	1	1
54	test_dev_user_final	26	0	1
55	test_dev_user_final	27	0	1
56	test_dev_user_final	28	0	1
57	test_dev_user_final	29	0	1
58	test_dev_user_final	30	0	1
59	phase1_temp_1761022046062_v7jottit1	1	0	15
60	phase1_temp_1761022046062_v7jottit1	2	0	15
61	phase1_temp_1761022046062_v7jottit1	3	0	15
62	phase1_temp_1761022046062_v7jottit1	4	0	15
63	phase1_temp_1761022046062_v7jottit1	5	0	15
64	phase1_temp_1761022046062_v7jottit1	6	0	15
65	phase1_temp_1761022046062_v7jottit1	7	0	15
66	phase1_temp_1761022046062_v7jottit1	8	0	15
67	phase1_temp_1761022046062_v7jottit1	9	0	15
68	phase1_temp_1761022046062_v7jottit1	10	0	15
69	phase1_temp_1761022046062_v7jottit1	11	0	15
70	phase1_temp_1761022046062_v7jottit1	12	0	15
71	phase1_temp_1761022046062_v7jottit1	13	0	15
72	phase1_temp_1761022046062_v7jottit1	14	0	15
73	phase1_temp_1761022046062_v7jottit1	15	0	15
74	phase1_temp_1761022046062_v7jottit1	16	0	15
75	phase1_temp_1761022046062_v7jottit1	17	0	15
76	phase1_temp_1761022046062_v7jottit1	18	1	15
77	phase1_temp_1761022046062_v7jottit1	19	2	15
78	phase1_temp_1761022046062_v7jottit1	20	0	15
79	phase1_temp_1761022046062_v7jottit1	21	0	15
80	phase1_temp_1761022046062_v7jottit1	22	0	15
81	phase1_temp_1761022046062_v7jottit1	23	0	15
82	phase1_temp_1761022046062_v7jottit1	24	0	15
83	phase1_temp_1761022046062_v7jottit1	25	2	15
84	phase1_temp_1761022046062_v7jottit1	26	0	15
85	phase1_temp_1761022046062_v7jottit1	27	0	15
86	phase1_temp_1761022046062_v7jottit1	28	0	15
87	phase1_temp_1761022046062_v7jottit1	29	0	15
88	phase1_temp_1761022046062_v7jottit1	30	0	15
89	phase1_temp_1761022051588_cv9cw1szj	1	0	15
90	phase1_temp_1761022051588_cv9cw1szj	2	0	15
91	phase1_temp_1761022051588_cv9cw1szj	3	0	15
92	phase1_temp_1761022051588_cv9cw1szj	4	0	15
93	phase1_temp_1761022051588_cv9cw1szj	5	0	15
94	phase1_temp_1761022051588_cv9cw1szj	6	0	15
95	phase1_temp_1761022051588_cv9cw1szj	7	0	15
96	phase1_temp_1761022051588_cv9cw1szj	8	2	15
97	phase1_temp_1761022051588_cv9cw1szj	9	2	15
98	phase1_temp_1761022051588_cv9cw1szj	10	1	15
99	phase1_temp_1761022051588_cv9cw1szj	11	2	15
100	phase1_temp_1761022051588_cv9cw1szj	12	0	15
101	phase1_temp_1761022051588_cv9cw1szj	13	1	15
102	phase1_temp_1761022051588_cv9cw1szj	14	0	15
103	phase1_temp_1761022051588_cv9cw1szj	15	0	15
104	phase1_temp_1761022051588_cv9cw1szj	16	0	15
105	phase1_temp_1761022051588_cv9cw1szj	17	0	15
106	phase1_temp_1761022051588_cv9cw1szj	18	0	15
107	phase1_temp_1761022051588_cv9cw1szj	19	0	15
108	phase1_temp_1761022051588_cv9cw1szj	20	0	15
109	phase1_temp_1761022051588_cv9cw1szj	21	0	15
110	phase1_temp_1761022051588_cv9cw1szj	22	0	15
19	test_dev_user	19	4	1
111	phase1_temp_1761022051588_cv9cw1szj	23	0	15
112	phase1_temp_1761022051588_cv9cw1szj	24	0	15
113	phase1_temp_1761022051588_cv9cw1szj	25	0	15
114	phase1_temp_1761022051588_cv9cw1szj	26	0	15
115	phase1_temp_1761022051588_cv9cw1szj	27	0	15
116	phase1_temp_1761022051588_cv9cw1szj	28	0	15
117	phase1_temp_1761022051588_cv9cw1szj	29	0	15
118	phase1_temp_1761022051588_cv9cw1szj	30	0	15
119	test_pm_user	1	0	1
120	test_pm_user	2	0	1
121	test_pm_user	3	0	1
122	test_pm_user	4	0	1
123	test_pm_user	5	0	1
124	test_pm_user	6	0	1
125	test_pm_user	7	0	1
126	test_pm_user	8	2	1
127	test_pm_user	9	1	1
128	test_pm_user	10	1	1
129	test_pm_user	11	2	1
130	test_pm_user	12	0	1
131	test_pm_user	13	0	1
132	test_pm_user	14	0	1
133	test_pm_user	15	0	1
134	test_pm_user	16	0	1
135	test_pm_user	17	0	1
136	test_pm_user	18	0	1
138	test_pm_user	20	0	1
139	test_pm_user	21	0	1
140	test_pm_user	22	0	1
141	test_pm_user	23	0	1
142	test_pm_user	24	0	1
143	test_pm_user	25	0	1
144	test_pm_user	26	0	1
145	test_pm_user	27	0	1
146	test_pm_user	28	0	1
147	test_pm_user	29	0	1
148	test_pm_user	30	0	1
149	phase1_temp_1761023242629_z1lje4wmy	1	0	15
150	phase1_temp_1761023242629_z1lje4wmy	2	0	15
151	phase1_temp_1761023242629_z1lje4wmy	3	0	15
152	phase1_temp_1761023242629_z1lje4wmy	4	0	15
153	phase1_temp_1761023242629_z1lje4wmy	5	0	15
154	phase1_temp_1761023242629_z1lje4wmy	6	0	15
155	phase1_temp_1761023242629_z1lje4wmy	7	0	15
156	phase1_temp_1761023242629_z1lje4wmy	8	0	15
157	phase1_temp_1761023242629_z1lje4wmy	9	0	15
158	phase1_temp_1761023242629_z1lje4wmy	10	0	15
159	phase1_temp_1761023242629_z1lje4wmy	11	0	15
160	phase1_temp_1761023242629_z1lje4wmy	12	0	15
161	phase1_temp_1761023242629_z1lje4wmy	13	0	15
162	phase1_temp_1761023242629_z1lje4wmy	14	0	15
163	phase1_temp_1761023242629_z1lje4wmy	15	0	15
164	phase1_temp_1761023242629_z1lje4wmy	16	0	15
165	phase1_temp_1761023242629_z1lje4wmy	17	0	15
166	phase1_temp_1761023242629_z1lje4wmy	18	1	15
167	phase1_temp_1761023242629_z1lje4wmy	19	2	15
168	phase1_temp_1761023242629_z1lje4wmy	20	0	15
169	phase1_temp_1761023242629_z1lje4wmy	21	0	15
170	phase1_temp_1761023242629_z1lje4wmy	22	0	15
171	phase1_temp_1761023242629_z1lje4wmy	23	2	15
172	phase1_temp_1761023242629_z1lje4wmy	24	0	15
173	phase1_temp_1761023242629_z1lje4wmy	25	2	15
174	phase1_temp_1761023242629_z1lje4wmy	26	0	15
175	phase1_temp_1761023242629_z1lje4wmy	27	0	15
176	phase1_temp_1761023242629_z1lje4wmy	28	0	15
177	phase1_temp_1761023242629_z1lje4wmy	29	0	15
178	phase1_temp_1761023242629_z1lje4wmy	30	0	15
179	phase1_temp_1761023558262_ktxyh5e7v	1	0	15
180	phase1_temp_1761023558262_ktxyh5e7v	2	0	15
181	phase1_temp_1761023558262_ktxyh5e7v	3	0	15
182	phase1_temp_1761023558262_ktxyh5e7v	4	0	15
183	phase1_temp_1761023558262_ktxyh5e7v	5	0	15
184	phase1_temp_1761023558262_ktxyh5e7v	6	0	15
185	phase1_temp_1761023558262_ktxyh5e7v	7	0	15
186	phase1_temp_1761023558262_ktxyh5e7v	8	0	15
187	phase1_temp_1761023558262_ktxyh5e7v	9	0	15
188	phase1_temp_1761023558262_ktxyh5e7v	10	0	15
189	phase1_temp_1761023558262_ktxyh5e7v	11	0	15
190	phase1_temp_1761023558262_ktxyh5e7v	12	0	15
191	phase1_temp_1761023558262_ktxyh5e7v	13	0	15
192	phase1_temp_1761023558262_ktxyh5e7v	14	0	15
193	phase1_temp_1761023558262_ktxyh5e7v	15	0	15
194	phase1_temp_1761023558262_ktxyh5e7v	16	0	15
195	phase1_temp_1761023558262_ktxyh5e7v	17	0	15
196	phase1_temp_1761023558262_ktxyh5e7v	18	1	15
197	phase1_temp_1761023558262_ktxyh5e7v	19	2	15
198	phase1_temp_1761023558262_ktxyh5e7v	20	0	15
199	phase1_temp_1761023558262_ktxyh5e7v	21	0	15
200	phase1_temp_1761023558262_ktxyh5e7v	22	0	15
201	phase1_temp_1761023558262_ktxyh5e7v	23	2	15
202	phase1_temp_1761023558262_ktxyh5e7v	24	0	15
203	phase1_temp_1761023558262_ktxyh5e7v	25	2	15
204	phase1_temp_1761023558262_ktxyh5e7v	26	0	15
205	phase1_temp_1761023558262_ktxyh5e7v	27	0	15
206	phase1_temp_1761023558262_ktxyh5e7v	28	0	15
207	phase1_temp_1761023558262_ktxyh5e7v	29	0	15
208	phase1_temp_1761023558262_ktxyh5e7v	30	0	15
209	phase1_temp_1761023785415_mly1fd5ro	1	0	15
210	phase1_temp_1761023785415_mly1fd5ro	2	0	15
211	phase1_temp_1761023785415_mly1fd5ro	3	0	15
212	phase1_temp_1761023785415_mly1fd5ro	4	0	15
213	phase1_temp_1761023785415_mly1fd5ro	5	0	15
214	phase1_temp_1761023785415_mly1fd5ro	6	0	15
215	phase1_temp_1761023785415_mly1fd5ro	7	0	15
137	test_pm_user	19	4	1
216	phase1_temp_1761023785415_mly1fd5ro	8	0	15
217	phase1_temp_1761023785415_mly1fd5ro	9	0	15
218	phase1_temp_1761023785415_mly1fd5ro	10	0	15
219	phase1_temp_1761023785415_mly1fd5ro	11	0	15
220	phase1_temp_1761023785415_mly1fd5ro	12	0	15
221	phase1_temp_1761023785415_mly1fd5ro	13	0	15
222	phase1_temp_1761023785415_mly1fd5ro	14	0	15
223	phase1_temp_1761023785415_mly1fd5ro	15	0	15
224	phase1_temp_1761023785415_mly1fd5ro	16	0	15
225	phase1_temp_1761023785415_mly1fd5ro	17	0	15
226	phase1_temp_1761023785415_mly1fd5ro	18	1	15
227	phase1_temp_1761023785415_mly1fd5ro	19	2	15
228	phase1_temp_1761023785415_mly1fd5ro	20	0	15
229	phase1_temp_1761023785415_mly1fd5ro	21	0	15
230	phase1_temp_1761023785415_mly1fd5ro	22	0	15
231	phase1_temp_1761023785415_mly1fd5ro	23	2	15
232	phase1_temp_1761023785415_mly1fd5ro	24	0	15
233	phase1_temp_1761023785415_mly1fd5ro	25	2	15
234	phase1_temp_1761023785415_mly1fd5ro	26	0	15
235	phase1_temp_1761023785415_mly1fd5ro	27	0	15
236	phase1_temp_1761023785415_mly1fd5ro	28	0	15
237	phase1_temp_1761023785415_mly1fd5ro	29	0	15
238	phase1_temp_1761023785415_mly1fd5ro	30	0	15
239	phase1_temp_1761024051893_qzgu7tktl	1	0	15
240	phase1_temp_1761024051893_qzgu7tktl	2	0	15
241	phase1_temp_1761024051893_qzgu7tktl	3	0	15
242	phase1_temp_1761024051893_qzgu7tktl	4	0	15
243	phase1_temp_1761024051893_qzgu7tktl	5	0	15
244	phase1_temp_1761024051893_qzgu7tktl	6	0	15
245	phase1_temp_1761024051893_qzgu7tktl	7	0	15
246	phase1_temp_1761024051893_qzgu7tktl	8	0	15
247	phase1_temp_1761024051893_qzgu7tktl	9	0	15
248	phase1_temp_1761024051893_qzgu7tktl	10	0	15
249	phase1_temp_1761024051893_qzgu7tktl	11	0	15
250	phase1_temp_1761024051893_qzgu7tktl	12	0	15
251	phase1_temp_1761024051893_qzgu7tktl	13	0	15
252	phase1_temp_1761024051893_qzgu7tktl	14	0	15
253	phase1_temp_1761024051893_qzgu7tktl	15	0	15
254	phase1_temp_1761024051893_qzgu7tktl	16	0	15
255	phase1_temp_1761024051893_qzgu7tktl	17	0	15
256	phase1_temp_1761024051893_qzgu7tktl	18	1	15
257	phase1_temp_1761024051893_qzgu7tktl	19	2	15
258	phase1_temp_1761024051893_qzgu7tktl	20	0	15
259	phase1_temp_1761024051893_qzgu7tktl	21	0	15
260	phase1_temp_1761024051893_qzgu7tktl	22	0	15
261	phase1_temp_1761024051893_qzgu7tktl	23	0	15
262	phase1_temp_1761024051893_qzgu7tktl	24	0	15
263	phase1_temp_1761024051893_qzgu7tktl	25	2	15
264	phase1_temp_1761024051893_qzgu7tktl	26	0	15
265	phase1_temp_1761024051893_qzgu7tktl	27	0	15
266	phase1_temp_1761024051893_qzgu7tktl	28	0	15
267	phase1_temp_1761024051893_qzgu7tktl	29	0	15
268	phase1_temp_1761024051893_qzgu7tktl	30	0	15
269	phase1_temp_1761057021036_74cqxdcfq	1	0	16
270	phase1_temp_1761057021036_74cqxdcfq	2	0	16
271	phase1_temp_1761057021036_74cqxdcfq	3	0	16
272	phase1_temp_1761057021036_74cqxdcfq	4	0	16
273	phase1_temp_1761057021036_74cqxdcfq	5	0	16
274	phase1_temp_1761057021036_74cqxdcfq	6	0	16
275	phase1_temp_1761057021036_74cqxdcfq	7	0	16
276	phase1_temp_1761057021036_74cqxdcfq	8	0	16
277	phase1_temp_1761057021036_74cqxdcfq	9	0	16
278	phase1_temp_1761057021036_74cqxdcfq	10	0	16
279	phase1_temp_1761057021036_74cqxdcfq	11	0	16
280	phase1_temp_1761057021036_74cqxdcfq	12	0	16
281	phase1_temp_1761057021036_74cqxdcfq	13	0	16
282	phase1_temp_1761057021036_74cqxdcfq	14	0	16
283	phase1_temp_1761057021036_74cqxdcfq	15	0	16
284	phase1_temp_1761057021036_74cqxdcfq	16	0	16
285	phase1_temp_1761057021036_74cqxdcfq	17	0	16
2749	test_llm_vs_euclidean_1761080164_9703	3	0	11
2750	test_llm_vs_euclidean_1761080164_9703	4	0	11
288	phase1_temp_1761057021036_74cqxdcfq	20	0	16
289	phase1_temp_1761057021036_74cqxdcfq	21	2	16
290	phase1_temp_1761057021036_74cqxdcfq	22	1	16
291	phase1_temp_1761057021036_74cqxdcfq	23	1	16
292	phase1_temp_1761057021036_74cqxdcfq	24	0	16
293	phase1_temp_1761057021036_74cqxdcfq	25	1	16
294	phase1_temp_1761057021036_74cqxdcfq	26	0	16
295	phase1_temp_1761057021036_74cqxdcfq	27	1	16
296	phase1_temp_1761057021036_74cqxdcfq	28	0	16
297	phase1_temp_1761057021036_74cqxdcfq	29	0	16
298	phase1_temp_1761057021036_74cqxdcfq	30	0	16
299	phase1_temp_1761057030704_hbwtow498	1	0	16
300	phase1_temp_1761057030704_hbwtow498	2	0	16
301	phase1_temp_1761057030704_hbwtow498	3	0	16
302	phase1_temp_1761057030704_hbwtow498	4	0	16
303	phase1_temp_1761057030704_hbwtow498	5	0	16
304	phase1_temp_1761057030704_hbwtow498	6	0	16
305	phase1_temp_1761057030704_hbwtow498	7	0	16
306	phase1_temp_1761057030704_hbwtow498	8	0	16
307	phase1_temp_1761057030704_hbwtow498	9	0	16
308	phase1_temp_1761057030704_hbwtow498	10	0	16
309	phase1_temp_1761057030704_hbwtow498	11	1	16
310	phase1_temp_1761057030704_hbwtow498	12	0	16
311	phase1_temp_1761057030704_hbwtow498	13	0	16
312	phase1_temp_1761057030704_hbwtow498	14	0	16
313	phase1_temp_1761057030704_hbwtow498	15	0	16
314	phase1_temp_1761057030704_hbwtow498	16	0	16
315	phase1_temp_1761057030704_hbwtow498	17	2	16
2751	test_llm_vs_euclidean_1761080164_9703	5	0	11
2752	test_llm_vs_euclidean_1761080164_9703	6	0	11
318	phase1_temp_1761057030704_hbwtow498	20	0	16
319	phase1_temp_1761057030704_hbwtow498	21	0	16
320	phase1_temp_1761057030704_hbwtow498	22	2	16
321	phase1_temp_1761057030704_hbwtow498	23	2	16
322	phase1_temp_1761057030704_hbwtow498	24	0	16
323	phase1_temp_1761057030704_hbwtow498	25	0	16
324	phase1_temp_1761057030704_hbwtow498	26	0	16
325	phase1_temp_1761057030704_hbwtow498	27	0	16
326	phase1_temp_1761057030704_hbwtow498	28	0	16
327	phase1_temp_1761057030704_hbwtow498	29	0	16
328	phase1_temp_1761057030704_hbwtow498	30	0	16
329	phase1_temp_1761057039476_g388bl1qc	1	0	16
330	phase1_temp_1761057039476_g388bl1qc	2	0	16
331	phase1_temp_1761057039476_g388bl1qc	3	0	16
332	phase1_temp_1761057039476_g388bl1qc	4	0	16
333	phase1_temp_1761057039476_g388bl1qc	5	0	16
334	phase1_temp_1761057039476_g388bl1qc	6	0	16
335	phase1_temp_1761057039476_g388bl1qc	7	2	16
336	phase1_temp_1761057039476_g388bl1qc	8	0	16
337	phase1_temp_1761057039476_g388bl1qc	9	1	16
338	phase1_temp_1761057039476_g388bl1qc	10	0	16
339	phase1_temp_1761057039476_g388bl1qc	11	0	16
340	phase1_temp_1761057039476_g388bl1qc	12	0	16
341	phase1_temp_1761057039476_g388bl1qc	13	0	16
342	phase1_temp_1761057039476_g388bl1qc	14	1	16
343	phase1_temp_1761057039476_g388bl1qc	15	0	16
344	phase1_temp_1761057039476_g388bl1qc	16	0	16
345	phase1_temp_1761057039476_g388bl1qc	17	0	16
346	phase1_temp_1761057039476_g388bl1qc	18	0	16
347	phase1_temp_1761057039476_g388bl1qc	19	0	16
348	phase1_temp_1761057039476_g388bl1qc	20	0	16
349	phase1_temp_1761057039476_g388bl1qc	21	0	16
350	phase1_temp_1761057039476_g388bl1qc	22	0	16
351	phase1_temp_1761057039476_g388bl1qc	23	2	16
352	phase1_temp_1761057039476_g388bl1qc	24	0	16
353	phase1_temp_1761057039476_g388bl1qc	25	2	16
354	phase1_temp_1761057039476_g388bl1qc	26	0	16
355	phase1_temp_1761057039476_g388bl1qc	27	0	16
356	phase1_temp_1761057039476_g388bl1qc	28	0	16
357	phase1_temp_1761057039476_g388bl1qc	29	0	16
358	phase1_temp_1761057039476_g388bl1qc	30	0	16
359	phase1_temp_1761057050092_048hecu33	1	0	16
360	phase1_temp_1761057050092_048hecu33	2	0	16
361	phase1_temp_1761057050092_048hecu33	3	0	16
362	phase1_temp_1761057050092_048hecu33	4	0	16
363	phase1_temp_1761057050092_048hecu33	5	0	16
364	phase1_temp_1761057050092_048hecu33	6	0	16
365	phase1_temp_1761057050092_048hecu33	7	0	16
366	phase1_temp_1761057050092_048hecu33	8	2	16
367	phase1_temp_1761057050092_048hecu33	9	2	16
368	phase1_temp_1761057050092_048hecu33	10	1	16
369	phase1_temp_1761057050092_048hecu33	11	2	16
370	phase1_temp_1761057050092_048hecu33	12	0	16
371	phase1_temp_1761057050092_048hecu33	13	0	16
372	phase1_temp_1761057050092_048hecu33	14	0	16
373	phase1_temp_1761057050092_048hecu33	15	0	16
374	phase1_temp_1761057050092_048hecu33	16	0	16
375	phase1_temp_1761057050092_048hecu33	17	0	16
376	phase1_temp_1761057050092_048hecu33	18	0	16
377	phase1_temp_1761057050092_048hecu33	19	0	16
378	phase1_temp_1761057050092_048hecu33	20	0	16
379	phase1_temp_1761057050092_048hecu33	21	0	16
380	phase1_temp_1761057050092_048hecu33	22	0	16
381	phase1_temp_1761057050092_048hecu33	23	0	16
382	phase1_temp_1761057050092_048hecu33	24	0	16
383	phase1_temp_1761057050092_048hecu33	25	0	16
384	phase1_temp_1761057050092_048hecu33	26	0	16
385	phase1_temp_1761057050092_048hecu33	27	0	16
386	phase1_temp_1761057050092_048hecu33	28	0	16
387	phase1_temp_1761057050092_048hecu33	29	0	16
388	phase1_temp_1761057050092_048hecu33	30	0	16
389	phase1_temp_1761057058677_i8goreoi3	1	0	16
390	phase1_temp_1761057058677_i8goreoi3	2	0	16
391	phase1_temp_1761057058677_i8goreoi3	3	0	16
392	phase1_temp_1761057058677_i8goreoi3	4	0	16
393	phase1_temp_1761057058677_i8goreoi3	5	0	16
394	phase1_temp_1761057058677_i8goreoi3	6	0	16
395	phase1_temp_1761057058677_i8goreoi3	7	0	16
396	phase1_temp_1761057058677_i8goreoi3	8	0	16
397	phase1_temp_1761057058677_i8goreoi3	9	0	16
398	phase1_temp_1761057058677_i8goreoi3	10	0	16
399	phase1_temp_1761057058677_i8goreoi3	11	0	16
400	phase1_temp_1761057058677_i8goreoi3	12	0	16
401	phase1_temp_1761057058677_i8goreoi3	13	0	16
402	phase1_temp_1761057058677_i8goreoi3	14	0	16
403	phase1_temp_1761057058677_i8goreoi3	15	0	16
404	phase1_temp_1761057058677_i8goreoi3	16	0	16
405	phase1_temp_1761057058677_i8goreoi3	17	0	16
406	phase1_temp_1761057058677_i8goreoi3	18	1	16
407	phase1_temp_1761057058677_i8goreoi3	19	2	16
408	phase1_temp_1761057058677_i8goreoi3	20	0	16
409	phase1_temp_1761057058677_i8goreoi3	21	0	16
410	phase1_temp_1761057058677_i8goreoi3	22	0	16
411	phase1_temp_1761057058677_i8goreoi3	23	2	16
412	phase1_temp_1761057058677_i8goreoi3	24	0	16
413	phase1_temp_1761057058677_i8goreoi3	25	2	16
414	phase1_temp_1761057058677_i8goreoi3	26	0	16
415	phase1_temp_1761057058677_i8goreoi3	27	0	16
416	phase1_temp_1761057058677_i8goreoi3	28	0	16
417	phase1_temp_1761057058677_i8goreoi3	29	0	16
418	phase1_temp_1761057058677_i8goreoi3	30	0	16
419	phase1_temp_1761058418802_i0r81j20u	1	0	16
420	phase1_temp_1761058418802_i0r81j20u	2	0	16
421	phase1_temp_1761058418802_i0r81j20u	3	0	16
422	phase1_temp_1761058418802_i0r81j20u	4	0	16
423	phase1_temp_1761058418802_i0r81j20u	5	0	16
424	phase1_temp_1761058418802_i0r81j20u	6	0	16
425	phase1_temp_1761058418802_i0r81j20u	7	0	16
426	phase1_temp_1761058418802_i0r81j20u	8	0	16
427	phase1_temp_1761058418802_i0r81j20u	9	0	16
428	phase1_temp_1761058418802_i0r81j20u	10	0	16
429	phase1_temp_1761058418802_i0r81j20u	11	0	16
430	phase1_temp_1761058418802_i0r81j20u	12	0	16
431	phase1_temp_1761058418802_i0r81j20u	13	0	16
432	phase1_temp_1761058418802_i0r81j20u	14	0	16
433	phase1_temp_1761058418802_i0r81j20u	15	0	16
434	phase1_temp_1761058418802_i0r81j20u	16	0	16
435	phase1_temp_1761058418802_i0r81j20u	17	0	16
2753	test_llm_vs_euclidean_1761080164_9703	7	0	11
2754	test_llm_vs_euclidean_1761080164_9703	8	0	11
438	phase1_temp_1761058418802_i0r81j20u	20	0	16
439	phase1_temp_1761058418802_i0r81j20u	21	2	16
440	phase1_temp_1761058418802_i0r81j20u	22	1	16
441	phase1_temp_1761058418802_i0r81j20u	23	1	16
442	phase1_temp_1761058418802_i0r81j20u	24	0	16
443	phase1_temp_1761058418802_i0r81j20u	25	1	16
444	phase1_temp_1761058418802_i0r81j20u	26	0	16
445	phase1_temp_1761058418802_i0r81j20u	27	1	16
446	phase1_temp_1761058418802_i0r81j20u	28	0	16
447	phase1_temp_1761058418802_i0r81j20u	29	0	16
448	phase1_temp_1761058418802_i0r81j20u	30	0	16
449	phase1_temp_1761058427860_w3j0i6ysi	1	0	16
450	phase1_temp_1761058427860_w3j0i6ysi	2	0	16
451	phase1_temp_1761058427860_w3j0i6ysi	3	0	16
452	phase1_temp_1761058427860_w3j0i6ysi	4	0	16
453	phase1_temp_1761058427860_w3j0i6ysi	5	0	16
454	phase1_temp_1761058427860_w3j0i6ysi	6	0	16
455	phase1_temp_1761058427860_w3j0i6ysi	7	0	16
456	phase1_temp_1761058427860_w3j0i6ysi	8	0	16
457	phase1_temp_1761058427860_w3j0i6ysi	9	0	16
458	phase1_temp_1761058427860_w3j0i6ysi	10	0	16
459	phase1_temp_1761058427860_w3j0i6ysi	11	0	16
460	phase1_temp_1761058427860_w3j0i6ysi	12	0	16
461	phase1_temp_1761058427860_w3j0i6ysi	13	0	16
462	phase1_temp_1761058427860_w3j0i6ysi	14	0	16
463	phase1_temp_1761058427860_w3j0i6ysi	15	0	16
464	phase1_temp_1761058427860_w3j0i6ysi	16	0	16
465	phase1_temp_1761058427860_w3j0i6ysi	17	0	16
466	phase1_temp_1761058427860_w3j0i6ysi	18	1	16
467	phase1_temp_1761058427860_w3j0i6ysi	19	2	16
468	phase1_temp_1761058427860_w3j0i6ysi	20	0	16
469	phase1_temp_1761058427860_w3j0i6ysi	21	0	16
470	phase1_temp_1761058427860_w3j0i6ysi	22	0	16
471	phase1_temp_1761058427860_w3j0i6ysi	23	1	16
472	phase1_temp_1761058427860_w3j0i6ysi	24	0	16
473	phase1_temp_1761058427860_w3j0i6ysi	25	2	16
474	phase1_temp_1761058427860_w3j0i6ysi	26	0	16
475	phase1_temp_1761058427860_w3j0i6ysi	27	0	16
476	phase1_temp_1761058427860_w3j0i6ysi	28	0	16
477	phase1_temp_1761058427860_w3j0i6ysi	29	0	16
478	phase1_temp_1761058427860_w3j0i6ysi	30	0	16
479	phase1_temp_1761058437297_6rn30413r	1	0	16
480	phase1_temp_1761058437297_6rn30413r	2	0	16
481	phase1_temp_1761058437297_6rn30413r	3	0	16
482	phase1_temp_1761058437297_6rn30413r	4	0	16
483	phase1_temp_1761058437297_6rn30413r	5	0	16
484	phase1_temp_1761058437297_6rn30413r	6	0	16
485	phase1_temp_1761058437297_6rn30413r	7	0	16
486	phase1_temp_1761058437297_6rn30413r	8	0	16
487	phase1_temp_1761058437297_6rn30413r	9	0	16
488	phase1_temp_1761058437297_6rn30413r	10	0	16
489	phase1_temp_1761058437297_6rn30413r	11	1	16
490	phase1_temp_1761058437297_6rn30413r	12	0	16
491	phase1_temp_1761058437297_6rn30413r	13	0	16
492	phase1_temp_1761058437297_6rn30413r	14	0	16
493	phase1_temp_1761058437297_6rn30413r	15	0	16
494	phase1_temp_1761058437297_6rn30413r	16	0	16
495	phase1_temp_1761058437297_6rn30413r	17	2	16
2755	test_llm_vs_euclidean_1761080164_9703	9	0	11
2756	test_llm_vs_euclidean_1761080164_9703	10	0	11
498	phase1_temp_1761058437297_6rn30413r	20	0	16
499	phase1_temp_1761058437297_6rn30413r	21	0	16
500	phase1_temp_1761058437297_6rn30413r	22	2	16
501	phase1_temp_1761058437297_6rn30413r	23	2	16
502	phase1_temp_1761058437297_6rn30413r	24	0	16
503	phase1_temp_1761058437297_6rn30413r	25	0	16
504	phase1_temp_1761058437297_6rn30413r	26	0	16
505	phase1_temp_1761058437297_6rn30413r	27	0	16
506	phase1_temp_1761058437297_6rn30413r	28	0	16
507	phase1_temp_1761058437297_6rn30413r	29	0	16
508	phase1_temp_1761058437297_6rn30413r	30	0	16
509	phase1_temp_1761058445927_ro8e19kc7	1	0	16
510	phase1_temp_1761058445927_ro8e19kc7	2	0	16
511	phase1_temp_1761058445927_ro8e19kc7	3	0	16
512	phase1_temp_1761058445927_ro8e19kc7	4	0	16
513	phase1_temp_1761058445927_ro8e19kc7	5	0	16
514	phase1_temp_1761058445927_ro8e19kc7	6	0	16
515	phase1_temp_1761058445927_ro8e19kc7	7	2	16
516	phase1_temp_1761058445927_ro8e19kc7	8	0	16
517	phase1_temp_1761058445927_ro8e19kc7	9	0	16
518	phase1_temp_1761058445927_ro8e19kc7	10	0	16
519	phase1_temp_1761058445927_ro8e19kc7	11	0	16
520	phase1_temp_1761058445927_ro8e19kc7	12	0	16
521	phase1_temp_1761058445927_ro8e19kc7	13	0	16
522	phase1_temp_1761058445927_ro8e19kc7	14	1	16
523	phase1_temp_1761058445927_ro8e19kc7	15	0	16
524	phase1_temp_1761058445927_ro8e19kc7	16	0	16
525	phase1_temp_1761058445927_ro8e19kc7	17	0	16
526	phase1_temp_1761058445927_ro8e19kc7	18	0	16
527	phase1_temp_1761058445927_ro8e19kc7	19	0	16
528	phase1_temp_1761058445927_ro8e19kc7	20	0	16
529	phase1_temp_1761058445927_ro8e19kc7	21	0	16
530	phase1_temp_1761058445927_ro8e19kc7	22	0	16
531	phase1_temp_1761058445927_ro8e19kc7	23	2	16
532	phase1_temp_1761058445927_ro8e19kc7	24	0	16
533	phase1_temp_1761058445927_ro8e19kc7	25	2	16
534	phase1_temp_1761058445927_ro8e19kc7	26	0	16
535	phase1_temp_1761058445927_ro8e19kc7	27	0	16
536	phase1_temp_1761058445927_ro8e19kc7	28	0	16
537	phase1_temp_1761058445927_ro8e19kc7	29	0	16
538	phase1_temp_1761058445927_ro8e19kc7	30	0	16
539	phase1_temp_1761058857887_jq1gjvhfe	1	0	16
540	phase1_temp_1761058857887_jq1gjvhfe	2	0	16
541	phase1_temp_1761058857887_jq1gjvhfe	3	0	16
542	phase1_temp_1761058857887_jq1gjvhfe	4	0	16
543	phase1_temp_1761058857887_jq1gjvhfe	5	0	16
544	phase1_temp_1761058857887_jq1gjvhfe	6	0	16
545	phase1_temp_1761058857887_jq1gjvhfe	7	0	16
546	phase1_temp_1761058857887_jq1gjvhfe	8	0	16
547	phase1_temp_1761058857887_jq1gjvhfe	9	0	16
548	phase1_temp_1761058857887_jq1gjvhfe	10	0	16
549	phase1_temp_1761058857887_jq1gjvhfe	11	0	16
550	phase1_temp_1761058857887_jq1gjvhfe	12	0	16
551	phase1_temp_1761058857887_jq1gjvhfe	13	0	16
552	phase1_temp_1761058857887_jq1gjvhfe	14	0	16
553	phase1_temp_1761058857887_jq1gjvhfe	15	0	16
554	phase1_temp_1761058857887_jq1gjvhfe	16	0	16
555	phase1_temp_1761058857887_jq1gjvhfe	17	0	16
2757	test_llm_vs_euclidean_1761080164_9703	11	1	11
2758	test_llm_vs_euclidean_1761080164_9703	12	0	11
558	phase1_temp_1761058857887_jq1gjvhfe	20	0	16
559	phase1_temp_1761058857887_jq1gjvhfe	21	2	16
560	phase1_temp_1761058857887_jq1gjvhfe	22	1	16
561	phase1_temp_1761058857887_jq1gjvhfe	23	1	16
562	phase1_temp_1761058857887_jq1gjvhfe	24	0	16
563	phase1_temp_1761058857887_jq1gjvhfe	25	1	16
564	phase1_temp_1761058857887_jq1gjvhfe	26	0	16
565	phase1_temp_1761058857887_jq1gjvhfe	27	1	16
566	phase1_temp_1761058857887_jq1gjvhfe	28	0	16
567	phase1_temp_1761058857887_jq1gjvhfe	29	0	16
568	phase1_temp_1761058857887_jq1gjvhfe	30	0	16
569	phase1_temp_1761058868486_76ngtoc35	1	0	16
570	phase1_temp_1761058868486_76ngtoc35	2	0	16
571	phase1_temp_1761058868486_76ngtoc35	3	0	16
572	phase1_temp_1761058868486_76ngtoc35	4	0	16
573	phase1_temp_1761058868486_76ngtoc35	5	0	16
574	phase1_temp_1761058868486_76ngtoc35	6	0	16
575	phase1_temp_1761058868486_76ngtoc35	7	0	16
576	phase1_temp_1761058868486_76ngtoc35	8	0	16
577	phase1_temp_1761058868486_76ngtoc35	9	0	16
578	phase1_temp_1761058868486_76ngtoc35	10	0	16
579	phase1_temp_1761058868486_76ngtoc35	11	0	16
580	phase1_temp_1761058868486_76ngtoc35	12	0	16
581	phase1_temp_1761058868486_76ngtoc35	13	0	16
582	phase1_temp_1761058868486_76ngtoc35	14	0	16
583	phase1_temp_1761058868486_76ngtoc35	15	0	16
584	phase1_temp_1761058868486_76ngtoc35	16	0	16
585	phase1_temp_1761058868486_76ngtoc35	17	0	16
586	phase1_temp_1761058868486_76ngtoc35	18	1	16
587	phase1_temp_1761058868486_76ngtoc35	19	2	16
588	phase1_temp_1761058868486_76ngtoc35	20	0	16
589	phase1_temp_1761058868486_76ngtoc35	21	0	16
590	phase1_temp_1761058868486_76ngtoc35	22	0	16
591	phase1_temp_1761058868486_76ngtoc35	23	0	16
592	phase1_temp_1761058868486_76ngtoc35	24	0	16
593	phase1_temp_1761058868486_76ngtoc35	25	2	16
594	phase1_temp_1761058868486_76ngtoc35	26	0	16
595	phase1_temp_1761058868486_76ngtoc35	27	0	16
596	phase1_temp_1761058868486_76ngtoc35	28	0	16
597	phase1_temp_1761058868486_76ngtoc35	29	0	16
598	phase1_temp_1761058868486_76ngtoc35	30	0	16
599	phase1_temp_1761058880386_uewnxr99n	1	0	16
600	phase1_temp_1761058880386_uewnxr99n	2	0	16
601	phase1_temp_1761058880386_uewnxr99n	3	0	16
602	phase1_temp_1761058880386_uewnxr99n	4	0	16
603	phase1_temp_1761058880386_uewnxr99n	5	0	16
604	phase1_temp_1761058880386_uewnxr99n	6	0	16
605	phase1_temp_1761058880386_uewnxr99n	7	0	16
606	phase1_temp_1761058880386_uewnxr99n	8	0	16
607	phase1_temp_1761058880386_uewnxr99n	9	0	16
608	phase1_temp_1761058880386_uewnxr99n	10	0	16
609	phase1_temp_1761058880386_uewnxr99n	11	1	16
610	phase1_temp_1761058880386_uewnxr99n	12	0	16
611	phase1_temp_1761058880386_uewnxr99n	13	0	16
612	phase1_temp_1761058880386_uewnxr99n	14	0	16
613	phase1_temp_1761058880386_uewnxr99n	15	0	16
614	phase1_temp_1761058880386_uewnxr99n	16	0	16
615	phase1_temp_1761058880386_uewnxr99n	17	2	16
2759	test_llm_vs_euclidean_1761080164_9703	13	0	11
2760	test_llm_vs_euclidean_1761080164_9703	14	0	11
618	phase1_temp_1761058880386_uewnxr99n	20	0	16
619	phase1_temp_1761058880386_uewnxr99n	21	0	16
620	phase1_temp_1761058880386_uewnxr99n	22	2	16
621	phase1_temp_1761058880386_uewnxr99n	23	2	16
622	phase1_temp_1761058880386_uewnxr99n	24	0	16
623	phase1_temp_1761058880386_uewnxr99n	25	0	16
624	phase1_temp_1761058880386_uewnxr99n	26	0	16
625	phase1_temp_1761058880386_uewnxr99n	27	0	16
626	phase1_temp_1761058880386_uewnxr99n	28	0	16
627	phase1_temp_1761058880386_uewnxr99n	29	0	16
628	phase1_temp_1761058880386_uewnxr99n	30	0	16
629	phase1_temp_1761058892469_dkvv4jw2w	1	0	16
630	phase1_temp_1761058892469_dkvv4jw2w	2	0	16
631	phase1_temp_1761058892469_dkvv4jw2w	3	0	16
632	phase1_temp_1761058892469_dkvv4jw2w	4	0	16
633	phase1_temp_1761058892469_dkvv4jw2w	5	0	16
634	phase1_temp_1761058892469_dkvv4jw2w	6	0	16
635	phase1_temp_1761058892469_dkvv4jw2w	7	2	16
636	phase1_temp_1761058892469_dkvv4jw2w	8	0	16
637	phase1_temp_1761058892469_dkvv4jw2w	9	1	16
638	phase1_temp_1761058892469_dkvv4jw2w	10	0	16
639	phase1_temp_1761058892469_dkvv4jw2w	11	0	16
640	phase1_temp_1761058892469_dkvv4jw2w	12	0	16
641	phase1_temp_1761058892469_dkvv4jw2w	13	0	16
642	phase1_temp_1761058892469_dkvv4jw2w	14	2	16
643	phase1_temp_1761058892469_dkvv4jw2w	15	0	16
644	phase1_temp_1761058892469_dkvv4jw2w	16	0	16
645	phase1_temp_1761058892469_dkvv4jw2w	17	0	16
646	phase1_temp_1761058892469_dkvv4jw2w	18	0	16
2761	test_llm_vs_euclidean_1761080164_9703	15	0	11
648	phase1_temp_1761058892469_dkvv4jw2w	20	0	16
649	phase1_temp_1761058892469_dkvv4jw2w	21	0	16
650	phase1_temp_1761058892469_dkvv4jw2w	22	0	16
651	phase1_temp_1761058892469_dkvv4jw2w	23	2	16
652	phase1_temp_1761058892469_dkvv4jw2w	24	0	16
653	phase1_temp_1761058892469_dkvv4jw2w	25	2	16
654	phase1_temp_1761058892469_dkvv4jw2w	26	0	16
655	phase1_temp_1761058892469_dkvv4jw2w	27	0	16
656	phase1_temp_1761058892469_dkvv4jw2w	28	0	16
657	phase1_temp_1761058892469_dkvv4jw2w	29	0	16
658	phase1_temp_1761058892469_dkvv4jw2w	30	0	16
659	phase1_temp_1761058904862_neaktu63o	1	0	16
660	phase1_temp_1761058904862_neaktu63o	2	0	16
661	phase1_temp_1761058904862_neaktu63o	3	0	16
662	phase1_temp_1761058904862_neaktu63o	4	0	16
663	phase1_temp_1761058904862_neaktu63o	5	0	16
664	phase1_temp_1761058904862_neaktu63o	6	0	16
665	phase1_temp_1761058904862_neaktu63o	7	0	16
666	phase1_temp_1761058904862_neaktu63o	8	2	16
667	phase1_temp_1761058904862_neaktu63o	9	2	16
668	phase1_temp_1761058904862_neaktu63o	10	1	16
669	phase1_temp_1761058904862_neaktu63o	11	2	16
670	phase1_temp_1761058904862_neaktu63o	12	0	16
671	phase1_temp_1761058904862_neaktu63o	13	1	16
672	phase1_temp_1761058904862_neaktu63o	14	0	16
673	phase1_temp_1761058904862_neaktu63o	15	0	16
674	phase1_temp_1761058904862_neaktu63o	16	1	16
675	phase1_temp_1761058904862_neaktu63o	17	0	16
676	phase1_temp_1761058904862_neaktu63o	18	0	16
677	phase1_temp_1761058904862_neaktu63o	19	0	16
678	phase1_temp_1761058904862_neaktu63o	20	0	16
679	phase1_temp_1761058904862_neaktu63o	21	0	16
680	phase1_temp_1761058904862_neaktu63o	22	0	16
681	phase1_temp_1761058904862_neaktu63o	23	0	16
682	phase1_temp_1761058904862_neaktu63o	24	0	16
683	phase1_temp_1761058904862_neaktu63o	25	0	16
684	phase1_temp_1761058904862_neaktu63o	26	0	16
685	phase1_temp_1761058904862_neaktu63o	27	0	16
686	phase1_temp_1761058904862_neaktu63o	28	0	16
687	phase1_temp_1761058904862_neaktu63o	29	0	16
688	phase1_temp_1761058904862_neaktu63o	30	0	16
689	phase1_temp_1761061461738_5nzjxk66a	1	0	16
690	phase1_temp_1761061461738_5nzjxk66a	2	0	16
691	phase1_temp_1761061461738_5nzjxk66a	3	0	16
692	phase1_temp_1761061461738_5nzjxk66a	4	0	16
693	phase1_temp_1761061461738_5nzjxk66a	5	0	16
694	phase1_temp_1761061461738_5nzjxk66a	6	0	16
695	phase1_temp_1761061461738_5nzjxk66a	7	0	16
696	phase1_temp_1761061461738_5nzjxk66a	8	0	16
697	phase1_temp_1761061461738_5nzjxk66a	9	0	16
698	phase1_temp_1761061461738_5nzjxk66a	10	0	16
699	phase1_temp_1761061461738_5nzjxk66a	11	0	16
700	phase1_temp_1761061461738_5nzjxk66a	12	0	16
701	phase1_temp_1761061461738_5nzjxk66a	13	0	16
702	phase1_temp_1761061461738_5nzjxk66a	14	0	16
703	phase1_temp_1761061461738_5nzjxk66a	15	0	16
704	phase1_temp_1761061461738_5nzjxk66a	16	0	16
705	phase1_temp_1761061461738_5nzjxk66a	17	0	16
2762	test_llm_vs_euclidean_1761080164_9703	16	1	11
2763	test_llm_vs_euclidean_1761080164_9703	17	1	11
708	phase1_temp_1761061461738_5nzjxk66a	20	0	16
709	phase1_temp_1761061461738_5nzjxk66a	21	2	16
710	phase1_temp_1761061461738_5nzjxk66a	22	1	16
711	phase1_temp_1761061461738_5nzjxk66a	23	1	16
712	phase1_temp_1761061461738_5nzjxk66a	24	0	16
713	phase1_temp_1761061461738_5nzjxk66a	25	0	16
714	phase1_temp_1761061461738_5nzjxk66a	26	0	16
715	phase1_temp_1761061461738_5nzjxk66a	27	1	16
716	phase1_temp_1761061461738_5nzjxk66a	28	0	16
717	phase1_temp_1761061461738_5nzjxk66a	29	0	16
718	phase1_temp_1761061461738_5nzjxk66a	30	0	16
719	phase1_temp_1761061469190_c1ndkxpzj	1	0	16
720	phase1_temp_1761061469190_c1ndkxpzj	2	0	16
721	phase1_temp_1761061469190_c1ndkxpzj	3	0	16
722	phase1_temp_1761061469190_c1ndkxpzj	4	0	16
723	phase1_temp_1761061469190_c1ndkxpzj	5	0	16
724	phase1_temp_1761061469190_c1ndkxpzj	6	0	16
725	phase1_temp_1761061469190_c1ndkxpzj	7	0	16
726	phase1_temp_1761061469190_c1ndkxpzj	8	0	16
727	phase1_temp_1761061469190_c1ndkxpzj	9	0	16
728	phase1_temp_1761061469190_c1ndkxpzj	10	0	16
729	phase1_temp_1761061469190_c1ndkxpzj	11	1	16
730	phase1_temp_1761061469190_c1ndkxpzj	12	0	16
731	phase1_temp_1761061469190_c1ndkxpzj	13	0	16
732	phase1_temp_1761061469190_c1ndkxpzj	14	0	16
733	phase1_temp_1761061469190_c1ndkxpzj	15	0	16
734	phase1_temp_1761061469190_c1ndkxpzj	16	2	16
735	phase1_temp_1761061469190_c1ndkxpzj	17	2	16
736	phase1_temp_1761061469190_c1ndkxpzj	18	1	16
2764	test_llm_vs_euclidean_1761080164_9703	18	1	11
738	phase1_temp_1761061469190_c1ndkxpzj	20	0	16
739	phase1_temp_1761061469190_c1ndkxpzj	21	0	16
740	phase1_temp_1761061469190_c1ndkxpzj	22	2	16
741	phase1_temp_1761061469190_c1ndkxpzj	23	2	16
742	phase1_temp_1761061469190_c1ndkxpzj	24	0	16
743	phase1_temp_1761061469190_c1ndkxpzj	25	0	16
744	phase1_temp_1761061469190_c1ndkxpzj	26	0	16
745	phase1_temp_1761061469190_c1ndkxpzj	27	0	16
746	phase1_temp_1761061469190_c1ndkxpzj	28	0	16
747	phase1_temp_1761061469190_c1ndkxpzj	29	0	16
748	phase1_temp_1761061469190_c1ndkxpzj	30	0	16
749	phase1_temp_1761061475576_eus6x8un3	1	0	16
750	phase1_temp_1761061475576_eus6x8un3	2	0	16
751	phase1_temp_1761061475576_eus6x8un3	3	0	16
752	phase1_temp_1761061475576_eus6x8un3	4	0	16
753	phase1_temp_1761061475576_eus6x8un3	5	0	16
754	phase1_temp_1761061475576_eus6x8un3	6	0	16
755	phase1_temp_1761061475576_eus6x8un3	7	2	16
756	phase1_temp_1761061475576_eus6x8un3	8	0	16
757	phase1_temp_1761061475576_eus6x8un3	9	1	16
758	phase1_temp_1761061475576_eus6x8un3	10	0	16
759	phase1_temp_1761061475576_eus6x8un3	11	0	16
760	phase1_temp_1761061475576_eus6x8un3	12	0	16
761	phase1_temp_1761061475576_eus6x8un3	13	0	16
762	phase1_temp_1761061475576_eus6x8un3	14	1	16
763	phase1_temp_1761061475576_eus6x8un3	15	0	16
764	phase1_temp_1761061475576_eus6x8un3	16	0	16
765	phase1_temp_1761061475576_eus6x8un3	17	0	16
766	phase1_temp_1761061475576_eus6x8un3	18	0	16
767	phase1_temp_1761061475576_eus6x8un3	19	0	16
768	phase1_temp_1761061475576_eus6x8un3	20	0	16
769	phase1_temp_1761061475576_eus6x8un3	21	0	16
770	phase1_temp_1761061475576_eus6x8un3	22	0	16
771	phase1_temp_1761061475576_eus6x8un3	23	2	16
772	phase1_temp_1761061475576_eus6x8un3	24	0	16
773	phase1_temp_1761061475576_eus6x8un3	25	2	16
774	phase1_temp_1761061475576_eus6x8un3	26	0	16
775	phase1_temp_1761061475576_eus6x8un3	27	0	16
776	phase1_temp_1761061475576_eus6x8un3	28	0	16
777	phase1_temp_1761061475576_eus6x8un3	29	0	16
778	phase1_temp_1761061475576_eus6x8un3	30	0	16
779	phase1_temp_1761061483959_7qkd7249m	1	0	16
780	phase1_temp_1761061483959_7qkd7249m	2	0	16
781	phase1_temp_1761061483959_7qkd7249m	3	0	16
782	phase1_temp_1761061483959_7qkd7249m	4	0	16
783	phase1_temp_1761061483959_7qkd7249m	5	0	16
784	phase1_temp_1761061483959_7qkd7249m	6	0	16
785	phase1_temp_1761061483959_7qkd7249m	7	0	16
786	phase1_temp_1761061483959_7qkd7249m	8	2	16
787	phase1_temp_1761061483959_7qkd7249m	9	2	16
788	phase1_temp_1761061483959_7qkd7249m	10	1	16
789	phase1_temp_1761061483959_7qkd7249m	11	2	16
790	phase1_temp_1761061483959_7qkd7249m	12	0	16
791	phase1_temp_1761061483959_7qkd7249m	13	1	16
792	phase1_temp_1761061483959_7qkd7249m	14	0	16
793	phase1_temp_1761061483959_7qkd7249m	15	0	16
794	phase1_temp_1761061483959_7qkd7249m	16	0	16
795	phase1_temp_1761061483959_7qkd7249m	17	0	16
796	phase1_temp_1761061483959_7qkd7249m	18	0	16
797	phase1_temp_1761061483959_7qkd7249m	19	0	16
798	phase1_temp_1761061483959_7qkd7249m	20	0	16
799	phase1_temp_1761061483959_7qkd7249m	21	0	16
800	phase1_temp_1761061483959_7qkd7249m	22	0	16
801	phase1_temp_1761061483959_7qkd7249m	23	0	16
802	phase1_temp_1761061483959_7qkd7249m	24	0	16
803	phase1_temp_1761061483959_7qkd7249m	25	0	16
804	phase1_temp_1761061483959_7qkd7249m	26	0	16
805	phase1_temp_1761061483959_7qkd7249m	27	0	16
806	phase1_temp_1761061483959_7qkd7249m	28	0	16
807	phase1_temp_1761061483959_7qkd7249m	29	0	16
808	phase1_temp_1761061483959_7qkd7249m	30	0	16
809	phase1_temp_1761061489973_pa2zogxxg	1	0	16
810	phase1_temp_1761061489973_pa2zogxxg	2	0	16
811	phase1_temp_1761061489973_pa2zogxxg	3	0	16
812	phase1_temp_1761061489973_pa2zogxxg	4	0	16
813	phase1_temp_1761061489973_pa2zogxxg	5	0	16
814	phase1_temp_1761061489973_pa2zogxxg	6	0	16
815	phase1_temp_1761061489973_pa2zogxxg	7	0	16
816	phase1_temp_1761061489973_pa2zogxxg	8	0	16
817	phase1_temp_1761061489973_pa2zogxxg	9	0	16
818	phase1_temp_1761061489973_pa2zogxxg	10	0	16
819	phase1_temp_1761061489973_pa2zogxxg	11	0	16
820	phase1_temp_1761061489973_pa2zogxxg	12	0	16
821	phase1_temp_1761061489973_pa2zogxxg	13	0	16
822	phase1_temp_1761061489973_pa2zogxxg	14	0	16
823	phase1_temp_1761061489973_pa2zogxxg	15	0	16
824	phase1_temp_1761061489973_pa2zogxxg	16	0	16
825	phase1_temp_1761061489973_pa2zogxxg	17	0	16
826	phase1_temp_1761061489973_pa2zogxxg	18	1	16
827	phase1_temp_1761061489973_pa2zogxxg	19	2	16
828	phase1_temp_1761061489973_pa2zogxxg	20	0	16
829	phase1_temp_1761061489973_pa2zogxxg	21	0	16
830	phase1_temp_1761061489973_pa2zogxxg	22	0	16
831	phase1_temp_1761061489973_pa2zogxxg	23	0	16
832	phase1_temp_1761061489973_pa2zogxxg	24	0	16
833	phase1_temp_1761061489973_pa2zogxxg	25	2	16
834	phase1_temp_1761061489973_pa2zogxxg	26	0	16
835	phase1_temp_1761061489973_pa2zogxxg	27	0	16
836	phase1_temp_1761061489973_pa2zogxxg	28	0	16
837	phase1_temp_1761061489973_pa2zogxxg	29	0	16
838	phase1_temp_1761061489973_pa2zogxxg	30	0	16
839	phase1_temp_1761062683560_lefw4cz6n	1	0	16
840	phase1_temp_1761062683560_lefw4cz6n	2	0	16
841	phase1_temp_1761062683560_lefw4cz6n	3	0	16
842	phase1_temp_1761062683560_lefw4cz6n	4	0	16
843	phase1_temp_1761062683560_lefw4cz6n	5	0	16
844	phase1_temp_1761062683560_lefw4cz6n	6	0	16
845	phase1_temp_1761062683560_lefw4cz6n	7	0	16
846	phase1_temp_1761062683560_lefw4cz6n	8	0	16
847	phase1_temp_1761062683560_lefw4cz6n	9	0	16
848	phase1_temp_1761062683560_lefw4cz6n	10	0	16
849	phase1_temp_1761062683560_lefw4cz6n	11	0	16
850	phase1_temp_1761062683560_lefw4cz6n	12	0	16
851	phase1_temp_1761062683560_lefw4cz6n	13	0	16
852	phase1_temp_1761062683560_lefw4cz6n	14	0	16
853	phase1_temp_1761062683560_lefw4cz6n	15	0	16
854	phase1_temp_1761062683560_lefw4cz6n	16	0	16
855	phase1_temp_1761062683560_lefw4cz6n	17	0	16
2765	test_llm_vs_euclidean_1761080164_9703	19	4	11
2766	test_llm_vs_euclidean_1761080164_9703	20	1	11
858	phase1_temp_1761062683560_lefw4cz6n	20	0	16
859	phase1_temp_1761062683560_lefw4cz6n	21	2	16
860	phase1_temp_1761062683560_lefw4cz6n	22	1	16
861	phase1_temp_1761062683560_lefw4cz6n	23	1	16
862	phase1_temp_1761062683560_lefw4cz6n	24	0	16
863	phase1_temp_1761062683560_lefw4cz6n	25	0	16
864	phase1_temp_1761062683560_lefw4cz6n	26	0	16
865	phase1_temp_1761062683560_lefw4cz6n	27	0	16
866	phase1_temp_1761062683560_lefw4cz6n	28	0	16
867	phase1_temp_1761062683560_lefw4cz6n	29	0	16
868	phase1_temp_1761062683560_lefw4cz6n	30	0	16
869	phase1_temp_1761062690705_zo4swt982	1	0	16
870	phase1_temp_1761062690705_zo4swt982	2	0	16
871	phase1_temp_1761062690705_zo4swt982	3	0	16
872	phase1_temp_1761062690705_zo4swt982	4	0	16
873	phase1_temp_1761062690705_zo4swt982	5	0	16
874	phase1_temp_1761062690705_zo4swt982	6	0	16
875	phase1_temp_1761062690705_zo4swt982	7	0	16
876	phase1_temp_1761062690705_zo4swt982	8	0	16
877	phase1_temp_1761062690705_zo4swt982	9	0	16
878	phase1_temp_1761062690705_zo4swt982	10	0	16
879	phase1_temp_1761062690705_zo4swt982	11	1	16
880	phase1_temp_1761062690705_zo4swt982	12	0	16
881	phase1_temp_1761062690705_zo4swt982	13	0	16
882	phase1_temp_1761062690705_zo4swt982	14	0	16
883	phase1_temp_1761062690705_zo4swt982	15	0	16
884	phase1_temp_1761062690705_zo4swt982	16	2	16
885	phase1_temp_1761062690705_zo4swt982	17	2	16
886	phase1_temp_1761062690705_zo4swt982	18	1	16
2767	test_llm_vs_euclidean_1761080164_9703	21	2	11
888	phase1_temp_1761062690705_zo4swt982	20	0	16
889	phase1_temp_1761062690705_zo4swt982	21	0	16
890	phase1_temp_1761062690705_zo4swt982	22	2	16
891	phase1_temp_1761062690705_zo4swt982	23	2	16
892	phase1_temp_1761062690705_zo4swt982	24	0	16
893	phase1_temp_1761062690705_zo4swt982	25	0	16
894	phase1_temp_1761062690705_zo4swt982	26	0	16
895	phase1_temp_1761062690705_zo4swt982	27	0	16
896	phase1_temp_1761062690705_zo4swt982	28	0	16
897	phase1_temp_1761062690705_zo4swt982	29	0	16
898	phase1_temp_1761062690705_zo4swt982	30	0	16
899	phase1_temp_1761062699334_gvxbn8cbb	1	0	16
900	phase1_temp_1761062699334_gvxbn8cbb	2	0	16
901	phase1_temp_1761062699334_gvxbn8cbb	3	0	16
902	phase1_temp_1761062699334_gvxbn8cbb	4	0	16
903	phase1_temp_1761062699334_gvxbn8cbb	5	0	16
904	phase1_temp_1761062699334_gvxbn8cbb	6	0	16
905	phase1_temp_1761062699334_gvxbn8cbb	7	2	16
906	phase1_temp_1761062699334_gvxbn8cbb	8	0	16
907	phase1_temp_1761062699334_gvxbn8cbb	9	1	16
908	phase1_temp_1761062699334_gvxbn8cbb	10	0	16
909	phase1_temp_1761062699334_gvxbn8cbb	11	0	16
910	phase1_temp_1761062699334_gvxbn8cbb	12	0	16
911	phase1_temp_1761062699334_gvxbn8cbb	13	0	16
912	phase1_temp_1761062699334_gvxbn8cbb	14	1	16
913	phase1_temp_1761062699334_gvxbn8cbb	15	0	16
914	phase1_temp_1761062699334_gvxbn8cbb	16	0	16
915	phase1_temp_1761062699334_gvxbn8cbb	17	0	16
916	phase1_temp_1761062699334_gvxbn8cbb	18	0	16
917	phase1_temp_1761062699334_gvxbn8cbb	19	0	16
918	phase1_temp_1761062699334_gvxbn8cbb	20	0	16
919	phase1_temp_1761062699334_gvxbn8cbb	21	0	16
920	phase1_temp_1761062699334_gvxbn8cbb	22	0	16
921	phase1_temp_1761062699334_gvxbn8cbb	23	2	16
922	phase1_temp_1761062699334_gvxbn8cbb	24	0	16
923	phase1_temp_1761062699334_gvxbn8cbb	25	2	16
924	phase1_temp_1761062699334_gvxbn8cbb	26	0	16
925	phase1_temp_1761062699334_gvxbn8cbb	27	0	16
926	phase1_temp_1761062699334_gvxbn8cbb	28	0	16
927	phase1_temp_1761062699334_gvxbn8cbb	29	0	16
928	phase1_temp_1761062699334_gvxbn8cbb	30	0	16
929	phase1_temp_1761062706216_f6ivgf8gv	1	0	16
930	phase1_temp_1761062706216_f6ivgf8gv	2	0	16
931	phase1_temp_1761062706216_f6ivgf8gv	3	0	16
932	phase1_temp_1761062706216_f6ivgf8gv	4	0	16
933	phase1_temp_1761062706216_f6ivgf8gv	5	0	16
934	phase1_temp_1761062706216_f6ivgf8gv	6	0	16
935	phase1_temp_1761062706216_f6ivgf8gv	7	0	16
936	phase1_temp_1761062706216_f6ivgf8gv	8	2	16
937	phase1_temp_1761062706216_f6ivgf8gv	9	2	16
938	phase1_temp_1761062706216_f6ivgf8gv	10	1	16
939	phase1_temp_1761062706216_f6ivgf8gv	11	2	16
940	phase1_temp_1761062706216_f6ivgf8gv	12	0	16
941	phase1_temp_1761062706216_f6ivgf8gv	13	0	16
942	phase1_temp_1761062706216_f6ivgf8gv	14	0	16
943	phase1_temp_1761062706216_f6ivgf8gv	15	0	16
944	phase1_temp_1761062706216_f6ivgf8gv	16	0	16
945	phase1_temp_1761062706216_f6ivgf8gv	17	0	16
946	phase1_temp_1761062706216_f6ivgf8gv	18	0	16
947	phase1_temp_1761062706216_f6ivgf8gv	19	0	16
948	phase1_temp_1761062706216_f6ivgf8gv	20	0	16
949	phase1_temp_1761062706216_f6ivgf8gv	21	0	16
950	phase1_temp_1761062706216_f6ivgf8gv	22	0	16
951	phase1_temp_1761062706216_f6ivgf8gv	23	0	16
952	phase1_temp_1761062706216_f6ivgf8gv	24	0	16
953	phase1_temp_1761062706216_f6ivgf8gv	25	0	16
954	phase1_temp_1761062706216_f6ivgf8gv	26	0	16
955	phase1_temp_1761062706216_f6ivgf8gv	27	0	16
956	phase1_temp_1761062706216_f6ivgf8gv	28	0	16
957	phase1_temp_1761062706216_f6ivgf8gv	29	0	16
958	phase1_temp_1761062706216_f6ivgf8gv	30	0	16
959	phase1_temp_1761062715043_q55x2575a	1	0	16
960	phase1_temp_1761062715043_q55x2575a	2	0	16
961	phase1_temp_1761062715043_q55x2575a	3	0	16
962	phase1_temp_1761062715043_q55x2575a	4	0	16
963	phase1_temp_1761062715043_q55x2575a	5	0	16
964	phase1_temp_1761062715043_q55x2575a	6	0	16
965	phase1_temp_1761062715043_q55x2575a	7	0	16
966	phase1_temp_1761062715043_q55x2575a	8	0	16
967	phase1_temp_1761062715043_q55x2575a	9	0	16
968	phase1_temp_1761062715043_q55x2575a	10	0	16
969	phase1_temp_1761062715043_q55x2575a	11	0	16
970	phase1_temp_1761062715043_q55x2575a	12	0	16
971	phase1_temp_1761062715043_q55x2575a	13	0	16
972	phase1_temp_1761062715043_q55x2575a	14	0	16
973	phase1_temp_1761062715043_q55x2575a	15	0	16
974	phase1_temp_1761062715043_q55x2575a	16	0	16
975	phase1_temp_1761062715043_q55x2575a	17	0	16
976	phase1_temp_1761062715043_q55x2575a	18	1	16
977	phase1_temp_1761062715043_q55x2575a	19	2	16
978	phase1_temp_1761062715043_q55x2575a	20	0	16
979	phase1_temp_1761062715043_q55x2575a	21	0	16
980	phase1_temp_1761062715043_q55x2575a	22	0	16
981	phase1_temp_1761062715043_q55x2575a	23	1	16
982	phase1_temp_1761062715043_q55x2575a	24	0	16
983	phase1_temp_1761062715043_q55x2575a	25	1	16
984	phase1_temp_1761062715043_q55x2575a	26	0	16
985	phase1_temp_1761062715043_q55x2575a	27	0	16
986	phase1_temp_1761062715043_q55x2575a	28	0	16
987	phase1_temp_1761062715043_q55x2575a	29	0	16
988	phase1_temp_1761062715043_q55x2575a	30	0	16
989	phase1_temp_1761063409422_4to8nfz47	1	0	16
990	phase1_temp_1761063409422_4to8nfz47	2	0	16
991	phase1_temp_1761063409422_4to8nfz47	3	0	16
992	phase1_temp_1761063409422_4to8nfz47	4	0	16
993	phase1_temp_1761063409422_4to8nfz47	5	0	16
994	phase1_temp_1761063409422_4to8nfz47	6	0	16
995	phase1_temp_1761063409422_4to8nfz47	7	0	16
996	phase1_temp_1761063409422_4to8nfz47	8	0	16
997	phase1_temp_1761063409422_4to8nfz47	9	0	16
998	phase1_temp_1761063409422_4to8nfz47	10	0	16
999	phase1_temp_1761063409422_4to8nfz47	11	0	16
1000	phase1_temp_1761063409422_4to8nfz47	12	0	16
1001	phase1_temp_1761063409422_4to8nfz47	13	0	16
1002	phase1_temp_1761063409422_4to8nfz47	14	0	16
1003	phase1_temp_1761063409422_4to8nfz47	15	0	16
1004	phase1_temp_1761063409422_4to8nfz47	16	0	16
1005	phase1_temp_1761063409422_4to8nfz47	17	0	16
1006	phase1_temp_1761063409422_4to8nfz47	18	1	16
1007	phase1_temp_1761063409422_4to8nfz47	19	2	16
1008	phase1_temp_1761063409422_4to8nfz47	20	0	16
1009	phase1_temp_1761063409422_4to8nfz47	21	0	16
1010	phase1_temp_1761063409422_4to8nfz47	22	0	16
1011	phase1_temp_1761063409422_4to8nfz47	23	0	16
1012	phase1_temp_1761063409422_4to8nfz47	24	0	16
1013	phase1_temp_1761063409422_4to8nfz47	25	2	16
1014	phase1_temp_1761063409422_4to8nfz47	26	0	16
1015	phase1_temp_1761063409422_4to8nfz47	27	0	16
1016	phase1_temp_1761063409422_4to8nfz47	28	0	16
1017	phase1_temp_1761063409422_4to8nfz47	29	0	16
1018	phase1_temp_1761063409422_4to8nfz47	30	0	16
1019	phase1_temp_1761063416296_9vtaktfao	1	0	16
1020	phase1_temp_1761063416296_9vtaktfao	2	0	16
1021	phase1_temp_1761063416296_9vtaktfao	3	0	16
1022	phase1_temp_1761063416296_9vtaktfao	4	0	16
1023	phase1_temp_1761063416296_9vtaktfao	5	0	16
1024	phase1_temp_1761063416296_9vtaktfao	6	0	16
1025	phase1_temp_1761063416296_9vtaktfao	7	0	16
1026	phase1_temp_1761063416296_9vtaktfao	8	2	16
1027	phase1_temp_1761063416296_9vtaktfao	9	2	16
1028	phase1_temp_1761063416296_9vtaktfao	10	1	16
1029	phase1_temp_1761063416296_9vtaktfao	11	2	16
1030	phase1_temp_1761063416296_9vtaktfao	12	0	16
1031	phase1_temp_1761063416296_9vtaktfao	13	0	16
1032	phase1_temp_1761063416296_9vtaktfao	14	0	16
1033	phase1_temp_1761063416296_9vtaktfao	15	0	16
1034	phase1_temp_1761063416296_9vtaktfao	16	0	16
1035	phase1_temp_1761063416296_9vtaktfao	17	0	16
1036	phase1_temp_1761063416296_9vtaktfao	18	0	16
1037	phase1_temp_1761063416296_9vtaktfao	19	0	16
1038	phase1_temp_1761063416296_9vtaktfao	20	0	16
1039	phase1_temp_1761063416296_9vtaktfao	21	0	16
1040	phase1_temp_1761063416296_9vtaktfao	22	0	16
1041	phase1_temp_1761063416296_9vtaktfao	23	0	16
1042	phase1_temp_1761063416296_9vtaktfao	24	0	16
1043	phase1_temp_1761063416296_9vtaktfao	25	0	16
1044	phase1_temp_1761063416296_9vtaktfao	26	0	16
1045	phase1_temp_1761063416296_9vtaktfao	27	0	16
1046	phase1_temp_1761063416296_9vtaktfao	28	0	16
1047	phase1_temp_1761063416296_9vtaktfao	29	0	16
1048	phase1_temp_1761063416296_9vtaktfao	30	0	16
1049	phase1_temp_1761063421806_leanyldrm	1	0	16
1050	phase1_temp_1761063421806_leanyldrm	2	0	16
1051	phase1_temp_1761063421806_leanyldrm	3	0	16
1052	phase1_temp_1761063421806_leanyldrm	4	0	16
1053	phase1_temp_1761063421806_leanyldrm	5	0	16
1054	phase1_temp_1761063421806_leanyldrm	6	0	16
1055	phase1_temp_1761063421806_leanyldrm	7	2	16
1056	phase1_temp_1761063421806_leanyldrm	8	0	16
1057	phase1_temp_1761063421806_leanyldrm	9	0	16
1058	phase1_temp_1761063421806_leanyldrm	10	0	16
1059	phase1_temp_1761063421806_leanyldrm	11	0	16
1060	phase1_temp_1761063421806_leanyldrm	12	0	16
1061	phase1_temp_1761063421806_leanyldrm	13	0	16
1062	phase1_temp_1761063421806_leanyldrm	14	1	16
1063	phase1_temp_1761063421806_leanyldrm	15	0	16
1064	phase1_temp_1761063421806_leanyldrm	16	0	16
1065	phase1_temp_1761063421806_leanyldrm	17	0	16
1066	phase1_temp_1761063421806_leanyldrm	18	0	16
1067	phase1_temp_1761063421806_leanyldrm	19	0	16
1068	phase1_temp_1761063421806_leanyldrm	20	0	16
1069	phase1_temp_1761063421806_leanyldrm	21	0	16
1070	phase1_temp_1761063421806_leanyldrm	22	0	16
1071	phase1_temp_1761063421806_leanyldrm	23	2	16
1072	phase1_temp_1761063421806_leanyldrm	24	0	16
1073	phase1_temp_1761063421806_leanyldrm	25	2	16
1074	phase1_temp_1761063421806_leanyldrm	26	0	16
1075	phase1_temp_1761063421806_leanyldrm	27	0	16
1076	phase1_temp_1761063421806_leanyldrm	28	0	16
1077	phase1_temp_1761063421806_leanyldrm	29	0	16
1078	phase1_temp_1761063421806_leanyldrm	30	0	16
1079	phase1_temp_1761063428009_9w44gmbtu	1	0	16
1080	phase1_temp_1761063428009_9w44gmbtu	2	0	16
1081	phase1_temp_1761063428009_9w44gmbtu	3	0	16
1082	phase1_temp_1761063428009_9w44gmbtu	4	0	16
1083	phase1_temp_1761063428009_9w44gmbtu	5	0	16
1084	phase1_temp_1761063428009_9w44gmbtu	6	0	16
1085	phase1_temp_1761063428009_9w44gmbtu	7	0	16
1086	phase1_temp_1761063428009_9w44gmbtu	8	0	16
1087	phase1_temp_1761063428009_9w44gmbtu	9	0	16
1088	phase1_temp_1761063428009_9w44gmbtu	10	0	16
1089	phase1_temp_1761063428009_9w44gmbtu	11	1	16
1090	phase1_temp_1761063428009_9w44gmbtu	12	0	16
1091	phase1_temp_1761063428009_9w44gmbtu	13	0	16
1092	phase1_temp_1761063428009_9w44gmbtu	14	0	16
1093	phase1_temp_1761063428009_9w44gmbtu	15	0	16
1094	phase1_temp_1761063428009_9w44gmbtu	16	2	16
1095	phase1_temp_1761063428009_9w44gmbtu	17	2	16
2768	test_llm_vs_euclidean_1761080164_9703	22	0	11
1097	phase1_temp_1761063428009_9w44gmbtu	19	0	16
1098	phase1_temp_1761063428009_9w44gmbtu	20	0	16
1099	phase1_temp_1761063428009_9w44gmbtu	21	2	16
1100	phase1_temp_1761063428009_9w44gmbtu	22	2	16
1101	phase1_temp_1761063428009_9w44gmbtu	23	2	16
1102	phase1_temp_1761063428009_9w44gmbtu	24	0	16
1103	phase1_temp_1761063428009_9w44gmbtu	25	0	16
1104	phase1_temp_1761063428009_9w44gmbtu	26	0	16
1105	phase1_temp_1761063428009_9w44gmbtu	27	0	16
1106	phase1_temp_1761063428009_9w44gmbtu	28	0	16
1107	phase1_temp_1761063428009_9w44gmbtu	29	0	16
1108	phase1_temp_1761063428009_9w44gmbtu	30	0	16
1109	phase1_temp_1761063435278_hp7acer76	1	0	16
1110	phase1_temp_1761063435278_hp7acer76	2	0	16
1111	phase1_temp_1761063435278_hp7acer76	3	0	16
1112	phase1_temp_1761063435278_hp7acer76	4	0	16
1113	phase1_temp_1761063435278_hp7acer76	5	0	16
1114	phase1_temp_1761063435278_hp7acer76	6	0	16
1115	phase1_temp_1761063435278_hp7acer76	7	0	16
1116	phase1_temp_1761063435278_hp7acer76	8	0	16
1117	phase1_temp_1761063435278_hp7acer76	9	0	16
1118	phase1_temp_1761063435278_hp7acer76	10	0	16
1119	phase1_temp_1761063435278_hp7acer76	11	0	16
1120	phase1_temp_1761063435278_hp7acer76	12	0	16
1121	phase1_temp_1761063435278_hp7acer76	13	0	16
1122	phase1_temp_1761063435278_hp7acer76	14	0	16
1123	phase1_temp_1761063435278_hp7acer76	15	0	16
1124	phase1_temp_1761063435278_hp7acer76	16	0	16
1125	phase1_temp_1761063435278_hp7acer76	17	0	16
2769	test_llm_vs_euclidean_1761080164_9703	23	0	11
2770	test_llm_vs_euclidean_1761080164_9703	24	0	11
1128	phase1_temp_1761063435278_hp7acer76	20	0	16
1129	phase1_temp_1761063435278_hp7acer76	21	2	16
1130	phase1_temp_1761063435278_hp7acer76	22	1	16
1131	phase1_temp_1761063435278_hp7acer76	23	1	16
1132	phase1_temp_1761063435278_hp7acer76	24	0	16
1133	phase1_temp_1761063435278_hp7acer76	25	0	16
1134	phase1_temp_1761063435278_hp7acer76	26	0	16
1135	phase1_temp_1761063435278_hp7acer76	27	0	16
1136	phase1_temp_1761063435278_hp7acer76	28	0	16
1137	phase1_temp_1761063435278_hp7acer76	29	0	16
1138	phase1_temp_1761063435278_hp7acer76	30	0	16
1139	phase1_temp_1761064141578_pup8hlew7	1	0	16
1140	phase1_temp_1761064141578_pup8hlew7	2	0	16
1141	phase1_temp_1761064141578_pup8hlew7	3	0	16
1142	phase1_temp_1761064141578_pup8hlew7	4	0	16
1143	phase1_temp_1761064141578_pup8hlew7	5	0	16
1144	phase1_temp_1761064141578_pup8hlew7	6	0	16
1145	phase1_temp_1761064141578_pup8hlew7	7	0	16
1146	phase1_temp_1761064141578_pup8hlew7	8	0	16
1147	phase1_temp_1761064141578_pup8hlew7	9	0	16
1148	phase1_temp_1761064141578_pup8hlew7	10	0	16
1149	phase1_temp_1761064141578_pup8hlew7	11	0	16
1150	phase1_temp_1761064141578_pup8hlew7	12	0	16
1151	phase1_temp_1761064141578_pup8hlew7	13	0	16
1152	phase1_temp_1761064141578_pup8hlew7	14	0	16
1153	phase1_temp_1761064141578_pup8hlew7	15	0	16
1154	phase1_temp_1761064141578_pup8hlew7	16	0	16
1155	phase1_temp_1761064141578_pup8hlew7	17	0	16
2771	test_llm_vs_euclidean_1761080164_9703	25	0	11
2772	test_llm_vs_euclidean_1761080164_9703	26	0	11
1158	phase1_temp_1761064141578_pup8hlew7	20	0	16
1159	phase1_temp_1761064141578_pup8hlew7	21	2	16
1160	phase1_temp_1761064141578_pup8hlew7	22	1	16
1161	phase1_temp_1761064141578_pup8hlew7	23	1	16
1162	phase1_temp_1761064141578_pup8hlew7	24	0	16
1163	phase1_temp_1761064141578_pup8hlew7	25	0	16
1164	phase1_temp_1761064141578_pup8hlew7	26	0	16
1165	phase1_temp_1761064141578_pup8hlew7	27	0	16
1166	phase1_temp_1761064141578_pup8hlew7	28	0	16
1167	phase1_temp_1761064141578_pup8hlew7	29	0	16
1168	phase1_temp_1761064141578_pup8hlew7	30	0	16
1169	phase1_temp_1761064149514_9taacpaas	1	0	16
1170	phase1_temp_1761064149514_9taacpaas	2	0	16
1171	phase1_temp_1761064149514_9taacpaas	3	0	16
1172	phase1_temp_1761064149514_9taacpaas	4	0	16
1173	phase1_temp_1761064149514_9taacpaas	5	0	16
1174	phase1_temp_1761064149514_9taacpaas	6	0	16
1175	phase1_temp_1761064149514_9taacpaas	7	0	16
1176	phase1_temp_1761064149514_9taacpaas	8	0	16
1177	phase1_temp_1761064149514_9taacpaas	9	0	16
1178	phase1_temp_1761064149514_9taacpaas	10	0	16
1179	phase1_temp_1761064149514_9taacpaas	11	1	16
1180	phase1_temp_1761064149514_9taacpaas	12	0	16
1181	phase1_temp_1761064149514_9taacpaas	13	0	16
1182	phase1_temp_1761064149514_9taacpaas	14	0	16
1183	phase1_temp_1761064149514_9taacpaas	15	0	16
1184	phase1_temp_1761064149514_9taacpaas	16	0	16
1185	phase1_temp_1761064149514_9taacpaas	17	2	16
2773	test_llm_vs_euclidean_1761080164_9703	27	0	11
2774	test_llm_vs_euclidean_1761080164_9703	28	0	11
1188	phase1_temp_1761064149514_9taacpaas	20	0	16
1189	phase1_temp_1761064149514_9taacpaas	21	0	16
1190	phase1_temp_1761064149514_9taacpaas	22	2	16
1191	phase1_temp_1761064149514_9taacpaas	23	2	16
1192	phase1_temp_1761064149514_9taacpaas	24	0	16
1193	phase1_temp_1761064149514_9taacpaas	25	0	16
1194	phase1_temp_1761064149514_9taacpaas	26	0	16
1195	phase1_temp_1761064149514_9taacpaas	27	0	16
1196	phase1_temp_1761064149514_9taacpaas	28	0	16
1197	phase1_temp_1761064149514_9taacpaas	29	0	16
1198	phase1_temp_1761064149514_9taacpaas	30	0	16
1199	phase1_temp_1761064157722_qm1j25eg0	1	0	16
1200	phase1_temp_1761064157722_qm1j25eg0	2	0	16
1201	phase1_temp_1761064157722_qm1j25eg0	3	0	16
1202	phase1_temp_1761064157722_qm1j25eg0	4	0	16
1203	phase1_temp_1761064157722_qm1j25eg0	5	0	16
1204	phase1_temp_1761064157722_qm1j25eg0	6	0	16
1205	phase1_temp_1761064157722_qm1j25eg0	7	2	16
1206	phase1_temp_1761064157722_qm1j25eg0	8	0	16
1207	phase1_temp_1761064157722_qm1j25eg0	9	1	16
1208	phase1_temp_1761064157722_qm1j25eg0	10	0	16
1209	phase1_temp_1761064157722_qm1j25eg0	11	0	16
1210	phase1_temp_1761064157722_qm1j25eg0	12	0	16
1211	phase1_temp_1761064157722_qm1j25eg0	13	0	16
1212	phase1_temp_1761064157722_qm1j25eg0	14	1	16
1213	phase1_temp_1761064157722_qm1j25eg0	15	0	16
1214	phase1_temp_1761064157722_qm1j25eg0	16	0	16
1215	phase1_temp_1761064157722_qm1j25eg0	17	0	16
1216	phase1_temp_1761064157722_qm1j25eg0	18	0	16
2775	test_llm_vs_euclidean_1761080164_9703	29	0	11
1218	phase1_temp_1761064157722_qm1j25eg0	20	0	16
1219	phase1_temp_1761064157722_qm1j25eg0	21	0	16
1220	phase1_temp_1761064157722_qm1j25eg0	22	0	16
1221	phase1_temp_1761064157722_qm1j25eg0	23	2	16
1222	phase1_temp_1761064157722_qm1j25eg0	24	0	16
1223	phase1_temp_1761064157722_qm1j25eg0	25	2	16
1224	phase1_temp_1761064157722_qm1j25eg0	26	0	16
1225	phase1_temp_1761064157722_qm1j25eg0	27	0	16
1226	phase1_temp_1761064157722_qm1j25eg0	28	0	16
1227	phase1_temp_1761064157722_qm1j25eg0	29	0	16
1228	phase1_temp_1761064157722_qm1j25eg0	30	0	16
1229	phase1_temp_1761064164058_flphdqg5d	1	0	16
1230	phase1_temp_1761064164058_flphdqg5d	2	0	16
1231	phase1_temp_1761064164058_flphdqg5d	3	0	16
1232	phase1_temp_1761064164058_flphdqg5d	4	0	16
1233	phase1_temp_1761064164058_flphdqg5d	5	0	16
1234	phase1_temp_1761064164058_flphdqg5d	6	0	16
1235	phase1_temp_1761064164058_flphdqg5d	7	0	16
1236	phase1_temp_1761064164058_flphdqg5d	8	2	16
1237	phase1_temp_1761064164058_flphdqg5d	9	2	16
1238	phase1_temp_1761064164058_flphdqg5d	10	1	16
1239	phase1_temp_1761064164058_flphdqg5d	11	2	16
1240	phase1_temp_1761064164058_flphdqg5d	12	0	16
1241	phase1_temp_1761064164058_flphdqg5d	13	0	16
1242	phase1_temp_1761064164058_flphdqg5d	14	0	16
1243	phase1_temp_1761064164058_flphdqg5d	15	0	16
1244	phase1_temp_1761064164058_flphdqg5d	16	0	16
1245	phase1_temp_1761064164058_flphdqg5d	17	0	16
1246	phase1_temp_1761064164058_flphdqg5d	18	0	16
1247	phase1_temp_1761064164058_flphdqg5d	19	0	16
1248	phase1_temp_1761064164058_flphdqg5d	20	0	16
1249	phase1_temp_1761064164058_flphdqg5d	21	0	16
1250	phase1_temp_1761064164058_flphdqg5d	22	0	16
1251	phase1_temp_1761064164058_flphdqg5d	23	0	16
1252	phase1_temp_1761064164058_flphdqg5d	24	0	16
1253	phase1_temp_1761064164058_flphdqg5d	25	0	16
1254	phase1_temp_1761064164058_flphdqg5d	26	0	16
1255	phase1_temp_1761064164058_flphdqg5d	27	0	16
1256	phase1_temp_1761064164058_flphdqg5d	28	0	16
1257	phase1_temp_1761064164058_flphdqg5d	29	0	16
1258	phase1_temp_1761064164058_flphdqg5d	30	0	16
1259	phase1_temp_1761064170989_4jumw966c	1	0	16
1260	phase1_temp_1761064170989_4jumw966c	2	0	16
1261	phase1_temp_1761064170989_4jumw966c	3	0	16
1262	phase1_temp_1761064170989_4jumw966c	4	0	16
1263	phase1_temp_1761064170989_4jumw966c	5	0	16
1264	phase1_temp_1761064170989_4jumw966c	6	0	16
1265	phase1_temp_1761064170989_4jumw966c	7	0	16
1266	phase1_temp_1761064170989_4jumw966c	8	0	16
1267	phase1_temp_1761064170989_4jumw966c	9	0	16
1268	phase1_temp_1761064170989_4jumw966c	10	0	16
1269	phase1_temp_1761064170989_4jumw966c	11	0	16
1270	phase1_temp_1761064170989_4jumw966c	12	0	16
1271	phase1_temp_1761064170989_4jumw966c	13	0	16
1272	phase1_temp_1761064170989_4jumw966c	14	0	16
1273	phase1_temp_1761064170989_4jumw966c	15	0	16
1274	phase1_temp_1761064170989_4jumw966c	16	0	16
1275	phase1_temp_1761064170989_4jumw966c	17	0	16
1276	phase1_temp_1761064170989_4jumw966c	18	1	16
2776	test_llm_vs_euclidean_1761080164_9703	30	0	11
1278	phase1_temp_1761064170989_4jumw966c	20	0	16
1279	phase1_temp_1761064170989_4jumw966c	21	0	16
1280	phase1_temp_1761064170989_4jumw966c	22	0	16
1281	phase1_temp_1761064170989_4jumw966c	23	2	16
1282	phase1_temp_1761064170989_4jumw966c	24	0	16
1283	phase1_temp_1761064170989_4jumw966c	25	2	16
1284	phase1_temp_1761064170989_4jumw966c	26	0	16
1285	phase1_temp_1761064170989_4jumw966c	27	0	16
1286	phase1_temp_1761064170989_4jumw966c	28	0	16
1287	phase1_temp_1761064170989_4jumw966c	29	0	16
1288	phase1_temp_1761064170989_4jumw966c	30	0	16
1289	phase1_temp_1761064575744_haxprvrhs	1	0	16
1290	phase1_temp_1761064575744_haxprvrhs	2	0	16
1291	phase1_temp_1761064575744_haxprvrhs	3	0	16
1292	phase1_temp_1761064575744_haxprvrhs	4	0	16
1293	phase1_temp_1761064575744_haxprvrhs	5	0	16
1294	phase1_temp_1761064575744_haxprvrhs	6	0	16
1295	phase1_temp_1761064575744_haxprvrhs	7	0	16
1296	phase1_temp_1761064575744_haxprvrhs	8	0	16
1297	phase1_temp_1761064575744_haxprvrhs	9	0	16
1298	phase1_temp_1761064575744_haxprvrhs	10	0	16
1299	phase1_temp_1761064575744_haxprvrhs	11	0	16
1300	phase1_temp_1761064575744_haxprvrhs	12	0	16
1301	phase1_temp_1761064575744_haxprvrhs	13	0	16
1302	phase1_temp_1761064575744_haxprvrhs	14	0	16
1303	phase1_temp_1761064575744_haxprvrhs	15	0	16
1304	phase1_temp_1761064575744_haxprvrhs	16	0	16
1305	phase1_temp_1761064575744_haxprvrhs	17	1	16
2777	test_llm_vs_euclidean_1761080185_9069	1	0	11
2778	test_llm_vs_euclidean_1761080185_9069	2	0	11
1308	phase1_temp_1761064575744_haxprvrhs	20	0	16
1309	phase1_temp_1761064575744_haxprvrhs	21	2	16
1310	phase1_temp_1761064575744_haxprvrhs	22	1	16
1311	phase1_temp_1761064575744_haxprvrhs	23	1	16
1312	phase1_temp_1761064575744_haxprvrhs	24	0	16
1313	phase1_temp_1761064575744_haxprvrhs	25	0	16
1314	phase1_temp_1761064575744_haxprvrhs	26	0	16
1315	phase1_temp_1761064575744_haxprvrhs	27	1	16
1316	phase1_temp_1761064575744_haxprvrhs	28	0	16
1317	phase1_temp_1761064575744_haxprvrhs	29	0	16
1318	phase1_temp_1761064575744_haxprvrhs	30	0	16
1319	phase1_temp_1761064584793_myi9fjk1m	1	0	16
1320	phase1_temp_1761064584793_myi9fjk1m	2	0	16
1321	phase1_temp_1761064584793_myi9fjk1m	3	0	16
1322	phase1_temp_1761064584793_myi9fjk1m	4	0	16
1323	phase1_temp_1761064584793_myi9fjk1m	5	0	16
1324	phase1_temp_1761064584793_myi9fjk1m	6	0	16
1325	phase1_temp_1761064584793_myi9fjk1m	7	0	16
1326	phase1_temp_1761064584793_myi9fjk1m	8	0	16
1327	phase1_temp_1761064584793_myi9fjk1m	9	0	16
1328	phase1_temp_1761064584793_myi9fjk1m	10	0	16
1329	phase1_temp_1761064584793_myi9fjk1m	11	1	16
1330	phase1_temp_1761064584793_myi9fjk1m	12	0	16
1331	phase1_temp_1761064584793_myi9fjk1m	13	0	16
1332	phase1_temp_1761064584793_myi9fjk1m	14	0	16
1333	phase1_temp_1761064584793_myi9fjk1m	15	0	16
1334	phase1_temp_1761064584793_myi9fjk1m	16	2	16
1335	phase1_temp_1761064584793_myi9fjk1m	17	2	16
1336	phase1_temp_1761064584793_myi9fjk1m	18	1	16
2779	test_llm_vs_euclidean_1761080185_9069	3	0	11
1338	phase1_temp_1761064584793_myi9fjk1m	20	0	16
1339	phase1_temp_1761064584793_myi9fjk1m	21	2	16
1340	phase1_temp_1761064584793_myi9fjk1m	22	2	16
1341	phase1_temp_1761064584793_myi9fjk1m	23	2	16
1342	phase1_temp_1761064584793_myi9fjk1m	24	0	16
1343	phase1_temp_1761064584793_myi9fjk1m	25	0	16
1344	phase1_temp_1761064584793_myi9fjk1m	26	0	16
1345	phase1_temp_1761064584793_myi9fjk1m	27	0	16
1346	phase1_temp_1761064584793_myi9fjk1m	28	0	16
1347	phase1_temp_1761064584793_myi9fjk1m	29	0	16
1348	phase1_temp_1761064584793_myi9fjk1m	30	0	16
1349	phase1_temp_1761064591945_9g10clo4b	1	0	16
1350	phase1_temp_1761064591945_9g10clo4b	2	0	16
1351	phase1_temp_1761064591945_9g10clo4b	3	0	16
1352	phase1_temp_1761064591945_9g10clo4b	4	0	16
1353	phase1_temp_1761064591945_9g10clo4b	5	0	16
1354	phase1_temp_1761064591945_9g10clo4b	6	0	16
1355	phase1_temp_1761064591945_9g10clo4b	7	2	16
1356	phase1_temp_1761064591945_9g10clo4b	8	0	16
1357	phase1_temp_1761064591945_9g10clo4b	9	1	16
1358	phase1_temp_1761064591945_9g10clo4b	10	0	16
1359	phase1_temp_1761064591945_9g10clo4b	11	0	16
1360	phase1_temp_1761064591945_9g10clo4b	12	0	16
1361	phase1_temp_1761064591945_9g10clo4b	13	0	16
1362	phase1_temp_1761064591945_9g10clo4b	14	1	16
1363	phase1_temp_1761064591945_9g10clo4b	15	0	16
1364	phase1_temp_1761064591945_9g10clo4b	16	0	16
1365	phase1_temp_1761064591945_9g10clo4b	17	0	16
1366	phase1_temp_1761064591945_9g10clo4b	18	0	16
1367	phase1_temp_1761064591945_9g10clo4b	19	0	16
1368	phase1_temp_1761064591945_9g10clo4b	20	0	16
1369	phase1_temp_1761064591945_9g10clo4b	21	0	16
1370	phase1_temp_1761064591945_9g10clo4b	22	0	16
1371	phase1_temp_1761064591945_9g10clo4b	23	2	16
1372	phase1_temp_1761064591945_9g10clo4b	24	0	16
1373	phase1_temp_1761064591945_9g10clo4b	25	2	16
1374	phase1_temp_1761064591945_9g10clo4b	26	0	16
1375	phase1_temp_1761064591945_9g10clo4b	27	0	16
1376	phase1_temp_1761064591945_9g10clo4b	28	0	16
1377	phase1_temp_1761064591945_9g10clo4b	29	0	16
1378	phase1_temp_1761064591945_9g10clo4b	30	0	16
1379	phase1_temp_1761064598792_q6hoc3xy5	1	0	16
1380	phase1_temp_1761064598792_q6hoc3xy5	2	0	16
1381	phase1_temp_1761064598792_q6hoc3xy5	3	0	16
1382	phase1_temp_1761064598792_q6hoc3xy5	4	0	16
1383	phase1_temp_1761064598792_q6hoc3xy5	5	0	16
1384	phase1_temp_1761064598792_q6hoc3xy5	6	0	16
1385	phase1_temp_1761064598792_q6hoc3xy5	7	0	16
1386	phase1_temp_1761064598792_q6hoc3xy5	8	2	16
1387	phase1_temp_1761064598792_q6hoc3xy5	9	2	16
1388	phase1_temp_1761064598792_q6hoc3xy5	10	1	16
1389	phase1_temp_1761064598792_q6hoc3xy5	11	2	16
1390	phase1_temp_1761064598792_q6hoc3xy5	12	0	16
1391	phase1_temp_1761064598792_q6hoc3xy5	13	0	16
1392	phase1_temp_1761064598792_q6hoc3xy5	14	0	16
1393	phase1_temp_1761064598792_q6hoc3xy5	15	0	16
1394	phase1_temp_1761064598792_q6hoc3xy5	16	1	16
1395	phase1_temp_1761064598792_q6hoc3xy5	17	0	16
1396	phase1_temp_1761064598792_q6hoc3xy5	18	0	16
1397	phase1_temp_1761064598792_q6hoc3xy5	19	0	16
1398	phase1_temp_1761064598792_q6hoc3xy5	20	0	16
1399	phase1_temp_1761064598792_q6hoc3xy5	21	0	16
1400	phase1_temp_1761064598792_q6hoc3xy5	22	0	16
1401	phase1_temp_1761064598792_q6hoc3xy5	23	0	16
1402	phase1_temp_1761064598792_q6hoc3xy5	24	0	16
1403	phase1_temp_1761064598792_q6hoc3xy5	25	0	16
1404	phase1_temp_1761064598792_q6hoc3xy5	26	0	16
1405	phase1_temp_1761064598792_q6hoc3xy5	27	0	16
1406	phase1_temp_1761064598792_q6hoc3xy5	28	0	16
1407	phase1_temp_1761064598792_q6hoc3xy5	29	0	16
1408	phase1_temp_1761064598792_q6hoc3xy5	30	0	16
1409	phase1_temp_1761064605689_1uv0ivb7x	1	0	16
1410	phase1_temp_1761064605689_1uv0ivb7x	2	0	16
1411	phase1_temp_1761064605689_1uv0ivb7x	3	0	16
1412	phase1_temp_1761064605689_1uv0ivb7x	4	0	16
1413	phase1_temp_1761064605689_1uv0ivb7x	5	0	16
1414	phase1_temp_1761064605689_1uv0ivb7x	6	0	16
1415	phase1_temp_1761064605689_1uv0ivb7x	7	0	16
1416	phase1_temp_1761064605689_1uv0ivb7x	8	0	16
1417	phase1_temp_1761064605689_1uv0ivb7x	9	0	16
1418	phase1_temp_1761064605689_1uv0ivb7x	10	0	16
1419	phase1_temp_1761064605689_1uv0ivb7x	11	0	16
1420	phase1_temp_1761064605689_1uv0ivb7x	12	0	16
1421	phase1_temp_1761064605689_1uv0ivb7x	13	0	16
1422	phase1_temp_1761064605689_1uv0ivb7x	14	0	16
1423	phase1_temp_1761064605689_1uv0ivb7x	15	0	16
1424	phase1_temp_1761064605689_1uv0ivb7x	16	0	16
1425	phase1_temp_1761064605689_1uv0ivb7x	17	0	16
1426	phase1_temp_1761064605689_1uv0ivb7x	18	1	16
1427	phase1_temp_1761064605689_1uv0ivb7x	19	2	16
1428	phase1_temp_1761064605689_1uv0ivb7x	20	0	16
1429	phase1_temp_1761064605689_1uv0ivb7x	21	0	16
1430	phase1_temp_1761064605689_1uv0ivb7x	22	0	16
1431	phase1_temp_1761064605689_1uv0ivb7x	23	0	16
1432	phase1_temp_1761064605689_1uv0ivb7x	24	0	16
1433	phase1_temp_1761064605689_1uv0ivb7x	25	2	16
1434	phase1_temp_1761064605689_1uv0ivb7x	26	0	16
1435	phase1_temp_1761064605689_1uv0ivb7x	27	0	16
1436	phase1_temp_1761064605689_1uv0ivb7x	28	0	16
1437	phase1_temp_1761064605689_1uv0ivb7x	29	0	16
1438	phase1_temp_1761064605689_1uv0ivb7x	30	0	16
1439	phase1_temp_1761065301703_juefozczj	1	0	16
1440	phase1_temp_1761065301703_juefozczj	2	0	16
1441	phase1_temp_1761065301703_juefozczj	3	0	16
1442	phase1_temp_1761065301703_juefozczj	4	0	16
1443	phase1_temp_1761065301703_juefozczj	5	0	16
1444	phase1_temp_1761065301703_juefozczj	6	0	16
1445	phase1_temp_1761065301703_juefozczj	7	0	16
1446	phase1_temp_1761065301703_juefozczj	8	0	16
1447	phase1_temp_1761065301703_juefozczj	9	0	16
1448	phase1_temp_1761065301703_juefozczj	10	0	16
1449	phase1_temp_1761065301703_juefozczj	11	0	16
1450	phase1_temp_1761065301703_juefozczj	12	0	16
1451	phase1_temp_1761065301703_juefozczj	13	0	16
1452	phase1_temp_1761065301703_juefozczj	14	0	16
1453	phase1_temp_1761065301703_juefozczj	15	0	16
1454	phase1_temp_1761065301703_juefozczj	16	0	16
1455	phase1_temp_1761065301703_juefozczj	17	0	16
2780	test_llm_vs_euclidean_1761080185_9069	4	0	11
2781	test_llm_vs_euclidean_1761080185_9069	5	0	11
1458	phase1_temp_1761065301703_juefozczj	20	0	16
1459	phase1_temp_1761065301703_juefozczj	21	2	16
1460	phase1_temp_1761065301703_juefozczj	22	1	16
1461	phase1_temp_1761065301703_juefozczj	23	1	16
1462	phase1_temp_1761065301703_juefozczj	24	0	16
1463	phase1_temp_1761065301703_juefozczj	25	0	16
1464	phase1_temp_1761065301703_juefozczj	26	0	16
1465	phase1_temp_1761065301703_juefozczj	27	0	16
1466	phase1_temp_1761065301703_juefozczj	28	0	16
1467	phase1_temp_1761065301703_juefozczj	29	0	16
1468	phase1_temp_1761065301703_juefozczj	30	0	16
1469	phase1_temp_1761065309731_e894p7q60	1	0	16
1470	phase1_temp_1761065309731_e894p7q60	2	0	16
1471	phase1_temp_1761065309731_e894p7q60	3	0	16
1472	phase1_temp_1761065309731_e894p7q60	4	0	16
1473	phase1_temp_1761065309731_e894p7q60	5	0	16
1474	phase1_temp_1761065309731_e894p7q60	6	0	16
1475	phase1_temp_1761065309731_e894p7q60	7	0	16
1476	phase1_temp_1761065309731_e894p7q60	8	0	16
1477	phase1_temp_1761065309731_e894p7q60	9	0	16
1478	phase1_temp_1761065309731_e894p7q60	10	0	16
1479	phase1_temp_1761065309731_e894p7q60	11	1	16
1480	phase1_temp_1761065309731_e894p7q60	12	0	16
1481	phase1_temp_1761065309731_e894p7q60	13	0	16
1482	phase1_temp_1761065309731_e894p7q60	14	0	16
1483	phase1_temp_1761065309731_e894p7q60	15	0	16
1484	phase1_temp_1761065309731_e894p7q60	16	0	16
1485	phase1_temp_1761065309731_e894p7q60	17	2	16
1486	phase1_temp_1761065309731_e894p7q60	18	1	16
1487	phase1_temp_1761065309731_e894p7q60	19	0	16
1488	phase1_temp_1761065309731_e894p7q60	20	0	16
1489	phase1_temp_1761065309731_e894p7q60	21	0	16
1490	phase1_temp_1761065309731_e894p7q60	22	2	16
1491	phase1_temp_1761065309731_e894p7q60	23	2	16
1492	phase1_temp_1761065309731_e894p7q60	24	0	16
1493	phase1_temp_1761065309731_e894p7q60	25	0	16
1494	phase1_temp_1761065309731_e894p7q60	26	0	16
1495	phase1_temp_1761065309731_e894p7q60	27	0	16
1496	phase1_temp_1761065309731_e894p7q60	28	0	16
1497	phase1_temp_1761065309731_e894p7q60	29	0	16
1498	phase1_temp_1761065309731_e894p7q60	30	0	16
1499	phase1_temp_1761065317016_8uuc897nx	1	0	16
1500	phase1_temp_1761065317016_8uuc897nx	2	0	16
1501	phase1_temp_1761065317016_8uuc897nx	3	0	16
1502	phase1_temp_1761065317016_8uuc897nx	4	0	16
1503	phase1_temp_1761065317016_8uuc897nx	5	0	16
1504	phase1_temp_1761065317016_8uuc897nx	6	0	16
1505	phase1_temp_1761065317016_8uuc897nx	7	2	16
1506	phase1_temp_1761065317016_8uuc897nx	8	0	16
1507	phase1_temp_1761065317016_8uuc897nx	9	1	16
1508	phase1_temp_1761065317016_8uuc897nx	10	0	16
1509	phase1_temp_1761065317016_8uuc897nx	11	0	16
1510	phase1_temp_1761065317016_8uuc897nx	12	0	16
1511	phase1_temp_1761065317016_8uuc897nx	13	0	16
1512	phase1_temp_1761065317016_8uuc897nx	14	1	16
1513	phase1_temp_1761065317016_8uuc897nx	15	0	16
1514	phase1_temp_1761065317016_8uuc897nx	16	0	16
1515	phase1_temp_1761065317016_8uuc897nx	17	0	16
1516	phase1_temp_1761065317016_8uuc897nx	18	0	16
1517	phase1_temp_1761065317016_8uuc897nx	19	0	16
1518	phase1_temp_1761065317016_8uuc897nx	20	0	16
1519	phase1_temp_1761065317016_8uuc897nx	21	0	16
1520	phase1_temp_1761065317016_8uuc897nx	22	0	16
1521	phase1_temp_1761065317016_8uuc897nx	23	2	16
1522	phase1_temp_1761065317016_8uuc897nx	24	0	16
1523	phase1_temp_1761065317016_8uuc897nx	25	2	16
1524	phase1_temp_1761065317016_8uuc897nx	26	0	16
1525	phase1_temp_1761065317016_8uuc897nx	27	0	16
1526	phase1_temp_1761065317016_8uuc897nx	28	0	16
1527	phase1_temp_1761065317016_8uuc897nx	29	0	16
1528	phase1_temp_1761065317016_8uuc897nx	30	0	16
1529	phase1_temp_1761065324347_qxttlquhj	1	0	16
1530	phase1_temp_1761065324347_qxttlquhj	2	0	16
1531	phase1_temp_1761065324347_qxttlquhj	3	0	16
1532	phase1_temp_1761065324347_qxttlquhj	4	0	16
1533	phase1_temp_1761065324347_qxttlquhj	5	0	16
1534	phase1_temp_1761065324347_qxttlquhj	6	0	16
1535	phase1_temp_1761065324347_qxttlquhj	7	0	16
1536	phase1_temp_1761065324347_qxttlquhj	8	2	16
1537	phase1_temp_1761065324347_qxttlquhj	9	2	16
1538	phase1_temp_1761065324347_qxttlquhj	10	1	16
1539	phase1_temp_1761065324347_qxttlquhj	11	2	16
1540	phase1_temp_1761065324347_qxttlquhj	12	0	16
1541	phase1_temp_1761065324347_qxttlquhj	13	1	16
1542	phase1_temp_1761065324347_qxttlquhj	14	0	16
1543	phase1_temp_1761065324347_qxttlquhj	15	0	16
1544	phase1_temp_1761065324347_qxttlquhj	16	0	16
1545	phase1_temp_1761065324347_qxttlquhj	17	0	16
1546	phase1_temp_1761065324347_qxttlquhj	18	0	16
1547	phase1_temp_1761065324347_qxttlquhj	19	0	16
1548	phase1_temp_1761065324347_qxttlquhj	20	0	16
1549	phase1_temp_1761065324347_qxttlquhj	21	0	16
1550	phase1_temp_1761065324347_qxttlquhj	22	0	16
1551	phase1_temp_1761065324347_qxttlquhj	23	0	16
1552	phase1_temp_1761065324347_qxttlquhj	24	0	16
1553	phase1_temp_1761065324347_qxttlquhj	25	0	16
1554	phase1_temp_1761065324347_qxttlquhj	26	0	16
1555	phase1_temp_1761065324347_qxttlquhj	27	0	16
1556	phase1_temp_1761065324347_qxttlquhj	28	0	16
1557	phase1_temp_1761065324347_qxttlquhj	29	0	16
1558	phase1_temp_1761065324347_qxttlquhj	30	0	16
1559	phase1_temp_1761065332763_yjl4oe5wm	1	0	16
1560	phase1_temp_1761065332763_yjl4oe5wm	2	0	16
1561	phase1_temp_1761065332763_yjl4oe5wm	3	0	16
1562	phase1_temp_1761065332763_yjl4oe5wm	4	0	16
1563	phase1_temp_1761065332763_yjl4oe5wm	5	0	16
1564	phase1_temp_1761065332763_yjl4oe5wm	6	0	16
1565	phase1_temp_1761065332763_yjl4oe5wm	7	0	16
1566	phase1_temp_1761065332763_yjl4oe5wm	8	0	16
1567	phase1_temp_1761065332763_yjl4oe5wm	9	0	16
1568	phase1_temp_1761065332763_yjl4oe5wm	10	0	16
1569	phase1_temp_1761065332763_yjl4oe5wm	11	0	16
1570	phase1_temp_1761065332763_yjl4oe5wm	12	0	16
1571	phase1_temp_1761065332763_yjl4oe5wm	13	0	16
1572	phase1_temp_1761065332763_yjl4oe5wm	14	0	16
1573	phase1_temp_1761065332763_yjl4oe5wm	15	0	16
1574	phase1_temp_1761065332763_yjl4oe5wm	16	0	16
1575	phase1_temp_1761065332763_yjl4oe5wm	17	0	16
1576	phase1_temp_1761065332763_yjl4oe5wm	18	1	16
1577	phase1_temp_1761065332763_yjl4oe5wm	19	2	16
1578	phase1_temp_1761065332763_yjl4oe5wm	20	0	16
1579	phase1_temp_1761065332763_yjl4oe5wm	21	0	16
1580	phase1_temp_1761065332763_yjl4oe5wm	22	0	16
1581	phase1_temp_1761065332763_yjl4oe5wm	23	0	16
1582	phase1_temp_1761065332763_yjl4oe5wm	24	0	16
1583	phase1_temp_1761065332763_yjl4oe5wm	25	2	16
1584	phase1_temp_1761065332763_yjl4oe5wm	26	0	16
1585	phase1_temp_1761065332763_yjl4oe5wm	27	0	16
1586	phase1_temp_1761065332763_yjl4oe5wm	28	0	16
1587	phase1_temp_1761065332763_yjl4oe5wm	29	0	16
1588	phase1_temp_1761065332763_yjl4oe5wm	30	0	16
1589	phase1_temp_1761065655490_w4f146y19	1	0	16
1590	phase1_temp_1761065655490_w4f146y19	2	0	16
1591	phase1_temp_1761065655490_w4f146y19	3	0	16
1592	phase1_temp_1761065655490_w4f146y19	4	0	16
1593	phase1_temp_1761065655490_w4f146y19	5	0	16
1594	phase1_temp_1761065655490_w4f146y19	6	0	16
1595	phase1_temp_1761065655490_w4f146y19	7	0	16
1596	phase1_temp_1761065655490_w4f146y19	8	0	16
1597	phase1_temp_1761065655490_w4f146y19	9	0	16
1598	phase1_temp_1761065655490_w4f146y19	10	0	16
1599	phase1_temp_1761065655490_w4f146y19	11	0	16
1600	phase1_temp_1761065655490_w4f146y19	12	0	16
1601	phase1_temp_1761065655490_w4f146y19	13	0	16
1602	phase1_temp_1761065655490_w4f146y19	14	0	16
1603	phase1_temp_1761065655490_w4f146y19	15	0	16
1604	phase1_temp_1761065655490_w4f146y19	16	0	16
1605	phase1_temp_1761065655490_w4f146y19	17	0	16
1606	phase1_temp_1761065655490_w4f146y19	18	1	16
1607	phase1_temp_1761065655490_w4f146y19	19	2	16
1608	phase1_temp_1761065655490_w4f146y19	20	0	16
1609	phase1_temp_1761065655490_w4f146y19	21	0	16
1610	phase1_temp_1761065655490_w4f146y19	22	0	16
1611	phase1_temp_1761065655490_w4f146y19	23	0	16
1612	phase1_temp_1761065655490_w4f146y19	24	0	16
1613	phase1_temp_1761065655490_w4f146y19	25	2	16
1614	phase1_temp_1761065655490_w4f146y19	26	0	16
1615	phase1_temp_1761065655490_w4f146y19	27	0	16
1616	phase1_temp_1761065655490_w4f146y19	28	0	16
1617	phase1_temp_1761065655490_w4f146y19	29	0	16
1618	phase1_temp_1761065655490_w4f146y19	30	0	16
1619	phase1_temp_1761066006974_nunzoua03	1	0	16
1620	phase1_temp_1761066006974_nunzoua03	2	0	16
1621	phase1_temp_1761066006974_nunzoua03	3	0	16
1622	phase1_temp_1761066006974_nunzoua03	4	0	16
1623	phase1_temp_1761066006974_nunzoua03	5	0	16
1624	phase1_temp_1761066006974_nunzoua03	6	0	16
1625	phase1_temp_1761066006974_nunzoua03	7	0	16
1626	phase1_temp_1761066006974_nunzoua03	8	0	16
1627	phase1_temp_1761066006974_nunzoua03	9	0	16
1628	phase1_temp_1761066006974_nunzoua03	10	0	16
1629	phase1_temp_1761066006974_nunzoua03	11	0	16
1630	phase1_temp_1761066006974_nunzoua03	12	0	16
1631	phase1_temp_1761066006974_nunzoua03	13	0	16
1632	phase1_temp_1761066006974_nunzoua03	14	0	16
1633	phase1_temp_1761066006974_nunzoua03	15	0	16
1634	phase1_temp_1761066006974_nunzoua03	16	0	16
1635	phase1_temp_1761066006974_nunzoua03	17	0	16
1636	phase1_temp_1761066006974_nunzoua03	18	1	16
1637	phase1_temp_1761066006974_nunzoua03	19	2	16
1638	phase1_temp_1761066006974_nunzoua03	20	0	16
1639	phase1_temp_1761066006974_nunzoua03	21	0	16
1640	phase1_temp_1761066006974_nunzoua03	22	0	16
1641	phase1_temp_1761066006974_nunzoua03	23	0	16
1642	phase1_temp_1761066006974_nunzoua03	24	0	16
1643	phase1_temp_1761066006974_nunzoua03	25	2	16
1644	phase1_temp_1761066006974_nunzoua03	26	0	16
1645	phase1_temp_1761066006974_nunzoua03	27	0	16
1646	phase1_temp_1761066006974_nunzoua03	28	0	16
1647	phase1_temp_1761066006974_nunzoua03	29	0	16
1648	phase1_temp_1761066006974_nunzoua03	30	0	16
1649	phase1_temp_1761066471322_og7qw5ixe	1	0	16
1650	phase1_temp_1761066471322_og7qw5ixe	2	0	16
1651	phase1_temp_1761066471322_og7qw5ixe	3	0	16
1652	phase1_temp_1761066471322_og7qw5ixe	4	0	16
1653	phase1_temp_1761066471322_og7qw5ixe	5	0	16
1654	phase1_temp_1761066471322_og7qw5ixe	6	0	16
1655	phase1_temp_1761066471322_og7qw5ixe	7	0	16
1656	phase1_temp_1761066471322_og7qw5ixe	8	0	16
1657	phase1_temp_1761066471322_og7qw5ixe	9	0	16
1658	phase1_temp_1761066471322_og7qw5ixe	10	0	16
1659	phase1_temp_1761066471322_og7qw5ixe	11	0	16
1660	phase1_temp_1761066471322_og7qw5ixe	12	0	16
1661	phase1_temp_1761066471322_og7qw5ixe	13	0	16
1662	phase1_temp_1761066471322_og7qw5ixe	14	0	16
1663	phase1_temp_1761066471322_og7qw5ixe	15	0	16
1664	phase1_temp_1761066471322_og7qw5ixe	16	0	16
1665	phase1_temp_1761066471322_og7qw5ixe	17	0	16
2782	test_llm_vs_euclidean_1761080185_9069	6	0	11
2783	test_llm_vs_euclidean_1761080185_9069	7	2	11
1668	phase1_temp_1761066471322_og7qw5ixe	20	0	16
1669	phase1_temp_1761066471322_og7qw5ixe	21	2	16
1670	phase1_temp_1761066471322_og7qw5ixe	22	1	16
1671	phase1_temp_1761066471322_og7qw5ixe	23	1	16
1672	phase1_temp_1761066471322_og7qw5ixe	24	0	16
1673	phase1_temp_1761066471322_og7qw5ixe	25	0	16
1674	phase1_temp_1761066471322_og7qw5ixe	26	0	16
1675	phase1_temp_1761066471322_og7qw5ixe	27	0	16
1676	phase1_temp_1761066471322_og7qw5ixe	28	0	16
1677	phase1_temp_1761066471322_og7qw5ixe	29	0	16
1678	phase1_temp_1761066471322_og7qw5ixe	30	0	16
1679	phase1_temp_1761066480657_nm72hejhf	1	0	16
1680	phase1_temp_1761066480657_nm72hejhf	2	0	16
1681	phase1_temp_1761066480657_nm72hejhf	3	0	16
1682	phase1_temp_1761066480657_nm72hejhf	4	0	16
1683	phase1_temp_1761066480657_nm72hejhf	5	0	16
1684	phase1_temp_1761066480657_nm72hejhf	6	0	16
1685	phase1_temp_1761066480657_nm72hejhf	7	0	16
1686	phase1_temp_1761066480657_nm72hejhf	8	0	16
1687	phase1_temp_1761066480657_nm72hejhf	9	0	16
1688	phase1_temp_1761066480657_nm72hejhf	10	0	16
1689	phase1_temp_1761066480657_nm72hejhf	11	1	16
1690	phase1_temp_1761066480657_nm72hejhf	12	0	16
1691	phase1_temp_1761066480657_nm72hejhf	13	0	16
1692	phase1_temp_1761066480657_nm72hejhf	14	0	16
1693	phase1_temp_1761066480657_nm72hejhf	15	0	16
1694	phase1_temp_1761066480657_nm72hejhf	16	0	16
1695	phase1_temp_1761066480657_nm72hejhf	17	2	16
2784	test_llm_vs_euclidean_1761080185_9069	8	0	11
2785	test_llm_vs_euclidean_1761080185_9069	9	1	11
1698	phase1_temp_1761066480657_nm72hejhf	20	0	16
1699	phase1_temp_1761066480657_nm72hejhf	21	0	16
1700	phase1_temp_1761066480657_nm72hejhf	22	2	16
1701	phase1_temp_1761066480657_nm72hejhf	23	2	16
1702	phase1_temp_1761066480657_nm72hejhf	24	0	16
1703	phase1_temp_1761066480657_nm72hejhf	25	0	16
1704	phase1_temp_1761066480657_nm72hejhf	26	0	16
1705	phase1_temp_1761066480657_nm72hejhf	27	0	16
1706	phase1_temp_1761066480657_nm72hejhf	28	0	16
1707	phase1_temp_1761066480657_nm72hejhf	29	0	16
1708	phase1_temp_1761066480657_nm72hejhf	30	0	16
1709	phase1_temp_1761066488385_h3r2r3fef	1	0	16
1710	phase1_temp_1761066488385_h3r2r3fef	2	0	16
1711	phase1_temp_1761066488385_h3r2r3fef	3	0	16
1712	phase1_temp_1761066488385_h3r2r3fef	4	0	16
1713	phase1_temp_1761066488385_h3r2r3fef	5	0	16
1714	phase1_temp_1761066488385_h3r2r3fef	6	0	16
1715	phase1_temp_1761066488385_h3r2r3fef	7	2	16
1716	phase1_temp_1761066488385_h3r2r3fef	8	0	16
1717	phase1_temp_1761066488385_h3r2r3fef	9	1	16
1718	phase1_temp_1761066488385_h3r2r3fef	10	0	16
1719	phase1_temp_1761066488385_h3r2r3fef	11	0	16
1720	phase1_temp_1761066488385_h3r2r3fef	12	0	16
1721	phase1_temp_1761066488385_h3r2r3fef	13	0	16
1722	phase1_temp_1761066488385_h3r2r3fef	14	2	16
1723	phase1_temp_1761066488385_h3r2r3fef	15	0	16
1724	phase1_temp_1761066488385_h3r2r3fef	16	0	16
1725	phase1_temp_1761066488385_h3r2r3fef	17	0	16
1726	phase1_temp_1761066488385_h3r2r3fef	18	0	16
2786	test_llm_vs_euclidean_1761080185_9069	10	0	11
1728	phase1_temp_1761066488385_h3r2r3fef	20	0	16
1729	phase1_temp_1761066488385_h3r2r3fef	21	0	16
1730	phase1_temp_1761066488385_h3r2r3fef	22	0	16
1731	phase1_temp_1761066488385_h3r2r3fef	23	2	16
1732	phase1_temp_1761066488385_h3r2r3fef	24	0	16
1733	phase1_temp_1761066488385_h3r2r3fef	25	2	16
1734	phase1_temp_1761066488385_h3r2r3fef	26	0	16
1735	phase1_temp_1761066488385_h3r2r3fef	27	0	16
1736	phase1_temp_1761066488385_h3r2r3fef	28	0	16
1737	phase1_temp_1761066488385_h3r2r3fef	29	0	16
1738	phase1_temp_1761066488385_h3r2r3fef	30	0	16
1739	phase1_temp_1761066496450_nbqr68c4z	1	0	16
1740	phase1_temp_1761066496450_nbqr68c4z	2	0	16
1741	phase1_temp_1761066496450_nbqr68c4z	3	0	16
1742	phase1_temp_1761066496450_nbqr68c4z	4	0	16
1743	phase1_temp_1761066496450_nbqr68c4z	5	0	16
1744	phase1_temp_1761066496450_nbqr68c4z	6	0	16
1745	phase1_temp_1761066496450_nbqr68c4z	7	0	16
1746	phase1_temp_1761066496450_nbqr68c4z	8	2	16
1747	phase1_temp_1761066496450_nbqr68c4z	9	2	16
1748	phase1_temp_1761066496450_nbqr68c4z	10	1	16
1749	phase1_temp_1761066496450_nbqr68c4z	11	2	16
1750	phase1_temp_1761066496450_nbqr68c4z	12	0	16
1751	phase1_temp_1761066496450_nbqr68c4z	13	0	16
1752	phase1_temp_1761066496450_nbqr68c4z	14	0	16
1753	phase1_temp_1761066496450_nbqr68c4z	15	0	16
1754	phase1_temp_1761066496450_nbqr68c4z	16	1	16
1755	phase1_temp_1761066496450_nbqr68c4z	17	0	16
1756	phase1_temp_1761066496450_nbqr68c4z	18	0	16
2787	test_llm_vs_euclidean_1761080185_9069	11	0	11
1758	phase1_temp_1761066496450_nbqr68c4z	20	0	16
1759	phase1_temp_1761066496450_nbqr68c4z	21	0	16
1760	phase1_temp_1761066496450_nbqr68c4z	22	0	16
1761	phase1_temp_1761066496450_nbqr68c4z	23	0	16
1762	phase1_temp_1761066496450_nbqr68c4z	24	0	16
1763	phase1_temp_1761066496450_nbqr68c4z	25	0	16
1764	phase1_temp_1761066496450_nbqr68c4z	26	0	16
1765	phase1_temp_1761066496450_nbqr68c4z	27	0	16
1766	phase1_temp_1761066496450_nbqr68c4z	28	0	16
1767	phase1_temp_1761066496450_nbqr68c4z	29	0	16
1768	phase1_temp_1761066496450_nbqr68c4z	30	0	16
1769	phase1_temp_1761066505736_3xakhlj37	1	0	16
1770	phase1_temp_1761066505736_3xakhlj37	2	0	16
1771	phase1_temp_1761066505736_3xakhlj37	3	0	16
1772	phase1_temp_1761066505736_3xakhlj37	4	0	16
1773	phase1_temp_1761066505736_3xakhlj37	5	0	16
1774	phase1_temp_1761066505736_3xakhlj37	6	0	16
1775	phase1_temp_1761066505736_3xakhlj37	7	0	16
1776	phase1_temp_1761066505736_3xakhlj37	8	0	16
1777	phase1_temp_1761066505736_3xakhlj37	9	0	16
1778	phase1_temp_1761066505736_3xakhlj37	10	0	16
1779	phase1_temp_1761066505736_3xakhlj37	11	0	16
1780	phase1_temp_1761066505736_3xakhlj37	12	0	16
1781	phase1_temp_1761066505736_3xakhlj37	13	0	16
1782	phase1_temp_1761066505736_3xakhlj37	14	0	16
1783	phase1_temp_1761066505736_3xakhlj37	15	0	16
1784	phase1_temp_1761066505736_3xakhlj37	16	0	16
1785	phase1_temp_1761066505736_3xakhlj37	17	0	16
1786	phase1_temp_1761066505736_3xakhlj37	18	1	16
1787	phase1_temp_1761066505736_3xakhlj37	19	2	16
1788	phase1_temp_1761066505736_3xakhlj37	20	0	16
1789	phase1_temp_1761066505736_3xakhlj37	21	0	16
1790	phase1_temp_1761066505736_3xakhlj37	22	0	16
1791	phase1_temp_1761066505736_3xakhlj37	23	0	16
1792	phase1_temp_1761066505736_3xakhlj37	24	0	16
1793	phase1_temp_1761066505736_3xakhlj37	25	2	16
1794	phase1_temp_1761066505736_3xakhlj37	26	0	16
1795	phase1_temp_1761066505736_3xakhlj37	27	0	16
1796	phase1_temp_1761066505736_3xakhlj37	28	0	16
1797	phase1_temp_1761066505736_3xakhlj37	29	0	16
1798	phase1_temp_1761066505736_3xakhlj37	30	0	16
1799	phase1_temp_1761067175225_rrin4mxsz	1	0	16
1800	phase1_temp_1761067175225_rrin4mxsz	2	0	16
1801	phase1_temp_1761067175225_rrin4mxsz	3	0	16
1802	phase1_temp_1761067175225_rrin4mxsz	4	0	16
1803	phase1_temp_1761067175225_rrin4mxsz	5	0	16
1804	phase1_temp_1761067175225_rrin4mxsz	6	0	16
1805	phase1_temp_1761067175225_rrin4mxsz	7	0	16
1806	phase1_temp_1761067175225_rrin4mxsz	8	0	16
1807	phase1_temp_1761067175225_rrin4mxsz	9	0	16
1808	phase1_temp_1761067175225_rrin4mxsz	10	0	16
1809	phase1_temp_1761067175225_rrin4mxsz	11	0	16
1810	phase1_temp_1761067175225_rrin4mxsz	12	0	16
1811	phase1_temp_1761067175225_rrin4mxsz	13	0	16
1812	phase1_temp_1761067175225_rrin4mxsz	14	0	16
1813	phase1_temp_1761067175225_rrin4mxsz	15	0	16
1814	phase1_temp_1761067175225_rrin4mxsz	16	0	16
1815	phase1_temp_1761067175225_rrin4mxsz	17	0	16
1816	phase1_temp_1761067175225_rrin4mxsz	18	1	16
1817	phase1_temp_1761067175225_rrin4mxsz	19	2	16
1818	phase1_temp_1761067175225_rrin4mxsz	20	0	16
1819	phase1_temp_1761067175225_rrin4mxsz	21	0	16
1820	phase1_temp_1761067175225_rrin4mxsz	22	0	16
1821	phase1_temp_1761067175225_rrin4mxsz	23	0	16
1822	phase1_temp_1761067175225_rrin4mxsz	24	0	16
1823	phase1_temp_1761067175225_rrin4mxsz	25	2	16
1824	phase1_temp_1761067175225_rrin4mxsz	26	0	16
1825	phase1_temp_1761067175225_rrin4mxsz	27	0	16
1826	phase1_temp_1761067175225_rrin4mxsz	28	0	16
1827	phase1_temp_1761067175225_rrin4mxsz	29	0	16
1828	phase1_temp_1761067175225_rrin4mxsz	30	0	16
1829	phase1_temp_1761067185881_5unpi01nr	1	0	16
1830	phase1_temp_1761067185881_5unpi01nr	2	0	16
1831	phase1_temp_1761067185881_5unpi01nr	3	0	16
1832	phase1_temp_1761067185881_5unpi01nr	4	0	16
1833	phase1_temp_1761067185881_5unpi01nr	5	0	16
1834	phase1_temp_1761067185881_5unpi01nr	6	0	16
1835	phase1_temp_1761067185881_5unpi01nr	7	2	16
1836	phase1_temp_1761067185881_5unpi01nr	8	0	16
1837	phase1_temp_1761067185881_5unpi01nr	9	1	16
1838	phase1_temp_1761067185881_5unpi01nr	10	0	16
1839	phase1_temp_1761067185881_5unpi01nr	11	0	16
1840	phase1_temp_1761067185881_5unpi01nr	12	0	16
1841	phase1_temp_1761067185881_5unpi01nr	13	0	16
1842	phase1_temp_1761067185881_5unpi01nr	14	1	16
1843	phase1_temp_1761067185881_5unpi01nr	15	0	16
1844	phase1_temp_1761067185881_5unpi01nr	16	0	16
1845	phase1_temp_1761067185881_5unpi01nr	17	0	16
1846	phase1_temp_1761067185881_5unpi01nr	18	0	16
1847	phase1_temp_1761067185881_5unpi01nr	19	0	16
1848	phase1_temp_1761067185881_5unpi01nr	20	0	16
1849	phase1_temp_1761067185881_5unpi01nr	21	0	16
1850	phase1_temp_1761067185881_5unpi01nr	22	0	16
1851	phase1_temp_1761067185881_5unpi01nr	23	2	16
1852	phase1_temp_1761067185881_5unpi01nr	24	0	16
1853	phase1_temp_1761067185881_5unpi01nr	25	2	16
1854	phase1_temp_1761067185881_5unpi01nr	26	0	16
1855	phase1_temp_1761067185881_5unpi01nr	27	0	16
1856	phase1_temp_1761067185881_5unpi01nr	28	0	16
1857	phase1_temp_1761067185881_5unpi01nr	29	0	16
1858	phase1_temp_1761067185881_5unpi01nr	30	0	16
1859	phase1_temp_1761067289219_wk56rjtrb	1	0	16
1860	phase1_temp_1761067289219_wk56rjtrb	2	0	16
1861	phase1_temp_1761067289219_wk56rjtrb	3	0	16
1862	phase1_temp_1761067289219_wk56rjtrb	4	0	16
1863	phase1_temp_1761067289219_wk56rjtrb	5	0	16
1864	phase1_temp_1761067289219_wk56rjtrb	6	0	16
1865	phase1_temp_1761067289219_wk56rjtrb	7	0	16
1866	phase1_temp_1761067289219_wk56rjtrb	8	0	16
1867	phase1_temp_1761067289219_wk56rjtrb	9	0	16
1868	phase1_temp_1761067289219_wk56rjtrb	10	0	16
1869	phase1_temp_1761067289219_wk56rjtrb	11	1	16
1870	phase1_temp_1761067289219_wk56rjtrb	12	0	16
1871	phase1_temp_1761067289219_wk56rjtrb	13	0	16
1872	phase1_temp_1761067289219_wk56rjtrb	14	0	16
1873	phase1_temp_1761067289219_wk56rjtrb	15	0	16
1874	phase1_temp_1761067289219_wk56rjtrb	16	0	16
1875	phase1_temp_1761067289219_wk56rjtrb	17	2	16
1878	phase1_temp_1761067289219_wk56rjtrb	20	0	16
1879	phase1_temp_1761067289219_wk56rjtrb	21	0	16
1880	phase1_temp_1761067289219_wk56rjtrb	22	2	16
1881	phase1_temp_1761067289219_wk56rjtrb	23	2	16
1882	phase1_temp_1761067289219_wk56rjtrb	24	0	16
1883	phase1_temp_1761067289219_wk56rjtrb	25	0	16
1884	phase1_temp_1761067289219_wk56rjtrb	26	0	16
1885	phase1_temp_1761067289219_wk56rjtrb	27	0	16
1886	phase1_temp_1761067289219_wk56rjtrb	28	0	16
1887	phase1_temp_1761067289219_wk56rjtrb	29	0	16
1888	phase1_temp_1761067289219_wk56rjtrb	30	0	16
1889	phase1_temp_1761067299128_fmegejpqf	1	0	16
1890	phase1_temp_1761067299128_fmegejpqf	2	0	16
1891	phase1_temp_1761067299128_fmegejpqf	3	0	16
1892	phase1_temp_1761067299128_fmegejpqf	4	0	16
1893	phase1_temp_1761067299128_fmegejpqf	5	0	16
1894	phase1_temp_1761067299128_fmegejpqf	6	0	16
1895	phase1_temp_1761067299128_fmegejpqf	7	0	16
1896	phase1_temp_1761067299128_fmegejpqf	8	0	16
1897	phase1_temp_1761067299128_fmegejpqf	9	0	16
1898	phase1_temp_1761067299128_fmegejpqf	10	0	16
1899	phase1_temp_1761067299128_fmegejpqf	11	0	16
1900	phase1_temp_1761067299128_fmegejpqf	12	0	16
1901	phase1_temp_1761067299128_fmegejpqf	13	0	16
1902	phase1_temp_1761067299128_fmegejpqf	14	0	16
1903	phase1_temp_1761067299128_fmegejpqf	15	0	16
1904	phase1_temp_1761067299128_fmegejpqf	16	0	16
1905	phase1_temp_1761067299128_fmegejpqf	17	0	16
1908	phase1_temp_1761067299128_fmegejpqf	20	0	16
1909	phase1_temp_1761067299128_fmegejpqf	21	2	16
1910	phase1_temp_1761067299128_fmegejpqf	22	1	16
1911	phase1_temp_1761067299128_fmegejpqf	23	1	16
1912	phase1_temp_1761067299128_fmegejpqf	24	0	16
1913	phase1_temp_1761067299128_fmegejpqf	25	0	16
1914	phase1_temp_1761067299128_fmegejpqf	26	0	16
1915	phase1_temp_1761067299128_fmegejpqf	27	0	16
1916	phase1_temp_1761067299128_fmegejpqf	28	0	16
1917	phase1_temp_1761067299128_fmegejpqf	29	0	16
1918	phase1_temp_1761067299128_fmegejpqf	30	0	16
1876	phase1_temp_1761067289219_wk56rjtrb	18	4	16
1877	phase1_temp_1761067289219_wk56rjtrb	19	4	16
1906	phase1_temp_1761067299128_fmegejpqf	18	4	16
1907	phase1_temp_1761067299128_fmegejpqf	19	4	16
2788	test_llm_vs_euclidean_1761080185_9069	12	0	11
2789	test_llm_vs_euclidean_1761080185_9069	13	0	11
2790	test_llm_vs_euclidean_1761080185_9069	14	1	11
2791	test_llm_vs_euclidean_1761080185_9069	15	0	11
2792	test_llm_vs_euclidean_1761080185_9069	16	0	11
2793	test_llm_vs_euclidean_1761080185_9069	17	0	11
2794	test_llm_vs_euclidean_1761080185_9069	18	0	11
2795	test_llm_vs_euclidean_1761080185_9069	19	0	11
2796	test_llm_vs_euclidean_1761080185_9069	20	0	11
2797	test_llm_vs_euclidean_1761080185_9069	21	0	11
2798	test_llm_vs_euclidean_1761080185_9069	22	0	11
2799	test_llm_vs_euclidean_1761080185_9069	23	2	11
2800	test_llm_vs_euclidean_1761080185_9069	24	0	11
2801	test_llm_vs_euclidean_1761080185_9069	25	1	11
2802	test_llm_vs_euclidean_1761080185_9069	26	0	11
2803	test_llm_vs_euclidean_1761080185_9069	27	0	11
2804	test_llm_vs_euclidean_1761080185_9069	28	0	11
2805	test_llm_vs_euclidean_1761080185_9069	29	0	11
2806	test_llm_vs_euclidean_1761080185_9069	30	0	11
2807	phase1_temp_1761080345662_5i6al8edx	1	0	16
2808	phase1_temp_1761080345662_5i6al8edx	2	0	16
2809	phase1_temp_1761080345662_5i6al8edx	3	0	16
2810	phase1_temp_1761080345662_5i6al8edx	4	0	16
2811	phase1_temp_1761080345662_5i6al8edx	5	0	16
2812	phase1_temp_1761080345662_5i6al8edx	6	0	16
2813	phase1_temp_1761080345662_5i6al8edx	7	0	16
2814	phase1_temp_1761080345662_5i6al8edx	8	0	16
2815	phase1_temp_1761080345662_5i6al8edx	9	0	16
2816	phase1_temp_1761080345662_5i6al8edx	10	0	16
2817	phase1_temp_1761080345662_5i6al8edx	11	0	16
2818	phase1_temp_1761080345662_5i6al8edx	12	0	16
2819	phase1_temp_1761080345662_5i6al8edx	13	0	16
2820	phase1_temp_1761080345662_5i6al8edx	14	0	16
2821	phase1_temp_1761080345662_5i6al8edx	15	0	16
2822	phase1_temp_1761080345662_5i6al8edx	16	0	16
2823	phase1_temp_1761080345662_5i6al8edx	17	0	16
2824	phase1_temp_1761080345662_5i6al8edx	18	4	16
2825	phase1_temp_1761080345662_5i6al8edx	19	4	16
2826	phase1_temp_1761080345662_5i6al8edx	20	0	16
2827	phase1_temp_1761080345662_5i6al8edx	21	2	16
2828	phase1_temp_1761080345662_5i6al8edx	22	0	16
2829	phase1_temp_1761080345662_5i6al8edx	23	0	16
2830	phase1_temp_1761080345662_5i6al8edx	24	0	16
2831	phase1_temp_1761080345662_5i6al8edx	25	0	16
2832	phase1_temp_1761080345662_5i6al8edx	26	0	16
2833	phase1_temp_1761080345662_5i6al8edx	27	0	16
2834	phase1_temp_1761080345662_5i6al8edx	28	0	16
2835	phase1_temp_1761080345662_5i6al8edx	29	0	16
2836	phase1_temp_1761080345662_5i6al8edx	30	0	16
2987	phase1_temp_1761084250260_8hl6wh7vx	1	0	17
2988	phase1_temp_1761084250260_8hl6wh7vx	2	0	17
2989	phase1_temp_1761084250260_8hl6wh7vx	3	0	17
2990	phase1_temp_1761084250260_8hl6wh7vx	4	0	17
2991	phase1_temp_1761084250260_8hl6wh7vx	5	0	17
2992	phase1_temp_1761084250260_8hl6wh7vx	6	0	17
2993	phase1_temp_1761084250260_8hl6wh7vx	7	0	17
2994	phase1_temp_1761084250260_8hl6wh7vx	8	0	17
2995	phase1_temp_1761084250260_8hl6wh7vx	9	0	17
2996	phase1_temp_1761084250260_8hl6wh7vx	10	0	17
2997	phase1_temp_1761084250260_8hl6wh7vx	11	1	17
2998	phase1_temp_1761084250260_8hl6wh7vx	12	0	17
2999	phase1_temp_1761084250260_8hl6wh7vx	13	0	17
3000	phase1_temp_1761084250260_8hl6wh7vx	14	0	17
3001	phase1_temp_1761084250260_8hl6wh7vx	15	0	17
3002	phase1_temp_1761084250260_8hl6wh7vx	16	1	17
3003	phase1_temp_1761084250260_8hl6wh7vx	17	1	17
3004	phase1_temp_1761084250260_8hl6wh7vx	18	4	17
3005	phase1_temp_1761084250260_8hl6wh7vx	19	4	17
3006	phase1_temp_1761084250260_8hl6wh7vx	20	1	17
3007	phase1_temp_1761084250260_8hl6wh7vx	21	2	17
3008	phase1_temp_1761084250260_8hl6wh7vx	22	0	17
3009	phase1_temp_1761084250260_8hl6wh7vx	23	0	17
3010	phase1_temp_1761084250260_8hl6wh7vx	24	0	17
3011	phase1_temp_1761084250260_8hl6wh7vx	25	0	17
3012	phase1_temp_1761084250260_8hl6wh7vx	26	0	17
3013	phase1_temp_1761084250260_8hl6wh7vx	27	0	17
3014	phase1_temp_1761084250260_8hl6wh7vx	28	0	17
3015	phase1_temp_1761084250260_8hl6wh7vx	29	0	17
3016	phase1_temp_1761084250260_8hl6wh7vx	30	0	17
3037	phase1_temp_1761089467953_w1qx12pv2	21	0	18
3038	phase1_temp_1761089467953_w1qx12pv2	22	0	18
3039	phase1_temp_1761089467953_w1qx12pv2	23	0	18
3040	phase1_temp_1761089467953_w1qx12pv2	24	0	18
3041	phase1_temp_1761089467953_w1qx12pv2	25	0	18
3042	phase1_temp_1761089467953_w1qx12pv2	26	0	18
3043	phase1_temp_1761089467953_w1qx12pv2	27	0	18
3044	phase1_temp_1761089467953_w1qx12pv2	28	0	18
3045	phase1_temp_1761089467953_w1qx12pv2	29	0	18
3046	phase1_temp_1761089467953_w1qx12pv2	30	0	18
3047	phase1_temp_1761089478883_rjy0nk1ah	1	0	18
3048	phase1_temp_1761089478883_rjy0nk1ah	2	0	18
3049	phase1_temp_1761089478883_rjy0nk1ah	3	0	18
3050	phase1_temp_1761089478883_rjy0nk1ah	4	0	18
3051	phase1_temp_1761089478883_rjy0nk1ah	5	0	18
3052	phase1_temp_1761089478883_rjy0nk1ah	6	0	18
3053	phase1_temp_1761089478883_rjy0nk1ah	7	0	18
3054	phase1_temp_1761089478883_rjy0nk1ah	8	0	18
3055	phase1_temp_1761089478883_rjy0nk1ah	9	0	18
3056	phase1_temp_1761089478883_rjy0nk1ah	10	0	18
3057	phase1_temp_1761089478883_rjy0nk1ah	11	1	18
3058	phase1_temp_1761089478883_rjy0nk1ah	12	0	18
1979	test_sw_dev_faiss	1	0	11
1980	test_sw_dev_faiss	2	0	11
1981	test_sw_dev_faiss	3	0	11
1982	test_sw_dev_faiss	4	0	11
1983	test_sw_dev_faiss	5	0	11
1984	test_sw_dev_faiss	6	0	11
1985	test_sw_dev_faiss	7	0	11
1986	test_sw_dev_faiss	8	0	11
1987	test_sw_dev_faiss	9	0	11
1988	test_sw_dev_faiss	10	0	11
1989	test_sw_dev_faiss	11	0	11
1990	test_sw_dev_faiss	12	0	11
1991	test_sw_dev_faiss	13	0	11
1992	test_sw_dev_faiss	14	0	11
1993	test_sw_dev_faiss	15	0	11
1994	test_sw_dev_faiss	16	0	11
1995	test_sw_dev_faiss	17	0	11
1996	test_sw_dev_faiss	18	0	11
1997	test_sw_dev_faiss	19	0	11
1998	test_sw_dev_faiss	20	0	11
1999	test_sw_dev_faiss	21	0	11
2000	test_sw_dev_faiss	22	0	11
2001	test_sw_dev_faiss	23	0	11
2002	test_sw_dev_faiss	24	0	11
2003	test_sw_dev_faiss	25	0	11
2004	test_sw_dev_faiss	26	0	11
2005	test_sw_dev_faiss	27	0	11
2006	test_sw_dev_faiss	28	0	11
2007	test_sw_dev_faiss	29	0	11
2008	test_sw_dev_faiss	30	0	11
3059	phase1_temp_1761089478883_rjy0nk1ah	13	0	18
3060	phase1_temp_1761089478883_rjy0nk1ah	14	0	18
3061	phase1_temp_1761089478883_rjy0nk1ah	15	0	18
3062	phase1_temp_1761089478883_rjy0nk1ah	16	1	18
3063	phase1_temp_1761089478883_rjy0nk1ah	17	1	18
3064	phase1_temp_1761089478883_rjy0nk1ah	18	4	18
3065	phase1_temp_1761089478883_rjy0nk1ah	19	4	18
3066	phase1_temp_1761089478883_rjy0nk1ah	20	1	18
3067	phase1_temp_1761089478883_rjy0nk1ah	21	0	18
3068	phase1_temp_1761089478883_rjy0nk1ah	22	0	18
3069	phase1_temp_1761089478883_rjy0nk1ah	23	0	18
3070	phase1_temp_1761089478883_rjy0nk1ah	24	0	18
3071	phase1_temp_1761089478883_rjy0nk1ah	25	0	18
3072	phase1_temp_1761089478883_rjy0nk1ah	26	0	18
2837	phase1_temp_1761080585221_a9rn20mov	1	0	16
2838	phase1_temp_1761080585221_a9rn20mov	2	0	16
2839	phase1_temp_1761080585221_a9rn20mov	3	0	16
2840	phase1_temp_1761080585221_a9rn20mov	4	0	16
2841	phase1_temp_1761080585221_a9rn20mov	5	0	16
2842	phase1_temp_1761080585221_a9rn20mov	6	0	16
2843	phase1_temp_1761080585221_a9rn20mov	7	0	16
2844	phase1_temp_1761080585221_a9rn20mov	8	0	16
2845	phase1_temp_1761080585221_a9rn20mov	9	0	16
2846	phase1_temp_1761080585221_a9rn20mov	10	0	16
2847	phase1_temp_1761080585221_a9rn20mov	11	0	16
2848	phase1_temp_1761080585221_a9rn20mov	12	0	16
2849	phase1_temp_1761080585221_a9rn20mov	13	0	16
2850	phase1_temp_1761080585221_a9rn20mov	14	0	16
2851	phase1_temp_1761080585221_a9rn20mov	15	0	16
2852	phase1_temp_1761080585221_a9rn20mov	16	1	16
2853	phase1_temp_1761080585221_a9rn20mov	17	2	16
2854	phase1_temp_1761080585221_a9rn20mov	18	4	16
2855	phase1_temp_1761080585221_a9rn20mov	19	4	16
2856	phase1_temp_1761080585221_a9rn20mov	20	1	16
2857	phase1_temp_1761080585221_a9rn20mov	21	2	16
2858	phase1_temp_1761080585221_a9rn20mov	22	0	16
2859	phase1_temp_1761080585221_a9rn20mov	23	0	16
2860	phase1_temp_1761080585221_a9rn20mov	24	0	16
2861	phase1_temp_1761080585221_a9rn20mov	25	0	16
2862	phase1_temp_1761080585221_a9rn20mov	26	0	16
2069	phase1_temp_1761071366657_vycue5okr	1	0	16
2070	phase1_temp_1761071366657_vycue5okr	2	0	16
2071	phase1_temp_1761071366657_vycue5okr	3	0	16
2072	phase1_temp_1761071366657_vycue5okr	4	0	16
2073	phase1_temp_1761071366657_vycue5okr	5	0	16
2074	phase1_temp_1761071366657_vycue5okr	6	0	16
2075	phase1_temp_1761071366657_vycue5okr	7	0	16
2076	phase1_temp_1761071366657_vycue5okr	8	0	16
2077	phase1_temp_1761071366657_vycue5okr	9	0	16
2078	phase1_temp_1761071366657_vycue5okr	10	0	16
2079	phase1_temp_1761071366657_vycue5okr	11	0	16
2080	phase1_temp_1761071366657_vycue5okr	12	0	16
2081	phase1_temp_1761071366657_vycue5okr	13	0	16
2082	phase1_temp_1761071366657_vycue5okr	14	0	16
2083	phase1_temp_1761071366657_vycue5okr	15	0	16
2084	phase1_temp_1761071366657_vycue5okr	16	0	16
2085	phase1_temp_1761071366657_vycue5okr	17	0	16
2086	phase1_temp_1761071366657_vycue5okr	18	0	16
2087	phase1_temp_1761071366657_vycue5okr	19	0	16
2088	phase1_temp_1761071366657_vycue5okr	20	0	16
2089	phase1_temp_1761071366657_vycue5okr	21	0	16
2090	phase1_temp_1761071366657_vycue5okr	22	0	16
2091	phase1_temp_1761071366657_vycue5okr	23	0	16
2092	phase1_temp_1761071366657_vycue5okr	24	0	16
2093	phase1_temp_1761071366657_vycue5okr	25	0	16
2094	phase1_temp_1761071366657_vycue5okr	26	0	16
2095	phase1_temp_1761071366657_vycue5okr	27	0	16
2096	phase1_temp_1761071366657_vycue5okr	28	0	16
2097	phase1_temp_1761071366657_vycue5okr	29	0	16
2098	phase1_temp_1761071366657_vycue5okr	30	0	16
2099	phase1_temp_1761071375895_60ag35lq0	1	0	16
2100	phase1_temp_1761071375895_60ag35lq0	2	0	16
2101	phase1_temp_1761071375895_60ag35lq0	3	0	16
2102	phase1_temp_1761071375895_60ag35lq0	4	0	16
2103	phase1_temp_1761071375895_60ag35lq0	5	0	16
2104	phase1_temp_1761071375895_60ag35lq0	6	0	16
2105	phase1_temp_1761071375895_60ag35lq0	7	0	16
2106	phase1_temp_1761071375895_60ag35lq0	8	0	16
2107	phase1_temp_1761071375895_60ag35lq0	9	0	16
2108	phase1_temp_1761071375895_60ag35lq0	10	0	16
2109	phase1_temp_1761071375895_60ag35lq0	11	0	16
2110	phase1_temp_1761071375895_60ag35lq0	12	0	16
2111	phase1_temp_1761071375895_60ag35lq0	13	0	16
2112	phase1_temp_1761071375895_60ag35lq0	14	0	16
2113	phase1_temp_1761071375895_60ag35lq0	15	0	16
2114	phase1_temp_1761071375895_60ag35lq0	16	0	16
2115	phase1_temp_1761071375895_60ag35lq0	17	0	16
2116	phase1_temp_1761071375895_60ag35lq0	18	0	16
2117	phase1_temp_1761071375895_60ag35lq0	19	0	16
2118	phase1_temp_1761071375895_60ag35lq0	20	0	16
2119	phase1_temp_1761071375895_60ag35lq0	21	0	16
2120	phase1_temp_1761071375895_60ag35lq0	22	0	16
2121	phase1_temp_1761071375895_60ag35lq0	23	0	16
2122	phase1_temp_1761071375895_60ag35lq0	24	0	16
2123	phase1_temp_1761071375895_60ag35lq0	25	0	16
2124	phase1_temp_1761071375895_60ag35lq0	26	0	16
2125	phase1_temp_1761071375895_60ag35lq0	27	0	16
2126	phase1_temp_1761071375895_60ag35lq0	28	0	16
2127	phase1_temp_1761071375895_60ag35lq0	29	0	16
2128	phase1_temp_1761071375895_60ag35lq0	30	0	16
2129	phase1_temp_1761071384786_qoj0q05nw	1	0	16
2130	phase1_temp_1761071384786_qoj0q05nw	2	0	16
2131	phase1_temp_1761071384786_qoj0q05nw	3	0	16
2132	phase1_temp_1761071384786_qoj0q05nw	4	0	16
2133	phase1_temp_1761071384786_qoj0q05nw	5	0	16
2134	phase1_temp_1761071384786_qoj0q05nw	6	0	16
2135	phase1_temp_1761071384786_qoj0q05nw	7	0	16
2136	phase1_temp_1761071384786_qoj0q05nw	8	0	16
2137	phase1_temp_1761071384786_qoj0q05nw	9	0	16
2138	phase1_temp_1761071384786_qoj0q05nw	10	0	16
2139	phase1_temp_1761071384786_qoj0q05nw	11	0	16
2140	phase1_temp_1761071384786_qoj0q05nw	12	0	16
2141	phase1_temp_1761071384786_qoj0q05nw	13	0	16
2142	phase1_temp_1761071384786_qoj0q05nw	14	0	16
2143	phase1_temp_1761071384786_qoj0q05nw	15	0	16
2144	phase1_temp_1761071384786_qoj0q05nw	16	0	16
2145	phase1_temp_1761071384786_qoj0q05nw	17	0	16
2146	phase1_temp_1761071384786_qoj0q05nw	18	0	16
2147	phase1_temp_1761071384786_qoj0q05nw	19	0	16
2148	phase1_temp_1761071384786_qoj0q05nw	20	0	16
2149	phase1_temp_1761071384786_qoj0q05nw	21	0	16
2150	phase1_temp_1761071384786_qoj0q05nw	22	0	16
2151	phase1_temp_1761071384786_qoj0q05nw	23	0	16
2152	phase1_temp_1761071384786_qoj0q05nw	24	0	16
2153	phase1_temp_1761071384786_qoj0q05nw	25	0	16
2154	phase1_temp_1761071384786_qoj0q05nw	26	0	16
2155	phase1_temp_1761071384786_qoj0q05nw	27	0	16
2156	phase1_temp_1761071384786_qoj0q05nw	28	0	16
2157	phase1_temp_1761071384786_qoj0q05nw	29	0	16
2158	phase1_temp_1761071384786_qoj0q05nw	30	0	16
2159	phase1_temp_1761071395139_7629y4n49	1	0	16
2160	phase1_temp_1761071395139_7629y4n49	2	0	16
2161	phase1_temp_1761071395139_7629y4n49	3	0	16
2162	phase1_temp_1761071395139_7629y4n49	4	0	16
2163	phase1_temp_1761071395139_7629y4n49	5	0	16
2164	phase1_temp_1761071395139_7629y4n49	6	0	16
2165	phase1_temp_1761071395139_7629y4n49	7	0	16
2166	phase1_temp_1761071395139_7629y4n49	8	0	16
2167	phase1_temp_1761071395139_7629y4n49	9	0	16
2168	phase1_temp_1761071395139_7629y4n49	10	0	16
2169	phase1_temp_1761071395139_7629y4n49	11	0	16
2170	phase1_temp_1761071395139_7629y4n49	12	0	16
2171	phase1_temp_1761071395139_7629y4n49	13	0	16
2172	phase1_temp_1761071395139_7629y4n49	14	0	16
2173	phase1_temp_1761071395139_7629y4n49	15	0	16
2174	phase1_temp_1761071395139_7629y4n49	16	0	16
2175	phase1_temp_1761071395139_7629y4n49	17	0	16
2176	phase1_temp_1761071395139_7629y4n49	18	0	16
2177	phase1_temp_1761071395139_7629y4n49	19	0	16
2178	phase1_temp_1761071395139_7629y4n49	20	0	16
2179	phase1_temp_1761071395139_7629y4n49	21	0	16
2180	phase1_temp_1761071395139_7629y4n49	22	0	16
2181	phase1_temp_1761071395139_7629y4n49	23	0	16
2182	phase1_temp_1761071395139_7629y4n49	24	0	16
2183	phase1_temp_1761071395139_7629y4n49	25	0	16
2184	phase1_temp_1761071395139_7629y4n49	26	0	16
2185	phase1_temp_1761071395139_7629y4n49	27	0	16
2186	phase1_temp_1761071395139_7629y4n49	28	0	16
2187	phase1_temp_1761071395139_7629y4n49	29	0	16
2188	phase1_temp_1761071395139_7629y4n49	30	0	16
2189	phase1_temp_1761071402915_9wceu3zya	1	0	16
2190	phase1_temp_1761071402915_9wceu3zya	2	0	16
2191	phase1_temp_1761071402915_9wceu3zya	3	0	16
2192	phase1_temp_1761071402915_9wceu3zya	4	0	16
2193	phase1_temp_1761071402915_9wceu3zya	5	0	16
2194	phase1_temp_1761071402915_9wceu3zya	6	0	16
2195	phase1_temp_1761071402915_9wceu3zya	7	0	16
2196	phase1_temp_1761071402915_9wceu3zya	8	0	16
2197	phase1_temp_1761071402915_9wceu3zya	9	0	16
2198	phase1_temp_1761071402915_9wceu3zya	10	0	16
2199	phase1_temp_1761071402915_9wceu3zya	11	0	16
2200	phase1_temp_1761071402915_9wceu3zya	12	0	16
2201	phase1_temp_1761071402915_9wceu3zya	13	0	16
2202	phase1_temp_1761071402915_9wceu3zya	14	0	16
2203	phase1_temp_1761071402915_9wceu3zya	15	0	16
2204	phase1_temp_1761071402915_9wceu3zya	16	0	16
2205	phase1_temp_1761071402915_9wceu3zya	17	0	16
2206	phase1_temp_1761071402915_9wceu3zya	18	0	16
2207	phase1_temp_1761071402915_9wceu3zya	19	0	16
2208	phase1_temp_1761071402915_9wceu3zya	20	0	16
2209	phase1_temp_1761071402915_9wceu3zya	21	0	16
2210	phase1_temp_1761071402915_9wceu3zya	22	0	16
2211	phase1_temp_1761071402915_9wceu3zya	23	0	16
2212	phase1_temp_1761071402915_9wceu3zya	24	0	16
2213	phase1_temp_1761071402915_9wceu3zya	25	0	16
2214	phase1_temp_1761071402915_9wceu3zya	26	0	16
2215	phase1_temp_1761071402915_9wceu3zya	27	0	16
2216	phase1_temp_1761071402915_9wceu3zya	28	0	16
2217	phase1_temp_1761071402915_9wceu3zya	29	0	16
2218	phase1_temp_1761071402915_9wceu3zya	30	0	16
2219	test_role_suggestion_user	1	0	11
2220	test_role_suggestion_user	2	0	11
2221	test_role_suggestion_user	3	0	11
2222	test_role_suggestion_user	4	0	11
2223	test_role_suggestion_user	5	0	11
2224	test_role_suggestion_user	6	0	11
2225	test_role_suggestion_user	7	0	11
2226	test_role_suggestion_user	8	0	11
2227	test_role_suggestion_user	9	0	11
2228	test_role_suggestion_user	10	0	11
2229	test_role_suggestion_user	11	0	11
2230	test_role_suggestion_user	12	0	11
2231	test_role_suggestion_user	13	0	11
2232	test_role_suggestion_user	14	0	11
2233	test_role_suggestion_user	15	0	11
2234	test_role_suggestion_user	16	0	11
2235	test_role_suggestion_user	17	0	11
2236	test_role_suggestion_user	18	0	11
2237	test_role_suggestion_user	19	0	11
2238	test_role_suggestion_user	20	0	11
2239	test_role_suggestion_user	21	0	11
2240	test_role_suggestion_user	22	0	11
2241	test_role_suggestion_user	23	0	11
2242	test_role_suggestion_user	24	0	11
2243	test_role_suggestion_user	25	0	11
2244	test_role_suggestion_user	26	0	11
2245	test_role_suggestion_user	27	0	11
2246	test_role_suggestion_user	28	0	11
2247	test_role_suggestion_user	29	0	11
2248	test_role_suggestion_user	30	0	11
2863	phase1_temp_1761080585221_a9rn20mov	27	0	16
2864	phase1_temp_1761080585221_a9rn20mov	28	0	16
2865	phase1_temp_1761080585221_a9rn20mov	29	0	16
2866	phase1_temp_1761080585221_a9rn20mov	30	0	16
2867	phase1_temp_1761081052624_0ymt33gyc	1	0	16
2868	phase1_temp_1761081052624_0ymt33gyc	2	0	16
2869	phase1_temp_1761081052624_0ymt33gyc	3	0	16
2870	phase1_temp_1761081052624_0ymt33gyc	4	0	16
2871	phase1_temp_1761081052624_0ymt33gyc	5	0	16
2872	phase1_temp_1761081052624_0ymt33gyc	6	0	16
2873	phase1_temp_1761081052624_0ymt33gyc	7	0	16
2874	phase1_temp_1761081052624_0ymt33gyc	8	0	16
2875	phase1_temp_1761081052624_0ymt33gyc	9	0	16
2876	phase1_temp_1761081052624_0ymt33gyc	10	0	16
2877	phase1_temp_1761081052624_0ymt33gyc	11	1	16
2878	phase1_temp_1761081052624_0ymt33gyc	12	0	16
2879	phase1_temp_1761081052624_0ymt33gyc	13	0	16
2880	phase1_temp_1761081052624_0ymt33gyc	14	0	16
2881	phase1_temp_1761081052624_0ymt33gyc	15	0	16
2882	phase1_temp_1761081052624_0ymt33gyc	16	1	16
2883	phase1_temp_1761081052624_0ymt33gyc	17	1	16
2884	phase1_temp_1761081052624_0ymt33gyc	18	4	16
2885	phase1_temp_1761081052624_0ymt33gyc	19	4	16
2886	phase1_temp_1761081052624_0ymt33gyc	20	1	16
2887	phase1_temp_1761081052624_0ymt33gyc	21	0	16
2888	phase1_temp_1761081052624_0ymt33gyc	22	0	16
2889	phase1_temp_1761081052624_0ymt33gyc	23	0	16
2890	phase1_temp_1761081052624_0ymt33gyc	24	0	16
2891	phase1_temp_1761081052624_0ymt33gyc	25	0	16
2892	phase1_temp_1761081052624_0ymt33gyc	26	0	16
2893	phase1_temp_1761081052624_0ymt33gyc	27	0	16
2894	phase1_temp_1761081052624_0ymt33gyc	28	0	16
2895	phase1_temp_1761081052624_0ymt33gyc	29	0	16
2896	phase1_temp_1761081052624_0ymt33gyc	30	0	16
2897	phase1_temp_1761081062471_88kplr0oc	1	0	16
2898	phase1_temp_1761081062471_88kplr0oc	2	0	16
2899	phase1_temp_1761081062471_88kplr0oc	3	0	16
2900	phase1_temp_1761081062471_88kplr0oc	4	0	16
2901	phase1_temp_1761081062471_88kplr0oc	5	0	16
2902	phase1_temp_1761081062471_88kplr0oc	6	0	16
2903	phase1_temp_1761081062471_88kplr0oc	7	1	16
2904	phase1_temp_1761081062471_88kplr0oc	8	0	16
2905	phase1_temp_1761081062471_88kplr0oc	9	0	16
2906	phase1_temp_1761081062471_88kplr0oc	10	0	16
2907	phase1_temp_1761081062471_88kplr0oc	11	0	16
2908	phase1_temp_1761081062471_88kplr0oc	12	0	16
2909	phase1_temp_1761081062471_88kplr0oc	13	0	16
2910	phase1_temp_1761081062471_88kplr0oc	14	1	16
2911	phase1_temp_1761081062471_88kplr0oc	15	0	16
2912	phase1_temp_1761081062471_88kplr0oc	16	0	16
2913	phase1_temp_1761081062471_88kplr0oc	17	0	16
2914	phase1_temp_1761081062471_88kplr0oc	18	0	16
2915	phase1_temp_1761081062471_88kplr0oc	19	0	16
46	test_dev_user_final	18	4	1
47	test_dev_user_final	19	4	1
286	phase1_temp_1761057021036_74cqxdcfq	18	4	16
287	phase1_temp_1761057021036_74cqxdcfq	19	4	16
316	phase1_temp_1761057030704_hbwtow498	18	4	16
317	phase1_temp_1761057030704_hbwtow498	19	4	16
436	phase1_temp_1761058418802_i0r81j20u	18	4	16
437	phase1_temp_1761058418802_i0r81j20u	19	4	16
496	phase1_temp_1761058437297_6rn30413r	18	4	16
497	phase1_temp_1761058437297_6rn30413r	19	4	16
556	phase1_temp_1761058857887_jq1gjvhfe	18	4	16
557	phase1_temp_1761058857887_jq1gjvhfe	19	4	16
616	phase1_temp_1761058880386_uewnxr99n	18	4	16
617	phase1_temp_1761058880386_uewnxr99n	19	4	16
647	phase1_temp_1761058892469_dkvv4jw2w	19	4	16
706	phase1_temp_1761061461738_5nzjxk66a	18	4	16
707	phase1_temp_1761061461738_5nzjxk66a	19	4	16
737	phase1_temp_1761061469190_c1ndkxpzj	19	4	16
856	phase1_temp_1761062683560_lefw4cz6n	18	4	16
857	phase1_temp_1761062683560_lefw4cz6n	19	4	16
887	phase1_temp_1761062690705_zo4swt982	19	4	16
1096	phase1_temp_1761063428009_9w44gmbtu	18	4	16
1126	phase1_temp_1761063435278_hp7acer76	18	4	16
1127	phase1_temp_1761063435278_hp7acer76	19	4	16
1156	phase1_temp_1761064141578_pup8hlew7	18	4	16
1157	phase1_temp_1761064141578_pup8hlew7	19	4	16
1186	phase1_temp_1761064149514_9taacpaas	18	4	16
1187	phase1_temp_1761064149514_9taacpaas	19	4	16
1217	phase1_temp_1761064157722_qm1j25eg0	19	4	16
2506	e2e_test_user	30	0	11
1277	phase1_temp_1761064170989_4jumw966c	19	4	16
1306	phase1_temp_1761064575744_haxprvrhs	18	4	16
1307	phase1_temp_1761064575744_haxprvrhs	19	4	16
1337	phase1_temp_1761064584793_myi9fjk1m	19	4	16
1456	phase1_temp_1761065301703_juefozczj	18	4	16
1457	phase1_temp_1761065301703_juefozczj	19	4	16
1666	phase1_temp_1761066471322_og7qw5ixe	18	4	16
1667	phase1_temp_1761066471322_og7qw5ixe	19	4	16
1696	phase1_temp_1761066480657_nm72hejhf	18	4	16
1697	phase1_temp_1761066480657_nm72hejhf	19	4	16
1727	phase1_temp_1761066488385_h3r2r3fef	19	4	16
1757	phase1_temp_1761066496450_nbqr68c4z	19	4	16
2387	debug_test_user	1	0	11
2388	debug_test_user	2	0	11
2389	debug_test_user	3	0	11
2390	debug_test_user	4	0	11
2391	debug_test_user	5	0	11
2392	debug_test_user	6	0	11
2393	debug_test_user	7	0	11
2394	debug_test_user	8	0	11
2395	debug_test_user	9	0	11
2396	debug_test_user	10	0	11
2397	debug_test_user	11	0	11
2398	debug_test_user	12	0	11
2399	debug_test_user	13	0	11
2400	debug_test_user	14	0	11
2401	debug_test_user	15	0	11
2402	debug_test_user	16	0	11
2403	debug_test_user	17	0	11
2404	debug_test_user	18	0	11
2405	debug_test_user	19	4	11
2406	debug_test_user	20	0	11
2407	debug_test_user	21	2	11
2408	debug_test_user	22	0	11
2409	debug_test_user	23	0	11
2410	debug_test_user	24	0	11
2411	debug_test_user	25	0	11
2412	debug_test_user	26	0	11
2413	debug_test_user	27	0	11
2414	debug_test_user	28	0	11
2415	debug_test_user	29	0	11
2416	debug_test_user	30	0	11
2477	e2e_test_user	1	0	11
2478	e2e_test_user	2	0	11
2479	e2e_test_user	3	0	11
2480	e2e_test_user	4	0	11
2481	e2e_test_user	5	0	11
2482	e2e_test_user	6	0	11
2483	e2e_test_user	7	0	11
2484	e2e_test_user	8	0	11
2485	e2e_test_user	9	0	11
2486	e2e_test_user	10	0	11
2487	e2e_test_user	11	0	11
2488	e2e_test_user	12	0	11
2489	e2e_test_user	13	0	11
2490	e2e_test_user	14	0	11
2491	e2e_test_user	15	0	11
2492	e2e_test_user	16	1	11
2493	e2e_test_user	17	2	11
2494	e2e_test_user	18	4	11
2495	e2e_test_user	19	4	11
2496	e2e_test_user	20	1	11
2497	e2e_test_user	21	0	11
2498	e2e_test_user	22	0	11
2499	e2e_test_user	23	1	11
2500	e2e_test_user	24	0	11
2501	e2e_test_user	25	1	11
2502	e2e_test_user	26	0	11
2503	e2e_test_user	27	0	11
2504	e2e_test_user	28	0	11
2505	e2e_test_user	29	0	11
2507	phase1_temp_1761076421752_dbnyodnuc	1	0	16
2508	phase1_temp_1761076421752_dbnyodnuc	2	0	16
2509	phase1_temp_1761076421752_dbnyodnuc	3	0	16
2510	phase1_temp_1761076421752_dbnyodnuc	4	0	16
2511	phase1_temp_1761076421752_dbnyodnuc	5	0	16
2512	phase1_temp_1761076421752_dbnyodnuc	6	0	16
2513	phase1_temp_1761076421752_dbnyodnuc	7	0	16
2514	phase1_temp_1761076421752_dbnyodnuc	8	0	16
2515	phase1_temp_1761076421752_dbnyodnuc	9	0	16
2516	phase1_temp_1761076421752_dbnyodnuc	10	0	16
2517	phase1_temp_1761076421752_dbnyodnuc	11	0	16
2518	phase1_temp_1761076421752_dbnyodnuc	12	0	16
2519	phase1_temp_1761076421752_dbnyodnuc	13	0	16
2520	phase1_temp_1761076421752_dbnyodnuc	14	0	16
2521	phase1_temp_1761076421752_dbnyodnuc	15	0	16
2522	phase1_temp_1761076421752_dbnyodnuc	16	0	16
2523	phase1_temp_1761076421752_dbnyodnuc	17	0	16
2524	phase1_temp_1761076421752_dbnyodnuc	18	0	16
2525	phase1_temp_1761076421752_dbnyodnuc	19	4	16
2526	phase1_temp_1761076421752_dbnyodnuc	20	0	16
2527	phase1_temp_1761076421752_dbnyodnuc	21	2	16
2528	phase1_temp_1761076421752_dbnyodnuc	22	0	16
2529	phase1_temp_1761076421752_dbnyodnuc	23	0	16
2530	phase1_temp_1761076421752_dbnyodnuc	24	0	16
2531	phase1_temp_1761076421752_dbnyodnuc	25	0	16
2532	phase1_temp_1761076421752_dbnyodnuc	26	0	16
2533	phase1_temp_1761076421752_dbnyodnuc	27	0	16
2534	phase1_temp_1761076421752_dbnyodnuc	28	0	16
2535	phase1_temp_1761076421752_dbnyodnuc	29	0	16
2536	phase1_temp_1761076421752_dbnyodnuc	30	0	16
2537	phase1_temp_1761078186663_izzurhsx4	1	0	16
2538	phase1_temp_1761078186663_izzurhsx4	2	0	16
2539	phase1_temp_1761078186663_izzurhsx4	3	0	16
2540	phase1_temp_1761078186663_izzurhsx4	4	0	16
2541	phase1_temp_1761078186663_izzurhsx4	5	0	16
2542	phase1_temp_1761078186663_izzurhsx4	6	0	16
2543	phase1_temp_1761078186663_izzurhsx4	7	0	16
2544	phase1_temp_1761078186663_izzurhsx4	8	0	16
2545	phase1_temp_1761078186663_izzurhsx4	9	0	16
2546	phase1_temp_1761078186663_izzurhsx4	10	0	16
2547	phase1_temp_1761078186663_izzurhsx4	11	0	16
2548	phase1_temp_1761078186663_izzurhsx4	12	0	16
2549	phase1_temp_1761078186663_izzurhsx4	13	0	16
2550	phase1_temp_1761078186663_izzurhsx4	14	0	16
2551	phase1_temp_1761078186663_izzurhsx4	15	0	16
2552	phase1_temp_1761078186663_izzurhsx4	16	0	16
2553	phase1_temp_1761078186663_izzurhsx4	17	0	16
2554	phase1_temp_1761078186663_izzurhsx4	18	0	16
2555	phase1_temp_1761078186663_izzurhsx4	19	4	16
2556	phase1_temp_1761078186663_izzurhsx4	20	0	16
2557	phase1_temp_1761078186663_izzurhsx4	21	2	16
2558	phase1_temp_1761078186663_izzurhsx4	22	0	16
2559	phase1_temp_1761078186663_izzurhsx4	23	0	16
2560	phase1_temp_1761078186663_izzurhsx4	24	0	16
2561	phase1_temp_1761078186663_izzurhsx4	25	0	16
2562	phase1_temp_1761078186663_izzurhsx4	26	0	16
2563	phase1_temp_1761078186663_izzurhsx4	27	0	16
2564	phase1_temp_1761078186663_izzurhsx4	28	0	16
2565	phase1_temp_1761078186663_izzurhsx4	29	0	16
2566	phase1_temp_1761078186663_izzurhsx4	30	0	16
2567	phase1_temp_1761078196076_fk7i9uhr8	1	0	16
2568	phase1_temp_1761078196076_fk7i9uhr8	2	0	16
2569	phase1_temp_1761078196076_fk7i9uhr8	3	0	16
2570	phase1_temp_1761078196076_fk7i9uhr8	4	0	16
2571	phase1_temp_1761078196076_fk7i9uhr8	5	0	16
2572	phase1_temp_1761078196076_fk7i9uhr8	6	0	16
2573	phase1_temp_1761078196076_fk7i9uhr8	7	0	16
2574	phase1_temp_1761078196076_fk7i9uhr8	8	0	16
2575	phase1_temp_1761078196076_fk7i9uhr8	9	0	16
2576	phase1_temp_1761078196076_fk7i9uhr8	10	0	16
2577	phase1_temp_1761078196076_fk7i9uhr8	11	1	16
2578	phase1_temp_1761078196076_fk7i9uhr8	12	0	16
2579	phase1_temp_1761078196076_fk7i9uhr8	13	0	16
2580	phase1_temp_1761078196076_fk7i9uhr8	14	0	16
2581	phase1_temp_1761078196076_fk7i9uhr8	15	0	16
2582	phase1_temp_1761078196076_fk7i9uhr8	16	1	16
2583	phase1_temp_1761078196076_fk7i9uhr8	17	1	16
2584	phase1_temp_1761078196076_fk7i9uhr8	18	4	16
2585	phase1_temp_1761078196076_fk7i9uhr8	19	4	16
2586	phase1_temp_1761078196076_fk7i9uhr8	20	1	16
2587	phase1_temp_1761078196076_fk7i9uhr8	21	0	16
2588	phase1_temp_1761078196076_fk7i9uhr8	22	0	16
2589	phase1_temp_1761078196076_fk7i9uhr8	23	0	16
2590	phase1_temp_1761078196076_fk7i9uhr8	24	0	16
2591	phase1_temp_1761078196076_fk7i9uhr8	25	0	16
2592	phase1_temp_1761078196076_fk7i9uhr8	26	0	16
2593	phase1_temp_1761078196076_fk7i9uhr8	27	0	16
2594	phase1_temp_1761078196076_fk7i9uhr8	28	0	16
2595	phase1_temp_1761078196076_fk7i9uhr8	29	0	16
2596	phase1_temp_1761078196076_fk7i9uhr8	30	0	16
2597	phase1_temp_1761078205299_50ue3pgd6	1	0	16
2598	phase1_temp_1761078205299_50ue3pgd6	2	0	16
2599	phase1_temp_1761078205299_50ue3pgd6	3	0	16
2600	phase1_temp_1761078205299_50ue3pgd6	4	0	16
2601	phase1_temp_1761078205299_50ue3pgd6	5	0	16
2602	phase1_temp_1761078205299_50ue3pgd6	6	0	16
2603	phase1_temp_1761078205299_50ue3pgd6	7	1	16
2604	phase1_temp_1761078205299_50ue3pgd6	8	0	16
2605	phase1_temp_1761078205299_50ue3pgd6	9	0	16
2606	phase1_temp_1761078205299_50ue3pgd6	10	0	16
2607	phase1_temp_1761078205299_50ue3pgd6	11	0	16
2608	phase1_temp_1761078205299_50ue3pgd6	12	0	16
2609	phase1_temp_1761078205299_50ue3pgd6	13	0	16
2610	phase1_temp_1761078205299_50ue3pgd6	14	1	16
2611	phase1_temp_1761078205299_50ue3pgd6	15	0	16
2612	phase1_temp_1761078205299_50ue3pgd6	16	0	16
2613	phase1_temp_1761078205299_50ue3pgd6	17	0	16
2614	phase1_temp_1761078205299_50ue3pgd6	18	0	16
2615	phase1_temp_1761078205299_50ue3pgd6	19	0	16
2616	phase1_temp_1761078205299_50ue3pgd6	20	0	16
2617	phase1_temp_1761078205299_50ue3pgd6	21	0	16
2618	phase1_temp_1761078205299_50ue3pgd6	22	0	16
2619	phase1_temp_1761078205299_50ue3pgd6	23	2	16
2620	phase1_temp_1761078205299_50ue3pgd6	24	0	16
2621	phase1_temp_1761078205299_50ue3pgd6	25	0	16
2622	phase1_temp_1761078205299_50ue3pgd6	26	0	16
2623	phase1_temp_1761078205299_50ue3pgd6	27	0	16
2624	phase1_temp_1761078205299_50ue3pgd6	28	0	16
2625	phase1_temp_1761078205299_50ue3pgd6	29	0	16
2626	phase1_temp_1761078205299_50ue3pgd6	30	0	16
2627	phase1_temp_1761078213117_euvzag1wq	1	0	16
2628	phase1_temp_1761078213117_euvzag1wq	2	0	16
2629	phase1_temp_1761078213117_euvzag1wq	3	0	16
2630	phase1_temp_1761078213117_euvzag1wq	4	0	16
2631	phase1_temp_1761078213117_euvzag1wq	5	0	16
2632	phase1_temp_1761078213117_euvzag1wq	6	0	16
2633	phase1_temp_1761078213117_euvzag1wq	7	0	16
2634	phase1_temp_1761078213117_euvzag1wq	8	2	16
2635	phase1_temp_1761078213117_euvzag1wq	9	2	16
2636	phase1_temp_1761078213117_euvzag1wq	10	1	16
2637	phase1_temp_1761078213117_euvzag1wq	11	2	16
2638	phase1_temp_1761078213117_euvzag1wq	12	0	16
2639	phase1_temp_1761078213117_euvzag1wq	13	0	16
2640	phase1_temp_1761078213117_euvzag1wq	14	0	16
2641	phase1_temp_1761078213117_euvzag1wq	15	0	16
2642	phase1_temp_1761078213117_euvzag1wq	16	0	16
2643	phase1_temp_1761078213117_euvzag1wq	17	0	16
2644	phase1_temp_1761078213117_euvzag1wq	18	0	16
2645	phase1_temp_1761078213117_euvzag1wq	19	0	16
2646	phase1_temp_1761078213117_euvzag1wq	20	1	16
2647	phase1_temp_1761078213117_euvzag1wq	21	0	16
2648	phase1_temp_1761078213117_euvzag1wq	22	0	16
2649	phase1_temp_1761078213117_euvzag1wq	23	0	16
2650	phase1_temp_1761078213117_euvzag1wq	24	0	16
2651	phase1_temp_1761078213117_euvzag1wq	25	0	16
2652	phase1_temp_1761078213117_euvzag1wq	26	0	16
2653	phase1_temp_1761078213117_euvzag1wq	27	0	16
2654	phase1_temp_1761078213117_euvzag1wq	28	0	16
2655	phase1_temp_1761078213117_euvzag1wq	29	0	16
2656	phase1_temp_1761078213117_euvzag1wq	30	0	16
2657	phase1_temp_1761078220613_mgy5fhm9t	1	0	16
2658	phase1_temp_1761078220613_mgy5fhm9t	2	0	16
2659	phase1_temp_1761078220613_mgy5fhm9t	3	0	16
2660	phase1_temp_1761078220613_mgy5fhm9t	4	0	16
2661	phase1_temp_1761078220613_mgy5fhm9t	5	0	16
2662	phase1_temp_1761078220613_mgy5fhm9t	6	0	16
2663	phase1_temp_1761078220613_mgy5fhm9t	7	0	16
2664	phase1_temp_1761078220613_mgy5fhm9t	8	0	16
2665	phase1_temp_1761078220613_mgy5fhm9t	9	0	16
2666	phase1_temp_1761078220613_mgy5fhm9t	10	0	16
2667	phase1_temp_1761078220613_mgy5fhm9t	11	0	16
2668	phase1_temp_1761078220613_mgy5fhm9t	12	0	16
2669	phase1_temp_1761078220613_mgy5fhm9t	13	0	16
2670	phase1_temp_1761078220613_mgy5fhm9t	14	0	16
2671	phase1_temp_1761078220613_mgy5fhm9t	15	0	16
2672	phase1_temp_1761078220613_mgy5fhm9t	16	0	16
2673	phase1_temp_1761078220613_mgy5fhm9t	17	1	16
2674	phase1_temp_1761078220613_mgy5fhm9t	18	1	16
2675	phase1_temp_1761078220613_mgy5fhm9t	19	2	16
2676	phase1_temp_1761078220613_mgy5fhm9t	20	1	16
2677	phase1_temp_1761078220613_mgy5fhm9t	21	0	16
2678	phase1_temp_1761078220613_mgy5fhm9t	22	0	16
2679	phase1_temp_1761078220613_mgy5fhm9t	23	0	16
2680	phase1_temp_1761078220613_mgy5fhm9t	24	0	16
2681	phase1_temp_1761078220613_mgy5fhm9t	25	0	16
2682	phase1_temp_1761078220613_mgy5fhm9t	26	0	16
2683	phase1_temp_1761078220613_mgy5fhm9t	27	0	16
2684	phase1_temp_1761078220613_mgy5fhm9t	28	0	16
2685	phase1_temp_1761078220613_mgy5fhm9t	29	0	16
2686	phase1_temp_1761078220613_mgy5fhm9t	30	0	16
2687	test_llm_vs_euclidean_1761080097_5532	1	0	11
2688	test_llm_vs_euclidean_1761080097_5532	2	0	11
2689	test_llm_vs_euclidean_1761080097_5532	3	0	11
2690	test_llm_vs_euclidean_1761080097_5532	4	0	11
2691	test_llm_vs_euclidean_1761080097_5532	5	0	11
2692	test_llm_vs_euclidean_1761080097_5532	6	0	11
2693	test_llm_vs_euclidean_1761080097_5532	7	0	11
2694	test_llm_vs_euclidean_1761080097_5532	8	0	11
2695	test_llm_vs_euclidean_1761080097_5532	9	0	11
2696	test_llm_vs_euclidean_1761080097_5532	10	0	11
2697	test_llm_vs_euclidean_1761080097_5532	11	0	11
2698	test_llm_vs_euclidean_1761080097_5532	12	0	11
2699	test_llm_vs_euclidean_1761080097_5532	13	0	11
2700	test_llm_vs_euclidean_1761080097_5532	14	0	11
2701	test_llm_vs_euclidean_1761080097_5532	15	0	11
2702	test_llm_vs_euclidean_1761080097_5532	16	0	11
2703	test_llm_vs_euclidean_1761080097_5532	17	0	11
2704	test_llm_vs_euclidean_1761080097_5532	18	0	11
2705	test_llm_vs_euclidean_1761080097_5532	19	4	11
2706	test_llm_vs_euclidean_1761080097_5532	20	0	11
2707	test_llm_vs_euclidean_1761080097_5532	21	2	11
2708	test_llm_vs_euclidean_1761080097_5532	22	2	11
2709	test_llm_vs_euclidean_1761080097_5532	23	1	11
2710	test_llm_vs_euclidean_1761080097_5532	24	0	11
2711	test_llm_vs_euclidean_1761080097_5532	25	0	11
2712	test_llm_vs_euclidean_1761080097_5532	26	0	11
2713	test_llm_vs_euclidean_1761080097_5532	27	0	11
2714	test_llm_vs_euclidean_1761080097_5532	28	0	11
2715	test_llm_vs_euclidean_1761080097_5532	29	0	11
2716	test_llm_vs_euclidean_1761080097_5532	30	0	11
2717	test_llm_vs_euclidean_1761080140_7134	1	0	11
2718	test_llm_vs_euclidean_1761080140_7134	2	0	11
2719	test_llm_vs_euclidean_1761080140_7134	3	0	11
2720	test_llm_vs_euclidean_1761080140_7134	4	0	11
2721	test_llm_vs_euclidean_1761080140_7134	5	0	11
2722	test_llm_vs_euclidean_1761080140_7134	6	0	11
2723	test_llm_vs_euclidean_1761080140_7134	7	0	11
2724	test_llm_vs_euclidean_1761080140_7134	8	0	11
2725	test_llm_vs_euclidean_1761080140_7134	9	0	11
2726	test_llm_vs_euclidean_1761080140_7134	10	0	11
2727	test_llm_vs_euclidean_1761080140_7134	11	0	11
2728	test_llm_vs_euclidean_1761080140_7134	12	0	11
2729	test_llm_vs_euclidean_1761080140_7134	13	0	11
2730	test_llm_vs_euclidean_1761080140_7134	14	0	11
2731	test_llm_vs_euclidean_1761080140_7134	15	0	11
2732	test_llm_vs_euclidean_1761080140_7134	16	0	11
2733	test_llm_vs_euclidean_1761080140_7134	17	0	11
2734	test_llm_vs_euclidean_1761080140_7134	18	4	11
2735	test_llm_vs_euclidean_1761080140_7134	19	4	11
2736	test_llm_vs_euclidean_1761080140_7134	20	0	11
2737	test_llm_vs_euclidean_1761080140_7134	21	2	11
2738	test_llm_vs_euclidean_1761080140_7134	22	0	11
2739	test_llm_vs_euclidean_1761080140_7134	23	0	11
2740	test_llm_vs_euclidean_1761080140_7134	24	0	11
2741	test_llm_vs_euclidean_1761080140_7134	25	0	11
2742	test_llm_vs_euclidean_1761080140_7134	26	0	11
2743	test_llm_vs_euclidean_1761080140_7134	27	0	11
2744	test_llm_vs_euclidean_1761080140_7134	28	0	11
2745	test_llm_vs_euclidean_1761080140_7134	29	0	11
2746	test_llm_vs_euclidean_1761080140_7134	30	0	11
2916	phase1_temp_1761081062471_88kplr0oc	20	0	16
2917	phase1_temp_1761081062471_88kplr0oc	21	0	16
2918	phase1_temp_1761081062471_88kplr0oc	22	0	16
2919	phase1_temp_1761081062471_88kplr0oc	23	2	16
2920	phase1_temp_1761081062471_88kplr0oc	24	0	16
2921	phase1_temp_1761081062471_88kplr0oc	25	0	16
2922	phase1_temp_1761081062471_88kplr0oc	26	0	16
2923	phase1_temp_1761081062471_88kplr0oc	27	0	16
2924	phase1_temp_1761081062471_88kplr0oc	28	0	16
2925	phase1_temp_1761081062471_88kplr0oc	29	0	16
2926	phase1_temp_1761081062471_88kplr0oc	30	0	16
2927	phase1_temp_1761081072810_hp4ajoc0b	1	0	16
2928	phase1_temp_1761081072810_hp4ajoc0b	2	0	16
2929	phase1_temp_1761081072810_hp4ajoc0b	3	0	16
2930	phase1_temp_1761081072810_hp4ajoc0b	4	0	16
2931	phase1_temp_1761081072810_hp4ajoc0b	5	0	16
2932	phase1_temp_1761081072810_hp4ajoc0b	6	0	16
2933	phase1_temp_1761081072810_hp4ajoc0b	7	0	16
2934	phase1_temp_1761081072810_hp4ajoc0b	8	2	16
2935	phase1_temp_1761081072810_hp4ajoc0b	9	2	16
2936	phase1_temp_1761081072810_hp4ajoc0b	10	1	16
2937	phase1_temp_1761081072810_hp4ajoc0b	11	2	16
2938	phase1_temp_1761081072810_hp4ajoc0b	12	0	16
2939	phase1_temp_1761081072810_hp4ajoc0b	13	1	16
2940	phase1_temp_1761081072810_hp4ajoc0b	14	0	16
2941	phase1_temp_1761081072810_hp4ajoc0b	15	0	16
2942	phase1_temp_1761081072810_hp4ajoc0b	16	1	16
2943	phase1_temp_1761081072810_hp4ajoc0b	17	0	16
2944	phase1_temp_1761081072810_hp4ajoc0b	18	0	16
2945	phase1_temp_1761081072810_hp4ajoc0b	19	0	16
2946	phase1_temp_1761081072810_hp4ajoc0b	20	1	16
2947	phase1_temp_1761081072810_hp4ajoc0b	21	0	16
2948	phase1_temp_1761081072810_hp4ajoc0b	22	0	16
2949	phase1_temp_1761081072810_hp4ajoc0b	23	0	16
2950	phase1_temp_1761081072810_hp4ajoc0b	24	0	16
2951	phase1_temp_1761081072810_hp4ajoc0b	25	0	16
2952	phase1_temp_1761081072810_hp4ajoc0b	26	0	16
2953	phase1_temp_1761081072810_hp4ajoc0b	27	0	16
2954	phase1_temp_1761081072810_hp4ajoc0b	28	0	16
2955	phase1_temp_1761081072810_hp4ajoc0b	29	0	16
2956	phase1_temp_1761081072810_hp4ajoc0b	30	0	16
2957	phase1_temp_1761081084534_c7r10cv4l	1	0	16
2958	phase1_temp_1761081084534_c7r10cv4l	2	0	16
2959	phase1_temp_1761081084534_c7r10cv4l	3	0	16
2960	phase1_temp_1761081084534_c7r10cv4l	4	0	16
2961	phase1_temp_1761081084534_c7r10cv4l	5	0	16
2962	phase1_temp_1761081084534_c7r10cv4l	6	0	16
2963	phase1_temp_1761081084534_c7r10cv4l	7	0	16
2964	phase1_temp_1761081084534_c7r10cv4l	8	0	16
2965	phase1_temp_1761081084534_c7r10cv4l	9	0	16
2966	phase1_temp_1761081084534_c7r10cv4l	10	0	16
2967	phase1_temp_1761081084534_c7r10cv4l	11	0	16
2968	phase1_temp_1761081084534_c7r10cv4l	12	0	16
2969	phase1_temp_1761081084534_c7r10cv4l	13	0	16
2970	phase1_temp_1761081084534_c7r10cv4l	14	0	16
2971	phase1_temp_1761081084534_c7r10cv4l	15	0	16
2972	phase1_temp_1761081084534_c7r10cv4l	16	0	16
2973	phase1_temp_1761081084534_c7r10cv4l	17	0	16
2974	phase1_temp_1761081084534_c7r10cv4l	18	1	16
2975	phase1_temp_1761081084534_c7r10cv4l	19	2	16
2976	phase1_temp_1761081084534_c7r10cv4l	20	0	16
2977	phase1_temp_1761081084534_c7r10cv4l	21	0	16
2978	phase1_temp_1761081084534_c7r10cv4l	22	0	16
2979	phase1_temp_1761081084534_c7r10cv4l	23	0	16
2980	phase1_temp_1761081084534_c7r10cv4l	24	0	16
2981	phase1_temp_1761081084534_c7r10cv4l	25	0	16
2982	phase1_temp_1761081084534_c7r10cv4l	26	0	16
2983	phase1_temp_1761081084534_c7r10cv4l	27	0	16
2984	phase1_temp_1761081084534_c7r10cv4l	28	0	16
2985	phase1_temp_1761081084534_c7r10cv4l	29	0	16
2986	phase1_temp_1761081084534_c7r10cv4l	30	0	16
3017	phase1_temp_1761089467953_w1qx12pv2	1	0	18
3018	phase1_temp_1761089467953_w1qx12pv2	2	0	18
3019	phase1_temp_1761089467953_w1qx12pv2	3	0	18
3020	phase1_temp_1761089467953_w1qx12pv2	4	0	18
3021	phase1_temp_1761089467953_w1qx12pv2	5	0	18
3022	phase1_temp_1761089467953_w1qx12pv2	6	0	18
3023	phase1_temp_1761089467953_w1qx12pv2	7	0	18
3024	phase1_temp_1761089467953_w1qx12pv2	8	0	18
3025	phase1_temp_1761089467953_w1qx12pv2	9	0	18
3026	phase1_temp_1761089467953_w1qx12pv2	10	0	18
3027	phase1_temp_1761089467953_w1qx12pv2	11	0	18
3028	phase1_temp_1761089467953_w1qx12pv2	12	0	18
3029	phase1_temp_1761089467953_w1qx12pv2	13	0	18
3030	phase1_temp_1761089467953_w1qx12pv2	14	0	18
3031	phase1_temp_1761089467953_w1qx12pv2	15	0	18
3032	phase1_temp_1761089467953_w1qx12pv2	16	0	18
3033	phase1_temp_1761089467953_w1qx12pv2	17	0	18
3034	phase1_temp_1761089467953_w1qx12pv2	18	1	18
3035	phase1_temp_1761089467953_w1qx12pv2	19	2	18
3036	phase1_temp_1761089467953_w1qx12pv2	20	0	18
3073	phase1_temp_1761089478883_rjy0nk1ah	27	0	18
3074	phase1_temp_1761089478883_rjy0nk1ah	28	0	18
3075	phase1_temp_1761089478883_rjy0nk1ah	29	0	18
3076	phase1_temp_1761089478883_rjy0nk1ah	30	0	18
3077	phase1_temp_1761183318380_zibljjb4o	1	0	20
3078	phase1_temp_1761183318380_zibljjb4o	2	0	20
3079	phase1_temp_1761183318380_zibljjb4o	3	0	20
3080	phase1_temp_1761183318380_zibljjb4o	4	0	20
3081	phase1_temp_1761183318380_zibljjb4o	5	0	20
3082	phase1_temp_1761183318380_zibljjb4o	6	0	20
3083	phase1_temp_1761183318380_zibljjb4o	7	0	20
3084	phase1_temp_1761183318380_zibljjb4o	8	0	20
3085	phase1_temp_1761183318380_zibljjb4o	9	0	20
3086	phase1_temp_1761183318380_zibljjb4o	10	0	20
3087	phase1_temp_1761183318380_zibljjb4o	11	0	20
3088	phase1_temp_1761183318380_zibljjb4o	12	0	20
3089	phase1_temp_1761183318380_zibljjb4o	13	0	20
3090	phase1_temp_1761183318380_zibljjb4o	14	0	20
3091	phase1_temp_1761183318380_zibljjb4o	15	0	20
3092	phase1_temp_1761183318380_zibljjb4o	16	0	20
3093	phase1_temp_1761183318380_zibljjb4o	17	0	20
3094	phase1_temp_1761183318380_zibljjb4o	18	4	20
3095	phase1_temp_1761183318380_zibljjb4o	19	4	20
3096	phase1_temp_1761183318380_zibljjb4o	20	0	20
3097	phase1_temp_1761183318380_zibljjb4o	21	2	20
3098	phase1_temp_1761183318380_zibljjb4o	22	0	20
3099	phase1_temp_1761183318380_zibljjb4o	23	0	20
3100	phase1_temp_1761183318380_zibljjb4o	24	0	20
3101	phase1_temp_1761183318380_zibljjb4o	25	0	20
3102	phase1_temp_1761183318380_zibljjb4o	26	0	20
3103	phase1_temp_1761183318380_zibljjb4o	27	0	20
3104	phase1_temp_1761183318380_zibljjb4o	28	0	20
3105	phase1_temp_1761183318380_zibljjb4o	29	0	20
3106	phase1_temp_1761183318380_zibljjb4o	30	0	20
3107	phase1_temp_1761183329459_83r06dyjq	1	0	20
3108	phase1_temp_1761183329459_83r06dyjq	2	0	20
3109	phase1_temp_1761183329459_83r06dyjq	3	0	20
3110	phase1_temp_1761183329459_83r06dyjq	4	0	20
3111	phase1_temp_1761183329459_83r06dyjq	5	0	20
3112	phase1_temp_1761183329459_83r06dyjq	6	0	20
3113	phase1_temp_1761183329459_83r06dyjq	7	0	20
3114	phase1_temp_1761183329459_83r06dyjq	8	0	20
3115	phase1_temp_1761183329459_83r06dyjq	9	0	20
3116	phase1_temp_1761183329459_83r06dyjq	10	0	20
3117	phase1_temp_1761183329459_83r06dyjq	11	1	20
3118	phase1_temp_1761183329459_83r06dyjq	12	0	20
3119	phase1_temp_1761183329459_83r06dyjq	13	0	20
3120	phase1_temp_1761183329459_83r06dyjq	14	0	20
3121	phase1_temp_1761183329459_83r06dyjq	15	0	20
3122	phase1_temp_1761183329459_83r06dyjq	16	1	20
3123	phase1_temp_1761183329459_83r06dyjq	17	1	20
3124	phase1_temp_1761183329459_83r06dyjq	18	4	20
3125	phase1_temp_1761183329459_83r06dyjq	19	4	20
3126	phase1_temp_1761183329459_83r06dyjq	20	1	20
3127	phase1_temp_1761183329459_83r06dyjq	21	0	20
3128	phase1_temp_1761183329459_83r06dyjq	22	0	20
3129	phase1_temp_1761183329459_83r06dyjq	23	0	20
3130	phase1_temp_1761183329459_83r06dyjq	24	0	20
3131	phase1_temp_1761183329459_83r06dyjq	25	0	20
3132	phase1_temp_1761183329459_83r06dyjq	26	0	20
3133	phase1_temp_1761183329459_83r06dyjq	27	0	20
3134	phase1_temp_1761183329459_83r06dyjq	28	0	20
3135	phase1_temp_1761183329459_83r06dyjq	29	0	20
3136	phase1_temp_1761183329459_83r06dyjq	30	0	20
3137	phase1_temp_1761183338741_u6agh68ox	1	0	20
3138	phase1_temp_1761183338741_u6agh68ox	2	0	20
3139	phase1_temp_1761183338741_u6agh68ox	3	0	20
3140	phase1_temp_1761183338741_u6agh68ox	4	0	20
3141	phase1_temp_1761183338741_u6agh68ox	5	0	20
3142	phase1_temp_1761183338741_u6agh68ox	6	0	20
3143	phase1_temp_1761183338741_u6agh68ox	7	1	20
3144	phase1_temp_1761183338741_u6agh68ox	8	0	20
3145	phase1_temp_1761183338741_u6agh68ox	9	0	20
3146	phase1_temp_1761183338741_u6agh68ox	10	0	20
3147	phase1_temp_1761183338741_u6agh68ox	11	0	20
3148	phase1_temp_1761183338741_u6agh68ox	12	0	20
3149	phase1_temp_1761183338741_u6agh68ox	13	0	20
3150	phase1_temp_1761183338741_u6agh68ox	14	1	20
3151	phase1_temp_1761183338741_u6agh68ox	15	0	20
3152	phase1_temp_1761183338741_u6agh68ox	16	0	20
3153	phase1_temp_1761183338741_u6agh68ox	17	0	20
3154	phase1_temp_1761183338741_u6agh68ox	18	0	20
3155	phase1_temp_1761183338741_u6agh68ox	19	0	20
3156	phase1_temp_1761183338741_u6agh68ox	20	0	20
3157	phase1_temp_1761183338741_u6agh68ox	21	0	20
3158	phase1_temp_1761183338741_u6agh68ox	22	0	20
3159	phase1_temp_1761183338741_u6agh68ox	23	2	20
3160	phase1_temp_1761183338741_u6agh68ox	24	0	20
3161	phase1_temp_1761183338741_u6agh68ox	25	0	20
3162	phase1_temp_1761183338741_u6agh68ox	26	0	20
3163	phase1_temp_1761183338741_u6agh68ox	27	0	20
3164	phase1_temp_1761183338741_u6agh68ox	28	0	20
3165	phase1_temp_1761183338741_u6agh68ox	29	0	20
3166	phase1_temp_1761183338741_u6agh68ox	30	0	20
3167	phase1_temp_1761183348360_zhem1a57f	1	0	20
3168	phase1_temp_1761183348360_zhem1a57f	2	0	20
3169	phase1_temp_1761183348360_zhem1a57f	3	0	20
3170	phase1_temp_1761183348360_zhem1a57f	4	0	20
3171	phase1_temp_1761183348360_zhem1a57f	5	0	20
3172	phase1_temp_1761183348360_zhem1a57f	6	0	20
3173	phase1_temp_1761183348360_zhem1a57f	7	0	20
3174	phase1_temp_1761183348360_zhem1a57f	8	0	20
3175	phase1_temp_1761183348360_zhem1a57f	9	0	20
3176	phase1_temp_1761183348360_zhem1a57f	10	0	20
3177	phase1_temp_1761183348360_zhem1a57f	11	0	20
3178	phase1_temp_1761183348360_zhem1a57f	12	0	20
3179	phase1_temp_1761183348360_zhem1a57f	13	0	20
3180	phase1_temp_1761183348360_zhem1a57f	14	0	20
3181	phase1_temp_1761183348360_zhem1a57f	15	0	20
3182	phase1_temp_1761183348360_zhem1a57f	16	0	20
3183	phase1_temp_1761183348360_zhem1a57f	17	0	20
3184	phase1_temp_1761183348360_zhem1a57f	18	1	20
3185	phase1_temp_1761183348360_zhem1a57f	19	2	20
3186	phase1_temp_1761183348360_zhem1a57f	20	0	20
3187	phase1_temp_1761183348360_zhem1a57f	21	0	20
3188	phase1_temp_1761183348360_zhem1a57f	22	0	20
3189	phase1_temp_1761183348360_zhem1a57f	23	0	20
3190	phase1_temp_1761183348360_zhem1a57f	24	0	20
3191	phase1_temp_1761183348360_zhem1a57f	25	0	20
3192	phase1_temp_1761183348360_zhem1a57f	26	0	20
3193	phase1_temp_1761183348360_zhem1a57f	27	0	20
3194	phase1_temp_1761183348360_zhem1a57f	28	0	20
3195	phase1_temp_1761183348360_zhem1a57f	29	0	20
3196	phase1_temp_1761183348360_zhem1a57f	30	0	20
\.


--
-- Data for Name: user_competency_survey_feedback; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.user_competency_survey_feedback (id, user_id, organization_id, feedback) FROM stdin;
3	5	19	[{"feedbacks": [{"user_strengths": "You are currently unaware of the principles of Systems Thinking, which indicates an opportunity for growth in this foundational area of systems engineering.", "competency_name": "Systems Thinking", "improvement_areas": "To improve your competency in Systems Thinking, consider enrolling in introductory courses or workshops that focus on systems theory and its applications. Engaging with resources such as books or online materials on systems thinking can also help build your foundational knowledge. Additionally, seeking mentorship from experienced systems engineers can provide valuable insights and guidance."}, {"user_strengths": "You demonstrate a strong ability to evaluate concepts regarding lifecycle phases, exceeding the required level for this competency.", "competency_name": "Lifecycle Consideration", "improvement_areas": ""}, {"user_strengths": "You meet the required level by effectively developing systems using agile methodologies with a focus on customer benefit, showcasing your understanding of customer needs.", "competency_name": "Customer / Value Orientation", "improvement_areas": ""}, {"user_strengths": "You have a good understanding of how models support your work and can read simple models, which is a solid foundation for further development.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To advance your competency in Systems Modeling and Analysis, focus on practical exercises that involve creating and defining your own system models. Consider taking courses that cover advanced modeling techniques and tools. Collaborating with peers on modeling projects can also enhance your skills and provide hands-on experience."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You demonstrate an awareness of the importance of communication competencies, which is a foundational step towards developing effective communication skills.", "competency_name": "Communication", "improvement_areas": "To improve your communication skills to the required level, consider engaging in workshops or training focused on effective communication techniques. Practicing active listening and empathy in conversations can also enhance your ability to communicate constructively and efficiently."}, {"user_strengths": "You recognize the necessity of leadership competencies, which is essential for your growth in this area.", "competency_name": "Leadership", "improvement_areas": "To advance your leadership skills, seek opportunities to participate in team projects where you can practice defining objectives and articulating them to your peers. Consider finding a mentor who can provide guidance and feedback on your leadership style and effectiveness."}, {"user_strengths": "You have a solid understanding of how self-organization concepts can influence your daily work, which is a great start towards mastering this competency.", "competency_name": "Self-Organization", "improvement_areas": "To reach the required level of self-organization, focus on developing a structured approach to managing your projects and tasks. You might benefit from using project management tools or techniques, such as time-blocking or the Pomodoro technique, to enhance your ability to independently manage your workload."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have demonstrated strong skills in defining project mandates, establishing conditions, creating complex project plans, and producing meaningful reports. Your ability to communicate effectively with stakeholders is a significant asset.", "competency_name": "Project Management", "improvement_areas": ""}, {"user_strengths": "You possess advanced skills in evaluating decisions and establishing decision-making bodies. Your ability to define guidelines for decision-making is commendable and shows a high level of competence in this area.", "competency_name": "Decision Management", "improvement_areas": ""}, {"user_strengths": "You currently have no awareness or knowledge in this competency area, indicating a starting point for growth.", "competency_name": "Information Management", "improvement_areas": "To improve in Information Management, consider enrolling in training programs focused on knowledge transfer platforms and information sharing practices. Engaging with mentors or colleagues who are experienced in this area can also provide valuable insights."}, {"user_strengths": "You currently have no awareness or knowledge in this competency area, indicating a starting point for growth.", "competency_name": "Configuration Management", "improvement_areas": "To enhance your skills in Configuration Management, seek out resources or training that cover the basics of defining configuration items and the tools used for creating configurations. Collaborating with team members who have experience in this area can also help you gain practical knowledge."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have demonstrated a strong ability to recognize deficiencies in the requirements process and develop suggestions for improvement. Your skills in creating context and interface descriptions and discussing these with stakeholders are commendable, indicating a solid grasp of the requirements definition process.", "competency_name": "Requirements Definition", "improvement_areas": ""}, {"user_strengths": "You possess a good understanding of the relevant process steps for architectural models and can create models of average complexity. Your ability to ensure that the information is reproducible and aligned with methodology and modeling language is a significant strength.", "competency_name": "System Architecting", "improvement_areas": "To further enhance your skills, consider seeking opportunities to work on more complex architectural models. Engaging in hands-on projects or collaborating with experienced architects can provide practical experience. Additionally, studying architectural frameworks and methodologies in depth can deepen your understanding."}, {"user_strengths": "You are capable of reading and understanding test plans, test cases, and results, which is essential for effective integration, verification, and validation processes.", "competency_name": "Integration, Verification, Validation", "improvement_areas": ""}, {"user_strengths": "You have a foundational awareness of the stages of operation, service, and maintenance phases, which is important for considering these aspects during development.", "competency_name": "Operation and Support", "improvement_areas": ""}, {"user_strengths": "You have a basic awareness of Agile values and methods, which is a good starting point for further development in this area.", "competency_name": "Agile Methods", "improvement_areas": "To improve your competency in Agile methods, consider participating in Agile training workshops or certification programs. Engaging in Agile projects, either as a team member or through simulations, can provide practical experience. Additionally, reading books or resources on Agile methodologies can help you understand how to effectively apply these methods in various project scenarios."}], "competency_area": "Technical"}]
4	6	20	[{"feedbacks": [{"user_strengths": "Currently, there are no strengths identified in this competency area as the user is unaware or lacks knowledge.", "competency_name": "Systems Thinking", "improvement_areas": "To improve in Systems Thinking, consider starting with foundational resources such as introductory books or online courses on systems theory. Engaging in discussions or study groups focused on systems thinking can also enhance your understanding of how individual components interact within a system."}, {"user_strengths": "Currently, there are no strengths identified in this competency area as the user is unaware or lacks knowledge.", "competency_name": "Lifecycle Consideration", "improvement_areas": "To develop your understanding of Lifecycle Consideration, seek out training programs or workshops that cover the various phases of a system's lifecycle. Practical experience through projects that require lifecycle analysis can also be beneficial."}, {"user_strengths": "Currently, there are no strengths identified in this competency area as the user is unaware or lacks knowledge.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To enhance your Customer / Value Orientation, consider exploring agile methodologies through online courses or certifications. Participating in agile teams or projects can provide practical experience in integrating agile thinking into your daily work."}, {"user_strengths": "Currently, there are no strengths identified in this competency area as the user is unaware or lacks knowledge.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To improve in Systems Modeling and Analysis, start with basic modeling techniques and tools. Online tutorials or courses that focus on reading and creating simple models can be very helpful. Additionally, collaborating with peers who have experience in modeling can provide valuable insights."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "Currently, you are at the awareness level in communication, which indicates that you recognize the importance of this competency but have not yet developed the necessary skills to communicate effectively and empathetically.", "competency_name": "Communication", "improvement_areas": "To improve your communication skills, consider enrolling in workshops or courses focused on effective communication techniques. Practicing active listening and engaging in role-playing scenarios can also help you develop empathy in your interactions. Additionally, seeking feedback from peers on your communication style can provide valuable insights."}, {"user_strengths": "You demonstrate strong leadership skills, as evidenced by your ability to strategically develop team members and enhance their problem-solving capabilities. This indicates a high level of understanding and application of leadership principles.", "competency_name": "Leadership", "improvement_areas": ""}, {"user_strengths": "You have a solid understanding of self-organization, as you can independently manage projects and tasks effectively. This shows that you are capable of applying self-organization concepts in your work.", "competency_name": "Self-Organization", "improvement_areas": ""}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have a solid understanding of the project mandate and can effectively contextualize project management within systems engineering. Your ability to create relevant project plans and generate corresponding status reports independently demonstrates your competence in this area.", "competency_name": "Project Management", "improvement_areas": ""}, {"user_strengths": "You have a foundational awareness of the main decision-making bodies and understand the decision-making process.", "competency_name": "Decision Management", "improvement_areas": "To improve your competency in Decision Management, focus on enhancing your understanding of decision support methods. Consider seeking out training or resources that cover various decision-making frameworks and tools. Additionally, engage with mentors or colleagues who can provide insights into which decisions you can make independently and which require committee involvement."}, {"user_strengths": "You excel in defining a comprehensive information management process, showcasing your advanced skills in this area.", "competency_name": "Information Management", "improvement_areas": ""}, {"user_strengths": "You demonstrate a strong ability to define sensible configuration items and recognize those relevant to your work. Your capability to use tools for defining configuration items and creating configurations is commendable.", "competency_name": "Configuration Management", "improvement_areas": ""}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have a solid understanding of how to identify sources of requirements, derive and write them, and you are familiar with different types and levels of requirements. Your ability to read requirement documents and context descriptions is commendable, as it indicates a strong foundation in this area.", "competency_name": "Requirements Definition", "improvement_areas": ""}, {"user_strengths": "You demonstrate awareness of architectural models and their purpose in the development process, which is a good starting point for further growth in this competency.", "competency_name": "System Architecting", "improvement_areas": "To improve your competency in System Architecting, consider engaging in training or workshops focused on architectural modeling methodologies and languages. Additionally, practice reading and analyzing architectural models to enhance your understanding of their relevance and how to extract information from them."}, {"user_strengths": "You excel in this area, showcasing your ability to independently set up testing strategies and derive test cases based on requirements. Your proactive approach to orchestrating and documenting tests is a significant strength.", "competency_name": "Integration, Verification, Validation", "improvement_areas": ""}, {"user_strengths": "You have a strong capability in executing operation, service, and maintenance phases, along with identifying improvements for future projects, which is a valuable asset.", "competency_name": "Operation and Support", "improvement_areas": ""}, {"user_strengths": "You possess a good understanding of Agile workflows and their application within development processes. Your ability to explain the impact of Agile practices on project success is a strong point.", "competency_name": "Agile Methods", "improvement_areas": ""}], "competency_area": "Technical"}]
5	7	20	[{"feedbacks": [{"user_strengths": "You have a solid foundation in recognizing the interrelationships within your system and its boundaries, which is a crucial first step in systems thinking.", "competency_name": "Systems Thinking", "improvement_areas": "To enhance your understanding of how individual components interact within the system, consider engaging in training sessions focused on systems dynamics or taking part in workshops that emphasize system interactions. Additionally, collaborating on projects that require a deeper analysis of component interactions can provide practical experience."}, {"user_strengths": "You demonstrate a clear understanding of the importance of considering all lifecycle phases during development, which is essential for effective systems engineering.", "competency_name": "Lifecycle Consideration", "improvement_areas": ""}, {"user_strengths": "You excel in developing systems using agile methodologies and maintaining a strong focus on customer benefits, showcasing your ability to integrate customer value into your work.", "competency_name": "Customer / Value Orientation", "improvement_areas": ""}, {"user_strengths": "You have advanced skills in setting guidelines for necessary models and writing good modeling practices, indicating a high level of proficiency in this area.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": ""}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "Currently, you are aware of the importance of communication, which is a foundational step towards developing this competency.", "competency_name": "Communication", "improvement_areas": "To improve your communication skills, consider engaging in workshops or courses focused on effective communication techniques. Practicing active listening and empathy in conversations can also enhance your ability to communicate constructively. Additionally, seeking feedback from peers on your communication style can provide valuable insights."}, {"user_strengths": "You have a basic awareness of self-organization concepts, which is a good starting point for further development.", "competency_name": "Self-Organization", "improvement_areas": "To advance your understanding of self-organization, try implementing time management techniques such as the Pomodoro Technique or prioritizing tasks using the Eisenhower Matrix. Reading books or taking online courses on productivity and self-management can also deepen your understanding. Consider setting specific goals for your daily organization and reflecting on your progress regularly."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have a solid understanding of the key platforms for knowledge transfer and are aware of the information that needs to be shared with relevant stakeholders. This indicates a good grasp of the principles of information management.", "competency_name": "Information Management", "improvement_areas": ""}, {"user_strengths": "You demonstrate a strong capability in defining sensible configuration items and recognizing those that are relevant to your work. Your ability to use tools for defining configuration items and creating configurations shows a high level of proficiency in this area.", "competency_name": "Configuration Management", "improvement_areas": ""}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have demonstrated a strong ability to recognize deficiencies in the requirements process and develop suggestions for improvement. Your skills in creating context and interface descriptions and discussing these with stakeholders are commendable and indicate a high level of engagement with the requirements definition process.", "competency_name": "Requirements Definition", "improvement_areas": ""}, {"user_strengths": "You are currently at the initial stage of awareness in this competency area, which indicates a willingness to learn and grow. Recognizing that you need to develop your understanding of the operation, service, and maintenance phases is a positive first step.", "competency_name": "Operation and Support", "improvement_areas": "To improve in this area, consider enrolling in training courses focused on systems operation and support. Engaging with resources such as textbooks or online courses that cover lifecycle management and the integration of operational phases into development will be beneficial. Additionally, seeking mentorship from experienced colleagues in this field can provide practical insights."}, {"user_strengths": "You have a foundational awareness of Agile values and methods, which is a great starting point. Your ability to recognize and list these principles shows that you are on the right track to understanding Agile methodologies.", "competency_name": "Agile Methods", "improvement_areas": "To advance your competency in Agile methods, I recommend participating in workshops or training sessions that focus on Agile workflows and their application in development processes. Engaging in hands-on projects that utilize Agile practices will also help you understand their impact on project success. Consider joining Agile communities or forums to learn from others' experiences and best practices."}], "competency_area": "Technical"}]
6	8	20	[{"feedbacks": [{"user_strengths": "You demonstrate an awareness of the interrelationships within your system and its boundaries, which is a foundational skill in systems thinking.", "competency_name": "Systems Thinking", "improvement_areas": "To improve your competency in Systems Thinking, focus on developing your analytical skills. Consider engaging in training or workshops that emphasize systems analysis and continuous improvement methodologies. Practical experience in analyzing existing systems and identifying areas for enhancement will also be beneficial."}, {"user_strengths": "Currently, you have not yet developed awareness in Lifecycle Consideration, which presents an opportunity for growth.", "competency_name": "Lifecycle Consideration", "improvement_areas": "To build your competency in Lifecycle Consideration, start by studying the various phases of a system's lifecycle. Resources such as textbooks on systems engineering or online courses can provide foundational knowledge. Additionally, seek mentorship from experienced professionals who can guide you in understanding how to assess lifecycle phases relevant to your projects."}, {"user_strengths": "You have a basic understanding of agile thinking principles, which is a good starting point for customer and value orientation.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To advance in Customer / Value Orientation, aim to deepen your knowledge of agile methodologies and their application in system development. Participate in agile training sessions or workshops that focus on customer-centric approaches. Engaging in projects that require you to apply these methodologies will also enhance your practical understanding."}, {"user_strengths": "You have achieved a high level of competency in Systems Modeling and Analysis, demonstrating the ability to set guidelines for modeling practices and ensuring quality in your work.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": ""}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You demonstrate a strong ability to sustain and manage relationships with colleagues and supervisors, indicating a high level of interpersonal skills and emotional intelligence.", "competency_name": "Communication", "improvement_areas": ""}, {"user_strengths": "You excel in strategically developing team members, enhancing their problem-solving capabilities, which showcases your strong leadership skills and commitment to team growth.", "competency_name": "Leadership", "improvement_areas": ""}, {"user_strengths": "You have a remarkable ability to manage and optimize complex projects and processes, reflecting your advanced self-organization skills and efficiency in task management.", "competency_name": "Self-Organization", "improvement_areas": ""}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You demonstrate a strong ability to identify inadequacies in processes and suggest improvements. Your communication skills are effective, allowing you to convey reports, plans, and mandates to all stakeholders successfully.", "competency_name": "Project Management", "improvement_areas": ""}, {"user_strengths": "You have a solid capability in preparing and making decisions within your relevant scopes, and you document these decisions effectively. Your application of decision support methods, such as utility analysis, shows a good level of understanding.", "competency_name": "Decision Management", "improvement_areas": ""}, {"user_strengths": "You are proficient in defining storage structures and documentation guidelines for projects, ensuring that relevant information is accessible at the right time and place.", "competency_name": "Information Management", "improvement_areas": ""}, {"user_strengths": "You have a good understanding of defining sensible configuration items and recognizing those relevant to your work. Your ability to use tools for defining configuration items and creating configurations is commendable.", "competency_name": "Configuration Management", "improvement_areas": ""}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have a solid understanding of how to identify sources of requirements and can derive and write them effectively. Your ability to read requirement documents and context descriptions is commendable.", "competency_name": "Requirements Definition", "improvement_areas": "To reach the required level, focus on enhancing your skills in independently documenting, linking, and analyzing requirements. Consider seeking out training or workshops on requirements management and documentation. Additionally, practice creating and analyzing context descriptions and interface specifications through hands-on projects or simulations."}, {"user_strengths": "You demonstrate a good understanding of the relevance of architectural models in the development process and can extract relevant information from them.", "competency_name": "System Architecting", "improvement_areas": ""}, {"user_strengths": "You are capable of reading and understanding test plans, test cases, and results, which is essential for effective testing and validation processes.", "competency_name": "Integration, Verification, Validation", "improvement_areas": ""}, {"user_strengths": "You currently have no awareness or knowledge in this competency area, which indicates a significant opportunity for growth.", "competency_name": "Agile Methods", "improvement_areas": "To meet the required level, start by familiarizing yourself with Agile methodologies through online courses or workshops. Engage with Agile communities or forums to learn from experienced practitioners. Consider seeking mentorship from someone who has experience in Agile environments to gain practical insights and guidance."}], "competency_area": "Technical"}]
\.


--
-- Data for Name: user_role_cluster; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.user_role_cluster (user_id, role_cluster_id) FROM stdin;
1	1
1	3
2	1
2	3
3	1
3	14
4	1
5	2
6	10
6	12
7	10
8	5
\.


--
-- Data for Name: user_se_competency_survey_results; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.user_se_competency_survey_results (id, user_id, organization_id, competency_id, score, submitted_at, target_level, gap_size, archetype_source, learning_plan_id) FROM stdin;
1	1	19	1	0	2025-10-23 00:09:23.81439	\N	\N	\N	\N
2	1	19	4	0	2025-10-23 00:09:23.81439	\N	\N	\N	\N
3	1	19	5	6	2025-10-23 00:09:23.81439	\N	\N	\N	\N
4	1	19	6	0	2025-10-23 00:09:23.81439	\N	\N	\N	\N
5	1	19	7	0	2025-10-23 00:09:23.81439	\N	\N	\N	\N
6	1	19	8	6	2025-10-23 00:09:23.81439	\N	\N	\N	\N
7	1	19	9	0	2025-10-23 00:09:23.81439	\N	\N	\N	\N
8	1	19	10	6	2025-10-23 00:09:23.81439	\N	\N	\N	\N
9	1	19	11	0	2025-10-23 00:09:23.81439	\N	\N	\N	\N
10	1	19	12	6	2025-10-23 00:09:23.81439	\N	\N	\N	\N
11	1	19	13	0	2025-10-23 00:09:23.81439	\N	\N	\N	\N
12	1	19	14	6	2025-10-23 00:09:23.81439	\N	\N	\N	\N
13	1	19	15	0	2025-10-23 00:09:23.81439	\N	\N	\N	\N
14	1	19	16	6	2025-10-23 00:09:23.81439	\N	\N	\N	\N
15	1	19	17	0	2025-10-23 00:09:23.81439	\N	\N	\N	\N
16	1	19	18	6	2025-10-23 00:09:23.81439	\N	\N	\N	\N
17	2	19	1	0	2025-10-23 00:13:50.29505	\N	\N	\N	\N
18	2	19	4	0	2025-10-23 00:13:50.29505	\N	\N	\N	\N
19	2	19	5	0	2025-10-23 00:13:50.29505	\N	\N	\N	\N
20	2	19	6	0	2025-10-23 00:13:50.29505	\N	\N	\N	\N
21	2	19	7	0	2025-10-23 00:13:50.29505	\N	\N	\N	\N
22	2	19	8	0	2025-10-23 00:13:50.29505	\N	\N	\N	\N
23	2	19	9	0	2025-10-23 00:13:50.29505	\N	\N	\N	\N
24	2	19	10	0	2025-10-23 00:13:50.29505	\N	\N	\N	\N
25	2	19	11	0	2025-10-23 00:13:50.29505	\N	\N	\N	\N
26	2	19	12	6	2025-10-23 00:13:50.29505	\N	\N	\N	\N
27	2	19	13	6	2025-10-23 00:13:50.29505	\N	\N	\N	\N
28	2	19	14	6	2025-10-23 00:13:50.29505	\N	\N	\N	\N
29	2	19	15	6	2025-10-23 00:13:50.29505	\N	\N	\N	\N
30	2	19	16	6	2025-10-23 00:13:50.29505	\N	\N	\N	\N
31	2	19	17	6	2025-10-23 00:13:50.29505	\N	\N	\N	\N
32	2	19	18	6	2025-10-23 00:13:50.29505	\N	\N	\N	\N
33	3	19	1	1	2025-10-23 00:24:48.21783	\N	\N	\N	\N
34	3	19	4	2	2025-10-23 00:24:48.21783	\N	\N	\N	\N
35	3	19	5	4	2025-10-23 00:24:48.21783	\N	\N	\N	\N
36	3	19	6	6	2025-10-23 00:24:48.21783	\N	\N	\N	\N
37	3	19	7	0	2025-10-23 00:24:48.21783	\N	\N	\N	\N
38	3	19	8	0	2025-10-23 00:24:48.21783	\N	\N	\N	\N
39	3	19	9	6	2025-10-23 00:24:48.21783	\N	\N	\N	\N
40	3	19	10	4	2025-10-23 00:24:48.21783	\N	\N	\N	\N
41	3	19	11	2	2025-10-23 00:24:48.21783	\N	\N	\N	\N
42	3	19	12	1	2025-10-23 00:24:48.21783	\N	\N	\N	\N
43	3	19	13	2	2025-10-23 00:24:48.21783	\N	\N	\N	\N
44	3	19	14	4	2025-10-23 00:24:48.21783	\N	\N	\N	\N
45	3	19	15	6	2025-10-23 00:24:48.21783	\N	\N	\N	\N
46	3	19	16	0	2025-10-23 00:24:48.21783	\N	\N	\N	\N
47	3	19	17	6	2025-10-23 00:24:48.21783	\N	\N	\N	\N
48	3	19	18	4	2025-10-23 00:24:48.21783	\N	\N	\N	\N
49	4	19	1	2	2025-10-23 00:48:35.172025	\N	\N	\N	\N
50	4	19	4	2	2025-10-23 00:48:35.172025	\N	\N	\N	\N
51	4	19	5	6	2025-10-23 00:48:35.172025	\N	\N	\N	\N
52	4	19	6	2	2025-10-23 00:48:35.172025	\N	\N	\N	\N
53	4	19	7	0	2025-10-23 00:48:35.172025	\N	\N	\N	\N
54	4	19	8	1	2025-10-23 00:48:35.172025	\N	\N	\N	\N
55	4	19	9	2	2025-10-23 00:48:35.172025	\N	\N	\N	\N
56	4	19	10	4	2025-10-23 00:48:35.172025	\N	\N	\N	\N
57	4	19	11	1	2025-10-23 00:48:35.172025	\N	\N	\N	\N
58	4	19	12	2	2025-10-23 00:48:35.172025	\N	\N	\N	\N
59	4	19	13	4	2025-10-23 00:48:35.172025	\N	\N	\N	\N
60	4	19	14	1	2025-10-23 00:48:35.172025	\N	\N	\N	\N
61	4	19	15	2	2025-10-23 00:48:35.172025	\N	\N	\N	\N
62	4	19	16	0	2025-10-23 00:48:35.172025	\N	\N	\N	\N
63	4	19	17	1	2025-10-23 00:48:35.172025	\N	\N	\N	\N
64	4	19	18	0	2025-10-23 00:48:35.172025	\N	\N	\N	\N
65	5	19	1	0	2025-10-23 01:04:54.764466	\N	\N	\N	\N
66	5	19	4	6	2025-10-23 01:04:54.764466	\N	\N	\N	\N
67	5	19	5	4	2025-10-23 01:04:54.764466	\N	\N	\N	\N
68	5	19	6	2	2025-10-23 01:04:54.764466	\N	\N	\N	\N
69	5	19	7	1	2025-10-23 01:04:54.764466	\N	\N	\N	\N
70	5	19	8	1	2025-10-23 01:04:54.764466	\N	\N	\N	\N
71	5	19	9	2	2025-10-23 01:04:54.764466	\N	\N	\N	\N
72	5	19	10	4	2025-10-23 01:04:54.764466	\N	\N	\N	\N
73	5	19	11	6	2025-10-23 01:04:54.764466	\N	\N	\N	\N
74	5	19	12	0	2025-10-23 01:04:54.764466	\N	\N	\N	\N
75	5	19	13	0	2025-10-23 01:04:54.764466	\N	\N	\N	\N
76	5	19	14	6	2025-10-23 01:04:54.764466	\N	\N	\N	\N
77	5	19	15	4	2025-10-23 01:04:54.764466	\N	\N	\N	\N
78	5	19	16	2	2025-10-23 01:04:54.764466	\N	\N	\N	\N
79	5	19	17	1	2025-10-23 01:04:54.764466	\N	\N	\N	\N
80	5	19	18	1	2025-10-23 01:04:54.764466	\N	\N	\N	\N
81	6	20	1	0	2025-10-23 01:40:11.486347	\N	\N	\N	\N
82	6	20	4	0	2025-10-23 01:40:11.486347	\N	\N	\N	\N
83	6	20	5	0	2025-10-23 01:40:11.486347	\N	\N	\N	\N
84	6	20	6	0	2025-10-23 01:40:11.486347	\N	\N	\N	\N
85	6	20	7	0	2025-10-23 01:40:11.486347	\N	\N	\N	\N
86	6	20	8	6	2025-10-23 01:40:11.486347	\N	\N	\N	\N
87	6	20	9	4	2025-10-23 01:40:11.486347	\N	\N	\N	\N
88	6	20	10	2	2025-10-23 01:40:11.486347	\N	\N	\N	\N
89	6	20	11	1	2025-10-23 01:40:11.486347	\N	\N	\N	\N
90	6	20	12	6	2025-10-23 01:40:11.486347	\N	\N	\N	\N
91	6	20	13	4	2025-10-23 01:40:11.486347	\N	\N	\N	\N
92	6	20	14	2	2025-10-23 01:40:11.486347	\N	\N	\N	\N
93	6	20	15	1	2025-10-23 01:40:11.486347	\N	\N	\N	\N
94	6	20	16	6	2025-10-23 01:40:11.486347	\N	\N	\N	\N
95	6	20	17	4	2025-10-23 01:40:11.486347	\N	\N	\N	\N
96	6	20	18	2	2025-10-23 01:40:11.486347	\N	\N	\N	\N
97	7	20	1	1	2025-10-23 02:03:45.044226	\N	\N	\N	\N
98	7	20	4	2	2025-10-23 02:03:45.044226	\N	\N	\N	\N
99	7	20	5	4	2025-10-23 02:03:45.044226	\N	\N	\N	\N
100	7	20	6	6	2025-10-23 02:03:45.044226	\N	\N	\N	\N
101	7	20	7	0	2025-10-23 02:03:45.044226	\N	\N	\N	\N
102	7	20	9	1	2025-10-23 02:03:45.044226	\N	\N	\N	\N
103	7	20	12	2	2025-10-23 02:03:45.044226	\N	\N	\N	\N
104	7	20	13	4	2025-10-23 02:03:45.044226	\N	\N	\N	\N
105	7	20	14	6	2025-10-23 02:03:45.044226	\N	\N	\N	\N
106	7	20	17	0	2025-10-23 02:03:45.044226	\N	\N	\N	\N
107	7	20	18	1	2025-10-23 02:03:45.044226	\N	\N	\N	\N
108	8	20	1	1	2025-10-23 02:25:52.443724	\N	\N	\N	\N
109	8	20	4	0	2025-10-23 02:25:52.443724	\N	\N	\N	\N
110	8	20	5	1	2025-10-23 02:25:52.443724	\N	\N	\N	\N
111	8	20	6	6	2025-10-23 02:25:52.443724	\N	\N	\N	\N
112	8	20	7	6	2025-10-23 02:25:52.443724	\N	\N	\N	\N
113	8	20	8	6	2025-10-23 02:25:52.443724	\N	\N	\N	\N
114	8	20	9	6	2025-10-23 02:25:52.443724	\N	\N	\N	\N
115	8	20	10	6	2025-10-23 02:25:52.443724	\N	\N	\N	\N
116	8	20	11	4	2025-10-23 02:25:52.443724	\N	\N	\N	\N
117	8	20	12	4	2025-10-23 02:25:52.443724	\N	\N	\N	\N
118	8	20	13	4	2025-10-23 02:25:52.443724	\N	\N	\N	\N
119	8	20	14	2	2025-10-23 02:25:52.443724	\N	\N	\N	\N
120	8	20	15	2	2025-10-23 02:25:52.443724	\N	\N	\N	\N
121	8	20	16	2	2025-10-23 02:25:52.443724	\N	\N	\N	\N
122	8	20	18	0	2025-10-23 02:25:52.443724	\N	\N	\N	\N
\.


--
-- Data for Name: user_survey_type; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.user_survey_type (id, user_id, created_at, survey_type) FROM stdin;
1	1	2025-10-23 00:09:23.795337	known_roles
2	2	2025-10-23 00:13:50.274075	known_roles
3	3	2025-10-23 00:24:48.200093	known_roles
4	4	2025-10-23 00:48:35.159001	known_roles
5	5	2025-10-23 01:04:54.748261	known_roles
6	6	2025-10-23 01:40:11.468753	known_roles
7	7	2025-10-23 02:03:45.02897	known_roles
8	8	2025-10-23 02:25:52.430225	known_roles
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: ma0349
--

COPY public.users (id, uuid, username, email, password_hash, first_name, last_name, organization_id, organization, joined_via_code, role, user_type, is_active, is_verified, created_at, last_login) FROM stdin;
1	f6b71cd2-c494-4245-a728-9930e301f972	admin	\N	scrypt:32768:8:1$zdpcJalPCeBvpWkb$2790bd8f0e4395a71437facd86911dc822f779493cef6e8b496f10771824c35a844c06be3c7b7819ddc5e39ea83b5205d18f53ffce15fa6607aa855e4901f771	\N	\N	1	\N	D0E45A175B205355	admin	participant	t	f	2025-10-20 23:53:06.983207	\N
2	2de3e516-5f37-4a85-84df-11ee260fdba9	employee1	\N	scrypt:32768:8:1$XAbntdR6m5LaWF0n$67c7c5a829be956b4c6c69a28635030675e2969e7034996cf4e861720dc30c815bd2c0cb2859c12dab496e225047865a26d740ff89b70781e840717d47943936	John	Doe	1	\N	D0E45A175B205355	employee	participant	t	f	2025-10-20 23:54:43.347729	\N
3	7191d80a-3f41-40ed-8d04-b90a7c3d155f	employee2	\N	scrypt:32768:8:1$6p4Y46DMlxWjNiEV$0b3d278143d621dacc2917c693d893950e549eabc43914d7a5b2e946904974d45161fe312e732600fc006408b4806e56fa088341b020617c9123ad5c3d06cb0a	\N	\N	1	\N	D0E45A175B205355	employee	participant	t	f	2025-10-20 23:56:36.240978	\N
4	8b4b3cad-d41a-47b9-b805-d1675c5ca457	admin_user	\N	scrypt:32768:8:1$MiclOzkQ7jej51vg$2c11af3136dc7c22b01b5179e7b75682a255d449a73c775ea9ddab0f41478f889ea7e9eb921fb72e0a48d8983a5e7497d427ed5f3d85dc92c9d95374c927511d	\N	\N	2	\N	548EC388A22CB85C	admin	participant	t	f	2025-10-20 23:57:12.417625	\N
5	b4169ea7-d1ac-4f2d-94c1-4f85587b803d	testadmin	\N	scrypt:32768:8:1$Br0oyuYL0rsDP4hj$e95649937c82faab3c68353c827bece85cb0f97788b8c5a18ed1a9cb4c93d4ebabf90e90f2fbf655d6807040e627a62bc7b9eea66c41612de577011dfb05e7ff	\N	\N	3	\N	038EBCB6F8AE3921	admin	participant	t	f	2025-10-21 00:03:13.282559	\N
6	175da968-d075-402c-95fd-c0e5bea4a610	admin_tester	\N	scrypt:32768:8:1$aushFN8rCvIRpURi$467c33fce9fa9f6b3b60a7bff7aa3f5f1979a137cc9f4cbcead359a8c0846f6dcdece30400f4d559132d2d731592563cdaae85d5b46f4a6e2c05207396c549ef	\N	\N	4	\N	14A988CC4CB19886	admin	participant	t	f	2025-10-21 00:05:08.49551	\N
7	27367122-c80b-4c29-a06a-8479ee65a087	admin_tests	\N	scrypt:32768:8:1$iY8lOreDDNVNxGRR$4b9826474da34c560edce9827aaa537cdce150ba20e1faae11b1c4ac7e9539065f2506e0a60d71a5c3faba64b04d786e604ef2827d13976b9acb193a613e3262	\N	\N	5	\N	FD238304CD9E1618	admin	participant	t	f	2025-10-21 00:06:30.454622	\N
10	f6d2142b-3ef4-44b2-84ea-12b59b94ed96	goofyman	\N	scrypt:32768:8:1$DpsYfGqX8OI0J7fv$4667475cc2347618287db4f81330108ca1e3152903f1b1dea7538c3c31fcbeadf56cecb12f637c994e754640ced8d85043d90e617a62972e42ec8ec5c39982d2	\N	\N	8	\N	34298DE867C7AFCB	admin	participant	t	f	2025-10-21 00:11:50.865341	\N
9	0f5acf17-7602-402d-953c-18b289f8ece8	hopethisworks	\N	scrypt:32768:8:1$Ld2QnskJX4fdzG2i$0b4128a58d97b22c90e9a15b683508dbdb0e0e3e67fc06339905cf3476d7be4ab83a43e8e7bbd08c2fedb1b8d0087c93a3abaed5e9a1037c4ab6b8af4432765d	\N	\N	7	\N	DABBB1696ECECE72	admin	participant	t	f	2025-10-21 00:08:57.312495	2025-10-21 00:13:12.997732
15	10387ab4-92f4-481c-9c9d-0d9c25ad196d	batman1	\N	scrypt:32768:8:1$vhkMmLDQQTPFNfAW$9234573642ea042fb97c47c6c7233437f09e323ced504c887a22dfaa865e8f1736641172854708ee2e9cb913646fb067143155e0711e940630b9cf2f0963b9e0	\N	\N	12	\N	F8CE7400F3ADFDCE	admin	participant	t	f	2025-10-21 00:58:35.089089	2025-10-21 00:58:38.606268
11	165958dd-04b5-4e5e-bbbe-cc7bf0dd9755	qwerty1	\N	scrypt:32768:8:1$Z6z0c5pp5U8GiKBf$8d3dec8b2e8e01ea18d59878475850d2d86dd82edd30bed6065a42347810636166b6f4ba43185d54463bfd118b9b2ef53b6eb9d33f0ca6c8362a5c44b513a4fd	\N	\N	9	\N	7CAEE398AC3984FF	admin	participant	t	f	2025-10-21 00:16:02.452093	\N
8	af6971e0-77df-48eb-95e6-2f0cd9451424	yoloman	\N	scrypt:32768:8:1$itzoev3gQOuqeof3$7e4c34d695682a918b36fe5ac242f77409306522ade8c97cf33abae6aa56ac4dac8b9f65f8881e9f1dfebe66990d6eeb44c2a9377f57caca402a97cafdfc8868	\N	\N	6	\N	E34D70C7CD9A121E	admin	participant	t	f	2025-10-21 00:07:23.073158	2025-10-21 00:22:21.925558
12	bfaded4d-5b85-46a0-85ec-0becbf379b1a	someoneuser	\N	scrypt:32768:8:1$p2xNRdOes1PhD4cv$a72101cffcb56842a354723a9c0f9a2b2a8d407a37c16c3b2828a658ec148f9bad11d2ea8ab92aab7646d8d380bca3d835476c086dee76ca8c8dbe6aaf813080	\N	\N	10	\N	6C2B24C3661580D1	admin	participant	t	f	2025-10-21 00:22:40.336392	2025-10-21 00:22:44.36921
16	abae230e-dd59-4c1f-aa6a-27f08763e437	batman2	\N	scrypt:32768:8:1$qd09ZjEHtUXR9Iom$5ee28a28758af148f1f24617695672ebe123037c956469d961c4e32fc81bf50c0646a1e99b9fa1ddc6df5f6a562fcd865d13e8817287923f89afb557a6a36f8a	\N	\N	11	\N	94D77D50D6753BA3	employee	participant	t	f	2025-10-21 00:59:32.149153	2025-10-21 00:59:38.600368
19	f65d31e0-886b-4672-9db1-a29001b16ae5	testtester1	\N	scrypt:32768:8:1$cZQc11AK0Onw7VtP$a8e75c9f0481dd7d797d6bfb9b2cbb06ac9351d3671c4bfad90e783e9c785a911c63dae6da6444e1caa1028568a36ea7ef6064048e71bad354cc41abb21ead39	\N	\N	16	\N	BEAEC7DBAE6F72C3	employee	participant	t	f	2025-10-21 14:24:58.009862	2025-10-21 14:25:02.110262
17	dc8c7c67-71fb-4dad-a141-7d2a45a55bb0	spartacus	\N	scrypt:32768:8:1$ll8FWxLWf3RMQQaN$7319e4c1ba6eed08aeaed7744cdb97a87703444d75a7b653ef0e4da5ce4fcd1cb7b604a498dedc2ac5ee2eafc833d286973547db1d132f05821c4e10f7ba7123	\N	\N	15	\N	B82AF8AE8E385FCC	admin	participant	t	f	2025-10-21 03:52:44.595465	2025-10-21 03:52:52.049933
13	cc25f932-2790-430e-b117-08a3782e6b3d	testtest	\N	scrypt:32768:8:1$xBbd60UiMtyuQSpt$c117c0f5cd41df5970f30cd07e6cef647c68a71b0f8cd42da34c6fcee0f674943907274fdcf0a8a8c148858f55235f0c3d7dc948ee0781e57cef74be5237ebe9	\N	\N	11	\N	94D77D50D6753BA3	admin	participant	t	f	2025-10-21 00:28:01.231917	2025-10-21 22:45:03.901781
18	4024be30-9163-47ae-a8b7-81c9e9083503	testtester	\N	scrypt:32768:8:1$D0jwS0dikV6yfdFG$2572b676b9b8b72e1eaa65eaa45f59c9b70dd573859f94a239d9211fde5cf9c9690c06aa8ed026895f1bf02957445f157d417c0091d4f93c1bbb402b4ebf911b	\N	\N	16	\N	BEAEC7DBAE6F72C3	admin	participant	t	f	2025-10-21 14:23:54.519095	2025-10-21 14:25:21.374885
14	9666835c-a774-4d41-84bb-f353fc76ac8e	testtest1	\N	scrypt:32768:8:1$r4q71wAVm3FZnhJ8$bf66ba300f553e31df3dfd23170944c030529653d9792540901b35dd2845f0f70fd88582d48b640f6a81be21b8840bdeea8f47ccd3022785c65bc3c2b4ebb557	\N	\N	11	\N	94D77D50D6753BA3	employee	participant	t	f	2025-10-21 00:40:12.464279	2025-10-21 22:45:13.986177
20	7eb460e1-49f9-4cb4-9c36-796a82e3a2f4	somerandomguy	\N	scrypt:32768:8:1$4u5cbWS2R9k9iKQa$89f5a77652568ebbb418fdc7f22db50aebba20f8b450bd7242252809fce170d6093cf7df8279fb8a6a2cec66568521c7eab92c30d5e737cc5434107cce8e3899	\N	\N	17	\N	A06E62CF9F0CDC71	admin	participant	t	f	2025-10-21 22:01:34.018229	2025-10-21 22:44:51.839202
22	e062fe69-7408-4f79-8dc7-45fda48f9e20	welpme1	\N	scrypt:32768:8:1$cVGlCk4mRa2Ra53e$f6cdd04aec90d8c8b49de39e9e40f92f85b9b1f15b1d1a77b325a5c20b30a66b3365cebd5a558b69cbfdb27d10119276070f982a17994285b2bf7617367a77d8	\N	\N	18	\N	D14016B870976956	employee	participant	t	f	2025-10-21 22:46:48.908479	2025-10-21 22:46:51.73374
21	fd7d4402-7a13-4096-b4ab-5a9400a6a198	welpme	\N	scrypt:32768:8:1$ZaVUpS9TT0c1VM9c$f9c0776e1f1be1d8aaaabcf81eb2a92b9df0b4b3dac9064e7c05a3c21b106c18c363204f6bcc5808a741badbdc971a6c9d501d82f8d02af847b068298b2aeddd	\N	\N	18	\N	D14016B870976956	admin	participant	t	f	2025-10-21 22:45:52.540124	2025-10-22 00:13:39.895154
23	6940015e-e39c-4641-baf5-f94d19947291	imbatman	\N	scrypt:32768:8:1$SzSfBPY5XJphBYSd$ba85a550f6affc23384516eb7a4bb2618b826e37e430b74973dd90039665888ff739438bd35737887d43a1952d8b49f46162bde1bce666bca9a88023174d8e49	\N	\N	19	\N	7287EF86B6ECFA5E	admin	participant	t	f	2025-10-22 00:15:17.500061	2025-10-22 01:47:20.52336
24	e6c7ccf5-5eed-4887-a8ac-86e0c6a05a53	reeguy	\N	scrypt:32768:8:1$Jao6uPW1vs1ufBnZ$0d272a4bf2e96fac79f0934675426f4ac5d820d91e11dd96585b78040ee43187565dfb822649743d2cf26e0f85689f607decf8c9e8bd6855a3fce70f804e08c5	\N	\N	20	\N	F2EBFCBBABF9895B	admin	participant	t	f	2025-10-23 01:33:08.096286	2025-10-23 02:30:39.903752
25	53dd7fcb-f756-4ad6-952a-ba245603bb72	reeguy1	\N	scrypt:32768:8:1$4eKgU3dftZpslQ6Z$d94acdb5e0b5594a44295e595cfcc5b4d3f124056b84aed414a03b0d59be0ad368f98fd971e23384c2ed19917ce7a49c89817ce4edb0bce8fc54e66b0b6efcb8	\N	\N	20	\N	F2EBFCBBABF9895B	employee	participant	t	f	2025-10-23 01:42:57.510712	2025-10-23 01:43:01.271431
\.


--
-- Name: app_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.app_user_id_seq', 8, true);


--
-- Name: assessments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.assessments_id_seq', 1, false);


--
-- Name: company_contexts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.company_contexts_id_seq', 1, false);


--
-- Name: competency_assessment_results_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.competency_assessment_results_id_seq', 1, false);


--
-- Name: competency_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.competency_id_seq', 1, false);


--
-- Name: competency_indicators_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.competency_indicators_id_seq', 64, true);


--
-- Name: iso_activities_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.iso_activities_id_seq', 1, false);


--
-- Name: iso_processes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.iso_processes_id_seq', 1, false);


--
-- Name: iso_system_life_cycle_processes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.iso_system_life_cycle_processes_id_seq', 1, false);


--
-- Name: iso_tasks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.iso_tasks_id_seq', 1, false);


--
-- Name: learning_modules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.learning_modules_id_seq', 1, false);


--
-- Name: learning_objectives_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.learning_objectives_id_seq', 1, false);


--
-- Name: learning_paths_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.learning_paths_id_seq', 1, false);


--
-- Name: learning_resources_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.learning_resources_id_seq', 1, false);


--
-- Name: module_assessments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.module_assessments_id_seq', 1, false);


--
-- Name: module_enrollments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.module_enrollments_id_seq', 1, false);


--
-- Name: new_survey_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.new_survey_user_id_seq', 11, true);


--
-- Name: organization_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.organization_id_seq', 20, true);


--
-- Name: process_competency_matrix_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.process_competency_matrix_id_seq', 1, false);


--
-- Name: qualification_archetypes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.qualification_archetypes_id_seq', 1, false);


--
-- Name: qualification_plans_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.qualification_plans_id_seq', 1, false);


--
-- Name: question_options_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.question_options_id_seq', 1, false);


--
-- Name: question_responses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.question_responses_id_seq', 1, false);


--
-- Name: questionnaire_responses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.questionnaire_responses_id_seq', 1, false);


--
-- Name: questionnaires_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.questionnaires_id_seq', 1, false);


--
-- Name: questions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.questions_id_seq', 1, false);


--
-- Name: rag_templates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.rag_templates_id_seq', 1, false);


--
-- Name: role_cluster_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.role_cluster_id_seq', 1, false);


--
-- Name: role_competency_matrix_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.role_competency_matrix_id_seq', 3136, true);


--
-- Name: role_process_matrix_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.role_process_matrix_id_seq', 3954, true);


--
-- Name: unknown_role_competency_matrix_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.unknown_role_competency_matrix_id_seq', 1680, true);


--
-- Name: unknown_role_process_matrix_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.unknown_role_process_matrix_id_seq', 3196, true);


--
-- Name: user_competency_survey_feedback_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.user_competency_survey_feedback_id_seq', 6, true);


--
-- Name: user_se_competency_survey_results_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.user_se_competency_survey_results_id_seq', 122, true);


--
-- Name: user_survey_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.user_survey_type_id_seq', 8, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ma0349
--

SELECT pg_catalog.setval('public.users_id_seq', 25, true);


--
-- Name: app_user app_user_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT app_user_pkey PRIMARY KEY (id);


--
-- Name: app_user app_user_username_key; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT app_user_username_key UNIQUE (username);


--
-- Name: assessments assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.assessments
    ADD CONSTRAINT assessments_pkey PRIMARY KEY (id);


--
-- Name: assessments assessments_uuid_key; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.assessments
    ADD CONSTRAINT assessments_uuid_key UNIQUE (uuid);


--
-- Name: company_contexts company_contexts_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.company_contexts
    ADD CONSTRAINT company_contexts_pkey PRIMARY KEY (id);


--
-- Name: competency_assessment_results competency_assessment_results_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.competency_assessment_results
    ADD CONSTRAINT competency_assessment_results_pkey PRIMARY KEY (id);


--
-- Name: competency_indicators competency_indicators_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.competency_indicators
    ADD CONSTRAINT competency_indicators_pkey PRIMARY KEY (id);


--
-- Name: competency competency_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.competency
    ADD CONSTRAINT competency_pkey PRIMARY KEY (id);


--
-- Name: iso_activities iso_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.iso_activities
    ADD CONSTRAINT iso_activities_pkey PRIMARY KEY (id);


--
-- Name: iso_processes iso_processes_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.iso_processes
    ADD CONSTRAINT iso_processes_pkey PRIMARY KEY (id);


--
-- Name: iso_system_life_cycle_processes iso_system_life_cycle_processes_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.iso_system_life_cycle_processes
    ADD CONSTRAINT iso_system_life_cycle_processes_pkey PRIMARY KEY (id);


--
-- Name: iso_tasks iso_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.iso_tasks
    ADD CONSTRAINT iso_tasks_pkey PRIMARY KEY (id);


--
-- Name: learning_modules learning_modules_module_code_key; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.learning_modules
    ADD CONSTRAINT learning_modules_module_code_key UNIQUE (module_code);


--
-- Name: learning_modules learning_modules_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.learning_modules
    ADD CONSTRAINT learning_modules_pkey PRIMARY KEY (id);


--
-- Name: learning_modules learning_modules_uuid_key; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.learning_modules
    ADD CONSTRAINT learning_modules_uuid_key UNIQUE (uuid);


--
-- Name: learning_objectives learning_objectives_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.learning_objectives
    ADD CONSTRAINT learning_objectives_pkey PRIMARY KEY (id);


--
-- Name: learning_objectives learning_objectives_uuid_key; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.learning_objectives
    ADD CONSTRAINT learning_objectives_uuid_key UNIQUE (uuid);


--
-- Name: learning_paths learning_paths_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.learning_paths
    ADD CONSTRAINT learning_paths_pkey PRIMARY KEY (id);


--
-- Name: learning_paths learning_paths_uuid_key; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.learning_paths
    ADD CONSTRAINT learning_paths_uuid_key UNIQUE (uuid);


--
-- Name: learning_plans learning_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.learning_plans
    ADD CONSTRAINT learning_plans_pkey PRIMARY KEY (id);


--
-- Name: learning_resources learning_resources_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.learning_resources
    ADD CONSTRAINT learning_resources_pkey PRIMARY KEY (id);


--
-- Name: learning_resources learning_resources_uuid_key; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.learning_resources
    ADD CONSTRAINT learning_resources_uuid_key UNIQUE (uuid);


--
-- Name: maturity_assessments maturity_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.maturity_assessments
    ADD CONSTRAINT maturity_assessments_pkey PRIMARY KEY (id);


--
-- Name: module_assessments module_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.module_assessments
    ADD CONSTRAINT module_assessments_pkey PRIMARY KEY (id);


--
-- Name: module_assessments module_assessments_uuid_key; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.module_assessments
    ADD CONSTRAINT module_assessments_uuid_key UNIQUE (uuid);


--
-- Name: module_enrollments module_enrollments_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.module_enrollments
    ADD CONSTRAINT module_enrollments_pkey PRIMARY KEY (id);


--
-- Name: module_enrollments module_enrollments_uuid_key; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.module_enrollments
    ADD CONSTRAINT module_enrollments_uuid_key UNIQUE (uuid);


--
-- Name: new_survey_user new_survey_user_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.new_survey_user
    ADD CONSTRAINT new_survey_user_pkey PRIMARY KEY (id);


--
-- Name: new_survey_user new_survey_user_username_key; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.new_survey_user
    ADD CONSTRAINT new_survey_user_username_key UNIQUE (username);


--
-- Name: organization organization_organization_name_key; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.organization
    ADD CONSTRAINT organization_organization_name_key UNIQUE (organization_name);


--
-- Name: organization organization_organization_public_key_key; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.organization
    ADD CONSTRAINT organization_organization_public_key_key UNIQUE (organization_public_key);


--
-- Name: organization organization_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.organization
    ADD CONSTRAINT organization_pkey PRIMARY KEY (id);


--
-- Name: phase_questionnaire_responses phase_questionnaire_responses_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.phase_questionnaire_responses
    ADD CONSTRAINT phase_questionnaire_responses_pkey PRIMARY KEY (id);


--
-- Name: process_competency_matrix process_competency_matrix_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.process_competency_matrix
    ADD CONSTRAINT process_competency_matrix_pkey PRIMARY KEY (id);


--
-- Name: process_competency_matrix process_competency_matrix_unique; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.process_competency_matrix
    ADD CONSTRAINT process_competency_matrix_unique UNIQUE (iso_process_id, competency_id);


--
-- Name: qualification_archetypes qualification_archetypes_name_key; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.qualification_archetypes
    ADD CONSTRAINT qualification_archetypes_name_key UNIQUE (name);


--
-- Name: qualification_archetypes qualification_archetypes_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.qualification_archetypes
    ADD CONSTRAINT qualification_archetypes_pkey PRIMARY KEY (id);


--
-- Name: qualification_plans qualification_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.qualification_plans
    ADD CONSTRAINT qualification_plans_pkey PRIMARY KEY (id);


--
-- Name: qualification_plans qualification_plans_uuid_key; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.qualification_plans
    ADD CONSTRAINT qualification_plans_uuid_key UNIQUE (uuid);


--
-- Name: question_options question_options_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.question_options
    ADD CONSTRAINT question_options_pkey PRIMARY KEY (id);


--
-- Name: question_responses question_responses_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.question_responses
    ADD CONSTRAINT question_responses_pkey PRIMARY KEY (id);


--
-- Name: questionnaire_responses questionnaire_responses_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.questionnaire_responses
    ADD CONSTRAINT questionnaire_responses_pkey PRIMARY KEY (id);


--
-- Name: questionnaire_responses questionnaire_responses_uuid_key; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.questionnaire_responses
    ADD CONSTRAINT questionnaire_responses_uuid_key UNIQUE (uuid);


--
-- Name: questionnaires questionnaires_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.questionnaires
    ADD CONSTRAINT questionnaires_pkey PRIMARY KEY (id);


--
-- Name: questions questions_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_pkey PRIMARY KEY (id);


--
-- Name: rag_templates rag_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.rag_templates
    ADD CONSTRAINT rag_templates_pkey PRIMARY KEY (id);


--
-- Name: role_cluster role_cluster_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.role_cluster
    ADD CONSTRAINT role_cluster_pkey PRIMARY KEY (id);


--
-- Name: role_competency_matrix role_competency_matrix_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.role_competency_matrix
    ADD CONSTRAINT role_competency_matrix_pkey PRIMARY KEY (id);


--
-- Name: role_process_matrix role_process_matrix_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.role_process_matrix
    ADD CONSTRAINT role_process_matrix_pkey PRIMARY KEY (id);


--
-- Name: role_process_matrix role_process_matrix_unique; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.role_process_matrix
    ADD CONSTRAINT role_process_matrix_unique UNIQUE (organization_id, role_cluster_id, iso_process_id);


--
-- Name: unknown_role_competency_matrix unknown_role_competency_matrix_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.unknown_role_competency_matrix
    ADD CONSTRAINT unknown_role_competency_matrix_pkey PRIMARY KEY (id);


--
-- Name: unknown_role_competency_matrix unknown_role_competency_matrix_unique; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.unknown_role_competency_matrix
    ADD CONSTRAINT unknown_role_competency_matrix_unique UNIQUE (organization_id, user_name, competency_id);


--
-- Name: unknown_role_process_matrix unknown_role_process_matrix_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.unknown_role_process_matrix
    ADD CONSTRAINT unknown_role_process_matrix_pkey PRIMARY KEY (id);


--
-- Name: unknown_role_process_matrix unknown_role_process_matrix_unique; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.unknown_role_process_matrix
    ADD CONSTRAINT unknown_role_process_matrix_unique UNIQUE (organization_id, iso_process_id, user_name);


--
-- Name: user_competency_survey_feedback user_competency_survey_feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.user_competency_survey_feedback
    ADD CONSTRAINT user_competency_survey_feedback_pkey PRIMARY KEY (id);


--
-- Name: user_role_cluster user_role_cluster_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.user_role_cluster
    ADD CONSTRAINT user_role_cluster_pkey PRIMARY KEY (user_id, role_cluster_id);


--
-- Name: user_se_competency_survey_results user_se_competency_survey_results_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.user_se_competency_survey_results
    ADD CONSTRAINT user_se_competency_survey_results_pkey PRIMARY KEY (id);


--
-- Name: user_survey_type user_survey_type_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.user_survey_type
    ADD CONSTRAINT user_survey_type_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: users users_uuid_key; Type: CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_uuid_key UNIQUE (uuid);


--
-- Name: new_survey_user before_insert_new_survey_user; Type: TRIGGER; Schema: public; Owner: ma0349
--

CREATE TRIGGER before_insert_new_survey_user BEFORE INSERT ON public.new_survey_user FOR EACH ROW EXECUTE FUNCTION public.set_username();


--
-- Name: app_user app_user_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT app_user_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(id);


--
-- Name: assessments assessments_selected_archetype_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.assessments
    ADD CONSTRAINT assessments_selected_archetype_id_fkey FOREIGN KEY (selected_archetype_id) REFERENCES public.qualification_archetypes(id);


--
-- Name: assessments assessments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.assessments
    ADD CONSTRAINT assessments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: competency_assessment_results competency_assessment_results_assessment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.competency_assessment_results
    ADD CONSTRAINT competency_assessment_results_assessment_id_fkey FOREIGN KEY (assessment_id) REFERENCES public.assessments(id);


--
-- Name: competency_assessment_results competency_assessment_results_competency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.competency_assessment_results
    ADD CONSTRAINT competency_assessment_results_competency_id_fkey FOREIGN KEY (competency_id) REFERENCES public.competency(id);


--
-- Name: competency_indicators competency_indicators_competency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.competency_indicators
    ADD CONSTRAINT competency_indicators_competency_id_fkey FOREIGN KEY (competency_id) REFERENCES public.competency(id);


--
-- Name: role_competency_matrix fk_competency; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.role_competency_matrix
    ADD CONSTRAINT fk_competency FOREIGN KEY (competency_id) REFERENCES public.competency(id);


--
-- Name: role_competency_matrix fk_organization; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.role_competency_matrix
    ADD CONSTRAINT fk_organization FOREIGN KEY (organization_id) REFERENCES public.organization(id);


--
-- Name: role_competency_matrix fk_role_cluster; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.role_competency_matrix
    ADD CONSTRAINT fk_role_cluster FOREIGN KEY (role_cluster_id) REFERENCES public.role_cluster(id);


--
-- Name: iso_activities iso_activities_process_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.iso_activities
    ADD CONSTRAINT iso_activities_process_id_fkey FOREIGN KEY (process_id) REFERENCES public.iso_processes(id);


--
-- Name: iso_processes iso_processes_life_cycle_process_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.iso_processes
    ADD CONSTRAINT iso_processes_life_cycle_process_id_fkey FOREIGN KEY (life_cycle_process_id) REFERENCES public.iso_system_life_cycle_processes(id);


--
-- Name: iso_tasks iso_tasks_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.iso_tasks
    ADD CONSTRAINT iso_tasks_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.iso_activities(id);


--
-- Name: learning_modules learning_modules_competency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.learning_modules
    ADD CONSTRAINT learning_modules_competency_id_fkey FOREIGN KEY (competency_id) REFERENCES public.competency(id);


--
-- Name: learning_objectives learning_objectives_competency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.learning_objectives
    ADD CONSTRAINT learning_objectives_competency_id_fkey FOREIGN KEY (competency_id) REFERENCES public.competency(id);


--
-- Name: learning_objectives learning_objectives_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.learning_objectives
    ADD CONSTRAINT learning_objectives_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: learning_plans learning_plans_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.learning_plans
    ADD CONSTRAINT learning_plans_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(id);


--
-- Name: learning_plans learning_plans_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.learning_plans
    ADD CONSTRAINT learning_plans_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: learning_resources learning_resources_module_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.learning_resources
    ADD CONSTRAINT learning_resources_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.learning_modules(id);


--
-- Name: maturity_assessments maturity_assessments_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.maturity_assessments
    ADD CONSTRAINT maturity_assessments_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(id);


--
-- Name: module_assessments module_assessments_enrollment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.module_assessments
    ADD CONSTRAINT module_assessments_enrollment_id_fkey FOREIGN KEY (enrollment_id) REFERENCES public.module_enrollments(id);


--
-- Name: module_enrollments module_enrollments_module_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.module_enrollments
    ADD CONSTRAINT module_enrollments_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.learning_modules(id);


--
-- Name: module_enrollments module_enrollments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.module_enrollments
    ADD CONSTRAINT module_enrollments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: phase_questionnaire_responses phase_questionnaire_responses_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.phase_questionnaire_responses
    ADD CONSTRAINT phase_questionnaire_responses_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(id);


--
-- Name: phase_questionnaire_responses phase_questionnaire_responses_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.phase_questionnaire_responses
    ADD CONSTRAINT phase_questionnaire_responses_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: process_competency_matrix process_competency_matrix_competency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.process_competency_matrix
    ADD CONSTRAINT process_competency_matrix_competency_id_fkey FOREIGN KEY (competency_id) REFERENCES public.competency(id);


--
-- Name: process_competency_matrix process_competency_matrix_iso_process_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.process_competency_matrix
    ADD CONSTRAINT process_competency_matrix_iso_process_id_fkey FOREIGN KEY (iso_process_id) REFERENCES public.iso_processes(id);


--
-- Name: qualification_plans qualification_plans_archetype_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.qualification_plans
    ADD CONSTRAINT qualification_plans_archetype_id_fkey FOREIGN KEY (archetype_id) REFERENCES public.qualification_archetypes(id);


--
-- Name: qualification_plans qualification_plans_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.qualification_plans
    ADD CONSTRAINT qualification_plans_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: question_options question_options_question_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.question_options
    ADD CONSTRAINT question_options_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.questions(id);


--
-- Name: question_responses question_responses_question_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.question_responses
    ADD CONSTRAINT question_responses_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.questions(id);


--
-- Name: question_responses question_responses_questionnaire_response_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.question_responses
    ADD CONSTRAINT question_responses_questionnaire_response_id_fkey FOREIGN KEY (questionnaire_response_id) REFERENCES public.questionnaire_responses(id);


--
-- Name: question_responses question_responses_selected_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.question_responses
    ADD CONSTRAINT question_responses_selected_option_id_fkey FOREIGN KEY (selected_option_id) REFERENCES public.question_options(id);


--
-- Name: questionnaire_responses questionnaire_responses_questionnaire_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.questionnaire_responses
    ADD CONSTRAINT questionnaire_responses_questionnaire_id_fkey FOREIGN KEY (questionnaire_id) REFERENCES public.questionnaires(id);


--
-- Name: questionnaire_responses questionnaire_responses_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.questionnaire_responses
    ADD CONSTRAINT questionnaire_responses_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: questions questions_questionnaire_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_questionnaire_id_fkey FOREIGN KEY (questionnaire_id) REFERENCES public.questionnaires(id);


--
-- Name: role_process_matrix role_process_matrix_iso_process_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.role_process_matrix
    ADD CONSTRAINT role_process_matrix_iso_process_id_fkey FOREIGN KEY (iso_process_id) REFERENCES public.iso_processes(id);


--
-- Name: role_process_matrix role_process_matrix_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.role_process_matrix
    ADD CONSTRAINT role_process_matrix_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(id);


--
-- Name: role_process_matrix role_process_matrix_role_cluster_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.role_process_matrix
    ADD CONSTRAINT role_process_matrix_role_cluster_id_fkey FOREIGN KEY (role_cluster_id) REFERENCES public.role_cluster(id);


--
-- Name: unknown_role_competency_matrix unknown_role_competency_matrix_competency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.unknown_role_competency_matrix
    ADD CONSTRAINT unknown_role_competency_matrix_competency_id_fkey FOREIGN KEY (competency_id) REFERENCES public.competency(id);


--
-- Name: unknown_role_competency_matrix unknown_role_competency_matrix_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.unknown_role_competency_matrix
    ADD CONSTRAINT unknown_role_competency_matrix_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: unknown_role_process_matrix unknown_role_process_matrix_iso_process_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.unknown_role_process_matrix
    ADD CONSTRAINT unknown_role_process_matrix_iso_process_id_fkey FOREIGN KEY (iso_process_id) REFERENCES public.iso_processes(id) ON DELETE CASCADE;


--
-- Name: unknown_role_process_matrix unknown_role_process_matrix_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.unknown_role_process_matrix
    ADD CONSTRAINT unknown_role_process_matrix_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: user_competency_survey_feedback user_competency_survey_feedback_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.user_competency_survey_feedback
    ADD CONSTRAINT user_competency_survey_feedback_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(id);


--
-- Name: user_competency_survey_feedback user_competency_survey_feedback_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.user_competency_survey_feedback
    ADD CONSTRAINT user_competency_survey_feedback_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.app_user(id);


--
-- Name: user_role_cluster user_role_cluster_role_cluster_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.user_role_cluster
    ADD CONSTRAINT user_role_cluster_role_cluster_id_fkey FOREIGN KEY (role_cluster_id) REFERENCES public.role_cluster(id);


--
-- Name: user_role_cluster user_role_cluster_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.user_role_cluster
    ADD CONSTRAINT user_role_cluster_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.app_user(id);


--
-- Name: user_se_competency_survey_results user_se_competency_survey_results_competency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.user_se_competency_survey_results
    ADD CONSTRAINT user_se_competency_survey_results_competency_id_fkey FOREIGN KEY (competency_id) REFERENCES public.competency(id);


--
-- Name: user_se_competency_survey_results user_se_competency_survey_results_learning_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.user_se_competency_survey_results
    ADD CONSTRAINT user_se_competency_survey_results_learning_plan_id_fkey FOREIGN KEY (learning_plan_id) REFERENCES public.learning_plans(id);


--
-- Name: user_se_competency_survey_results user_se_competency_survey_results_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.user_se_competency_survey_results
    ADD CONSTRAINT user_se_competency_survey_results_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(id);


--
-- Name: user_se_competency_survey_results user_se_competency_survey_results_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.user_se_competency_survey_results
    ADD CONSTRAINT user_se_competency_survey_results_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_survey_type user_survey_type_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.user_survey_type
    ADD CONSTRAINT user_survey_type_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.app_user(id);


--
-- Name: users users_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ma0349
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO ma0349;
GRANT ALL ON SCHEMA public TO seqpt_admin;


--
-- Name: TABLE app_user; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.app_user TO seqpt_admin;


--
-- Name: SEQUENCE app_user_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.app_user_id_seq TO seqpt_admin;


--
-- Name: TABLE assessments; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.assessments TO seqpt_admin;


--
-- Name: SEQUENCE assessments_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.assessments_id_seq TO seqpt_admin;


--
-- Name: TABLE company_contexts; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.company_contexts TO seqpt_admin;


--
-- Name: SEQUENCE company_contexts_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.company_contexts_id_seq TO seqpt_admin;


--
-- Name: TABLE competency; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.competency TO seqpt_admin;


--
-- Name: TABLE competency_assessment_results; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.competency_assessment_results TO seqpt_admin;


--
-- Name: SEQUENCE competency_assessment_results_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.competency_assessment_results_id_seq TO seqpt_admin;


--
-- Name: SEQUENCE competency_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.competency_id_seq TO seqpt_admin;


--
-- Name: TABLE competency_indicators; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.competency_indicators TO seqpt_admin;


--
-- Name: SEQUENCE competency_indicators_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.competency_indicators_id_seq TO seqpt_admin;


--
-- Name: TABLE iso_activities; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.iso_activities TO seqpt_admin;


--
-- Name: SEQUENCE iso_activities_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.iso_activities_id_seq TO seqpt_admin;


--
-- Name: TABLE iso_processes; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.iso_processes TO seqpt_admin;


--
-- Name: SEQUENCE iso_processes_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.iso_processes_id_seq TO seqpt_admin;


--
-- Name: TABLE iso_system_life_cycle_processes; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.iso_system_life_cycle_processes TO seqpt_admin;


--
-- Name: SEQUENCE iso_system_life_cycle_processes_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.iso_system_life_cycle_processes_id_seq TO seqpt_admin;


--
-- Name: TABLE iso_tasks; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.iso_tasks TO seqpt_admin;


--
-- Name: SEQUENCE iso_tasks_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.iso_tasks_id_seq TO seqpt_admin;


--
-- Name: TABLE learning_modules; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.learning_modules TO seqpt_admin;


--
-- Name: SEQUENCE learning_modules_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.learning_modules_id_seq TO seqpt_admin;


--
-- Name: TABLE learning_objectives; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.learning_objectives TO seqpt_admin;


--
-- Name: SEQUENCE learning_objectives_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.learning_objectives_id_seq TO seqpt_admin;


--
-- Name: TABLE learning_paths; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.learning_paths TO seqpt_admin;


--
-- Name: SEQUENCE learning_paths_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.learning_paths_id_seq TO seqpt_admin;


--
-- Name: TABLE learning_plans; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.learning_plans TO seqpt_admin;


--
-- Name: TABLE learning_resources; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.learning_resources TO seqpt_admin;


--
-- Name: SEQUENCE learning_resources_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.learning_resources_id_seq TO seqpt_admin;


--
-- Name: TABLE maturity_assessments; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.maturity_assessments TO seqpt_admin;


--
-- Name: TABLE module_assessments; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.module_assessments TO seqpt_admin;


--
-- Name: SEQUENCE module_assessments_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.module_assessments_id_seq TO seqpt_admin;


--
-- Name: TABLE module_enrollments; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.module_enrollments TO seqpt_admin;


--
-- Name: SEQUENCE module_enrollments_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.module_enrollments_id_seq TO seqpt_admin;


--
-- Name: TABLE new_survey_user; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.new_survey_user TO seqpt_admin;


--
-- Name: SEQUENCE new_survey_user_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.new_survey_user_id_seq TO seqpt_admin;


--
-- Name: TABLE organization; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.organization TO seqpt_admin;


--
-- Name: SEQUENCE organization_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.organization_id_seq TO seqpt_admin;


--
-- Name: TABLE phase_questionnaire_responses; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.phase_questionnaire_responses TO seqpt_admin;


--
-- Name: TABLE process_competency_matrix; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.process_competency_matrix TO seqpt_admin;


--
-- Name: SEQUENCE process_competency_matrix_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.process_competency_matrix_id_seq TO seqpt_admin;


--
-- Name: TABLE qualification_archetypes; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.qualification_archetypes TO seqpt_admin;


--
-- Name: SEQUENCE qualification_archetypes_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.qualification_archetypes_id_seq TO seqpt_admin;


--
-- Name: TABLE qualification_plans; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.qualification_plans TO seqpt_admin;


--
-- Name: SEQUENCE qualification_plans_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.qualification_plans_id_seq TO seqpt_admin;


--
-- Name: TABLE question_options; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.question_options TO seqpt_admin;


--
-- Name: SEQUENCE question_options_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.question_options_id_seq TO seqpt_admin;


--
-- Name: TABLE question_responses; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.question_responses TO seqpt_admin;


--
-- Name: SEQUENCE question_responses_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.question_responses_id_seq TO seqpt_admin;


--
-- Name: TABLE questionnaire_responses; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.questionnaire_responses TO seqpt_admin;


--
-- Name: SEQUENCE questionnaire_responses_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.questionnaire_responses_id_seq TO seqpt_admin;


--
-- Name: TABLE questionnaires; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.questionnaires TO seqpt_admin;


--
-- Name: SEQUENCE questionnaires_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.questionnaires_id_seq TO seqpt_admin;


--
-- Name: TABLE questions; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.questions TO seqpt_admin;


--
-- Name: SEQUENCE questions_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.questions_id_seq TO seqpt_admin;


--
-- Name: TABLE rag_templates; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.rag_templates TO seqpt_admin;


--
-- Name: SEQUENCE rag_templates_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.rag_templates_id_seq TO seqpt_admin;


--
-- Name: TABLE role_cluster; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.role_cluster TO seqpt_admin;


--
-- Name: SEQUENCE role_cluster_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.role_cluster_id_seq TO seqpt_admin;


--
-- Name: TABLE role_competency_matrix; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.role_competency_matrix TO seqpt_admin;


--
-- Name: SEQUENCE role_competency_matrix_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.role_competency_matrix_id_seq TO seqpt_admin;


--
-- Name: TABLE role_process_matrix; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.role_process_matrix TO seqpt_admin;


--
-- Name: SEQUENCE role_process_matrix_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.role_process_matrix_id_seq TO seqpt_admin;


--
-- Name: TABLE unknown_role_competency_matrix; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.unknown_role_competency_matrix TO seqpt_admin;


--
-- Name: SEQUENCE unknown_role_competency_matrix_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.unknown_role_competency_matrix_id_seq TO seqpt_admin;


--
-- Name: TABLE unknown_role_process_matrix; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.unknown_role_process_matrix TO seqpt_admin;


--
-- Name: SEQUENCE unknown_role_process_matrix_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.unknown_role_process_matrix_id_seq TO seqpt_admin;


--
-- Name: TABLE user_competency_survey_feedback; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.user_competency_survey_feedback TO seqpt_admin;


--
-- Name: SEQUENCE user_competency_survey_feedback_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.user_competency_survey_feedback_id_seq TO seqpt_admin;


--
-- Name: TABLE user_role_cluster; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.user_role_cluster TO seqpt_admin;


--
-- Name: TABLE user_se_competency_survey_results; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.user_se_competency_survey_results TO seqpt_admin;


--
-- Name: SEQUENCE user_se_competency_survey_results_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.user_se_competency_survey_results_id_seq TO seqpt_admin;


--
-- Name: TABLE user_survey_type; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.user_survey_type TO seqpt_admin;


--
-- Name: SEQUENCE user_survey_type_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.user_survey_type_id_seq TO seqpt_admin;


--
-- Name: TABLE users; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON TABLE public.users TO seqpt_admin;


--
-- Name: SEQUENCE users_id_seq; Type: ACL; Schema: public; Owner: ma0349
--

GRANT ALL ON SEQUENCE public.users_id_seq TO seqpt_admin;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO ma0349;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO seqpt_admin;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO ma0349;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO seqpt_admin;


--
-- PostgreSQL database dump complete
--

