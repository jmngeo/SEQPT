--
-- PostgreSQL database dump
--

-- Dumped from database version 16.3
-- Dumped by pg_dump version 16.4 (Homebrew)

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

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: azure_pg_admin
--

-- *not* creating schema, since initdb creates it



--
-- Name: get_competency_results(integer, integer); Type: FUNCTION; Schema: public; Owner: adminderik
--

CREATE FUNCTION public.get_competency_results(p_user_id integer, p_organization_id integer) RETURNS TABLE(competency_area text, competency_name text, user_recorded_level text, user_recorded_level_competency_indicator text, user_required_level text, user_required_level_competency_indicator text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    WITH recorded_competencies AS (
        SELECT sr.competency_id, 
               c.competency_area::TEXT,  -- Cast to TEXT
               c.competency_name::TEXT,  -- Cast to TEXT
               sr.score AS user_score
        FROM user_se_competency_survey_results sr
        LEFT JOIN competency c ON sr.competency_id = c.id
        WHERE sr.user_id = p_user_id
    ),
    required_competencies AS (
        SELECT competency_id, MAX(role_competency_value) AS max_score
        FROM role_competency_matrix
        WHERE organization_id = p_organization_id 
          AND role_cluster_id IN (
              SELECT role_cluster_id
              FROM user_role_cluster
              WHERE user_id = p_user_id
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
    SELECT rrw.competency_area::TEXT,  -- Cast to TEXT
           rrw.competency_name::TEXT,  -- Cast to TEXT
           COALESCE(rrw.recorded_level, 'unwissend')::TEXT AS user_recorded_level,  -- Cast to TEXT
           COALESCE(rrw.recorded_level_indicators, 'You are unaware or lacks knowledge in this competency area')::TEXT AS user_recorded_level_competency_indicator,  -- Cast to TEXT
           rrw.required_level::TEXT AS user_required_level,  -- Cast to TEXT
           rrw.required_level_indicators::TEXT AS user_required_level_competency_indicator  -- Cast to TEXT
    FROM required_vs_recorded_with_indicators_joined_by_req_joined_by_rec rrw order by rrw.competency_area;
END;
$$;




--
-- Name: get_competency_results(character varying, integer); Type: FUNCTION; Schema: public; Owner: adminderik
--

CREATE FUNCTION public.get_competency_results(p_username character varying, p_organization_id integer) RETURNS TABLE(competency_area text, competency_name text, user_recorded_level text, user_recorded_level_competency_indicator text, user_required_level text, user_required_level_competency_indicator text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    WITH recorded_competencies AS (
        SELECT sr.competency_id, 
               c.competency_area::TEXT,  -- Cast to TEXT
               c.competency_name::TEXT,  -- Cast to TEXT
               sr.score AS user_score
        FROM user_se_competency_survey_results sr
        LEFT JOIN competency c ON sr.competency_id = c.id
        WHERE sr.user_id IN (select id  from app_user where username= p_username and organization_id = p_organization_id )
    ),
    required_competencies AS (
        SELECT competency_id, MAX(role_competency_value) AS max_score
        FROM role_competency_matrix
        WHERE organization_id = p_organization_id 
          AND role_cluster_id IN (
              SELECT role_cluster_id
              FROM user_role_cluster
              WHERE user_id IN (select id  from app_user where username= p_username and organization_id = p_organization_id )
			  AND role_cluster_id NOT IN (40004, 70007)
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
    SELECT rrw.competency_area::TEXT,  -- Cast to TEXT
           rrw.competency_name::TEXT,  -- Cast to TEXT
           COALESCE(rrw.recorded_level, 'unwissend')::TEXT AS user_recorded_level,  -- Cast to TEXT
           COALESCE(rrw.recorded_level_indicators, 'You are unaware or lacks knowledge in this competency area')::TEXT AS user_recorded_level_competency_indicator,  -- Cast to TEXT
           rrw.required_level::TEXT AS user_required_level,  -- Cast to TEXT
           rrw.required_level_indicators::TEXT AS user_required_level_competency_indicator  -- Cast to TEXT
    FROM required_vs_recorded_with_indicators_joined_by_req_joined_by_rec rrw order by rrw.competency_area;
END;
$$;



--
-- Name: get_unknown_role_competency_results(character varying, integer); Type: FUNCTION; Schema: public; Owner: adminderik
--

CREATE FUNCTION public.get_unknown_role_competency_results(p_username character varying, p_organization_id integer) RETURNS TABLE(competency_area text, competency_name text, user_recorded_level text, user_recorded_level_competency_indicator text, user_required_level text, user_required_level_competency_indicator text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
 WITH recorded_competencies AS (
        SELECT sr.competency_id, 
               c.competency_area::TEXT,  -- Cast to TEXT
               c.competency_name::TEXT,  -- Cast to TEXT
               sr.score AS user_score
        FROM user_se_competency_survey_results sr
        LEFT JOIN competency c ON sr.competency_id = c.id
        WHERE sr.user_id IN (select id  from app_user where username= p_username and organization_id = p_organization_id )
    ),
    required_competencies AS (
        select competency_id,role_competency_value as max_score
		from unknown_role_competency_matrix urcm 
		where user_name = p_username and organization_id = p_organization_id
    ),
    required_vs_recorded AS (
        SELECT rec.*, req.max_score
        FROM recorded_competencies rec
        LEFT JOIN required_competencies req ON rec.competency_id = req.competency_id
    ),
    competency_indicators_with_score AS (
        SELECT competency_id, "level",
               CASE
                   WHEN "level" = 'kennen' THEN p_organization_id
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
    SELECT rrw.competency_area::TEXT,  -- Cast to TEXT
           rrw.competency_name::TEXT,  -- Cast to TEXT
           COALESCE(rrw.recorded_level, 'unwissend')::TEXT AS user_recorded_level,  -- Cast to TEXT
           COALESCE(rrw.recorded_level_indicators, 'You are unaware or lacks knowledge in this competency area')::TEXT AS user_recorded_level_competency_indicator,  -- Cast to TEXT
           rrw.required_level::TEXT AS user_required_level,  -- Cast to TEXT
           rrw.required_level_indicators::TEXT AS user_required_level_competency_indicator  -- Cast to TEXT
    FROM required_vs_recorded_with_indicators_joined_by_req_joined_by_rec rrw order by rrw.competency_area;
    
   
  END;
$$;




--
-- Name: insert_new_org_default_role_competency_matrix(integer); Type: PROCEDURE; Schema: public; Owner: adminderik
--

CREATE PROCEDURE public.insert_new_org_default_role_competency_matrix(IN _organization_id integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Insert rows into role_competency_matrix where organization_id is 1
    INSERT INTO public.role_competency_matrix (role_cluster_id, competency_id, role_competency_value, organization_id)
    SELECT 
        role_cluster_id, 
        competency_id, 
        role_competency_value, 
        _organization_id  -- Hardcode the organization_id to the value passed as a parameter
    FROM public.role_competency_matrix
    WHERE organization_id = 1;

    RAISE NOTICE 'Rows successfully inserted into role_competency_matrix with organization_id %', _organization_id;

END;
$$;




--
-- Name: insert_new_org_default_role_process_matrix(integer); Type: PROCEDURE; Schema: public; Owner: adminderik
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
        _organization_id  -- Hardcode the organization_id to the value passed as a parameter
    FROM public.role_process_matrix
    WHERE organization_id = 1;

    RAISE NOTICE 'Rows successfully inserted into role_process_matrix with organization_id %', _organization_id;

END;
$$;



--
-- Name: refresh_role_competency_matrix(); Type: FUNCTION; Schema: public; Owner: adminderik
--

CREATE FUNCTION public.refresh_role_competency_matrix() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Step 1: Truncate the existing table to remove old data
    TRUNCATE TABLE public.role_competency_matrix;

    -- Step 2: Insert the updated data using the logic for calculating the role-competency matrix
    INSERT INTO public.role_competency_matrix (role_cluster_id, competency_id, role_competency_value)
    SELECT 
        rpm.role_cluster_id,
        pcm.competency_id,
        SUM(rpm.role_process_value * pcm.relevance_value) AS role_competency_value
    FROM 
        public.role_process_matrix rpm
    JOIN 
        public.process_competency_matrix pcm 
        ON rpm.iso_process_id = pcm.iso_process_id
    GROUP BY 
        rpm.role_cluster_id, pcm.competency_id;
    
    -- Note: The SUM here is to aggregate the values for the role-competency relationships.
    -- Depending on your logic, you might want to customize this step.

END;
$$;




--
-- Name: set_username(); Type: FUNCTION; Schema: public; Owner: adminderik
--

CREATE FUNCTION public.set_username() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.id IS NULL THEN
    NEW.id := nextval(pg_get_serial_sequence('new_survey_user', 'id'));
  END IF;
  NEW.username := 'se_surver_user_' || NEW.id;
  RETURN NEW;
END;
$$;






CREATE PROCEDURE public.update_role_competency_matrix()
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Step 1: Truncate the role_competency_matrix table to clear previous entries
    TRUNCATE TABLE public.role_competency_matrix RESTART IDENTITY;

    -- Step 2: Insert calculated role-competency relationships into the matrix
    INSERT INTO public.role_competency_matrix (role_cluster_id, competency_id, role_competency_value)
    SELECT
        rpm.role_cluster_id,
        pcm.competency_id,
        MAX(
            CASE
                -- Multiply role_process_value and process_competency_value to get the result value
                WHEN rpm.role_process_value * pcm.process_competency_value = 0 THEN 0 -- "nicht relevant"
                WHEN rpm.role_process_value * pcm.process_competency_value = 1 THEN 1 -- "anwenden"
                WHEN rpm.role_process_value * pcm.process_competency_value = 2 THEN 2 -- "verstehen"
                WHEN rpm.role_process_value * pcm.process_competency_value = 3 THEN 3 -- "anwenden"
                WHEN rpm.role_process_value * pcm.process_competency_value = 4 THEN 4 -- "anwenden"
                WHEN rpm.role_process_value * pcm.process_competency_value = 6 THEN 6 -- "beherrschen"
                ELSE -100 -- Default to "invalid" (if no valid combination is found)
            END
        ) AS role_competency_value
    FROM
        public.role_process_matrix rpm
    JOIN
        public.process_competency_matrix pcm
    ON
        rpm.iso_process_id = pcm.iso_process_id
    GROUP BY
        rpm.role_cluster_id, pcm.competency_id;

    RAISE NOTICE 'Role-Competency matrix updated successfully';

END $$;



--
-- Name: update_role_competency_matrix(integer); Type: PROCEDURE; Schema: public; Owner: adminderik
--

CREATE PROCEDURE public.update_role_competency_matrix(IN _organization_id integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Step 1: Delete existing entries for the given organization_id from role_competency_matrix
    DELETE FROM public.role_competency_matrix
    WHERE organization_id = _organization_id;

    -- Step 2: Insert calculated role-competency relationships into the matrix for the given organization
    INSERT INTO public.role_competency_matrix (role_cluster_id, competency_id, role_competency_value, organization_id)
    SELECT
        rpm.role_cluster_id,
        pcm.competency_id,
        MAX(
            CASE
                -- Multiply role_process_value and process_competency_value to get the result value
                WHEN rpm.role_process_value * pcm.process_competency_value = 0 THEN 0 -- "nicht relevant"
                WHEN rpm.role_process_value * pcm.process_competency_value = 1 THEN 1 -- "anwenden"
                WHEN rpm.role_process_value * pcm.process_competency_value = 2 THEN 2 -- "verstehen"
                WHEN rpm.role_process_value * pcm.process_competency_value = 3 THEN 3 -- "anwenden"
                WHEN rpm.role_process_value * pcm.process_competency_value = 4 THEN 4 -- "anwenden"
                WHEN rpm.role_process_value * pcm.process_competency_value = 6 THEN 6 -- "beherrschen"
                ELSE -100 -- Default to "invalid" (if no valid combination is found)
            END
        ) AS role_competency_value,
        _organization_id -- Insert the given organization_id
    FROM
        public.role_process_matrix rpm
    JOIN
        public.process_competency_matrix pcm
    ON
        rpm.iso_process_id = pcm.iso_process_id
    WHERE
        rpm.organization_id = _organization_id -- Filter by the given organization_id
    GROUP BY
        rpm.role_cluster_id, pcm.competency_id;

    RAISE NOTICE 'Role-Competency matrix updated successfully for organization_id %', _organization_id;

END $$;



--
-- Name: update_unknown_role_competency_values(text, integer); Type: PROCEDURE; Schema: public; Owner: adminderik
--

CREATE PROCEDURE public.update_unknown_role_competency_values(IN input_user_name text, IN input_organization_id integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- First delete any existing entries for the user and organization in the target table
    DELETE FROM unknown_role_competency_matrix
    WHERE user_name = input_user_name
      AND organization_id = input_organization_id;

    -- Insert the results from your logic into the unknown_role_competency_matrix table
    INSERT INTO unknown_role_competency_matrix (user_name, competency_id, role_competency_value, organization_id)
    SELECT 
        urpm.user_name::VARCHAR(50), -- Explicitly cast to match the declared type
        pcm.competency_id,
        MAX(
            CASE
                -- Multiply role_process_value and process_competency_value to get the result value
                WHEN urpm.role_process_value * pcm.process_competency_value = 0 THEN 0 -- "nicht relevant"
                WHEN urpm.role_process_value * pcm.process_competency_value = 1 THEN 1 -- "anwenden"
                WHEN urpm.role_process_value * pcm.process_competency_value = 2 THEN 2 -- "verstehen"
                WHEN urpm.role_process_value * pcm.process_competency_value = 3 THEN 3 -- "anwenden"
                WHEN urpm.role_process_value * pcm.process_competency_value = 4 THEN 4 -- "anwenden"
                WHEN urpm.role_process_value * pcm.process_competency_value = 6 THEN 6 -- "beherrschen"
                ELSE -100 -- Default to "invalid" (if no valid combination is found)
            END
        ) AS role_competency_value,
        input_organization_id AS organization_id
    FROM public.unknown_role_process_matrix urpm 
    JOIN public.process_competency_matrix pcm 
    ON urpm.iso_process_id = pcm.iso_process_id 
    WHERE urpm.organization_id = input_organization_id
    AND urpm.user_name = input_user_name
    GROUP BY urpm.user_name, pcm.competency_id;

END;
$$;



SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: admin_user; Type: TABLE; Schema: public; Owner: adminderik
--

CREATE TABLE public.admin_user (
    id integer NOT NULL,
    username character varying(255) NOT NULL,
    password_hash text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);



--
-- Name: admin_user_id_seq; Type: SEQUENCE; Schema: public; Owner: adminderik
--

CREATE SEQUENCE public.admin_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: admin_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: adminderik
--

ALTER SEQUENCE public.admin_user_id_seq OWNED BY public.admin_user.id;


--
-- Name: alembic_version; Type: TABLE; Schema: public; Owner: adminderik
--

CREATE TABLE public.alembic_version (
    version_num character varying(32) NOT NULL
);



--
-- Name: app_user; Type: TABLE; Schema: public; Owner: adminderik
--

CREATE TABLE public.app_user (
    id integer NOT NULL,
    organization_id integer NOT NULL,
    name character varying(255) NOT NULL,
    username character varying(255) NOT NULL,
    tasks_responsibilities jsonb
);



--
-- Name: app_user_id_seq; Type: SEQUENCE; Schema: public; Owner: adminderik
--

CREATE SEQUENCE public.app_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: app_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: adminderik
--

ALTER SEQUENCE public.app_user_id_seq OWNED BY public.app_user.id;


--
-- Name: competency; Type: TABLE; Schema: public; Owner: adminderik
--

CREATE TABLE public.competency (
    id integer NOT NULL,
    competency_area character varying(50),
    competency_name character varying(255) NOT NULL,
    description text,
    why_it_matters text
);



--
-- Name: competency_id_seq; Type: SEQUENCE; Schema: public; Owner: adminderik
--

CREATE SEQUENCE public.competency_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: competency_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: adminderik
--

ALTER SEQUENCE public.competency_id_seq OWNED BY public.competency.id;


--
-- Name: competency_indicators; Type: TABLE; Schema: public; Owner: adminderik
--

CREATE TABLE public.competency_indicators (
    id integer NOT NULL,
    competency_id integer,
    level character varying(50),
    indicator_en text,
    indicator_de text
);



--
-- Name: competency_indicators_backup01112024; Type: TABLE; Schema: public; Owner: adminderik
--

CREATE TABLE public.competency_indicators_backup01112024 (
    id integer,
    competency_id integer,
    level character varying(50),
    indicator text
);



--
-- Name: competency_indicators_id_seq; Type: SEQUENCE; Schema: public; Owner: adminderik
--

CREATE SEQUENCE public.competency_indicators_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: competency_indicators_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: adminderik
--

ALTER SEQUENCE public.competency_indicators_id_seq OWNED BY public.competency_indicators.id;


--
-- Name: iso_activities; Type: TABLE; Schema: public; Owner: adminderik
--

CREATE TABLE public.iso_activities (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    process_id integer
);



--
-- Name: iso_activities_id_seq; Type: SEQUENCE; Schema: public; Owner: adminderik
--

CREATE SEQUENCE public.iso_activities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: iso_activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: adminderik
--

ALTER SEQUENCE public.iso_activities_id_seq OWNED BY public.iso_activities.id;


--
-- Name: iso_processes; Type: TABLE; Schema: public; Owner: adminderik
--

CREATE TABLE public.iso_processes (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    life_cycle_process_id integer
);



--
-- Name: iso_processes_id_seq; Type: SEQUENCE; Schema: public; Owner: adminderik
--

CREATE SEQUENCE public.iso_processes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: iso_processes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: adminderik
--

ALTER SEQUENCE public.iso_processes_id_seq OWNED BY public.iso_processes.id;


--
-- Name: iso_system_life_cycle_processes; Type: TABLE; Schema: public; Owner: adminderik
--

CREATE TABLE public.iso_system_life_cycle_processes (
    id integer NOT NULL,
    name character varying(255) NOT NULL
);



--
-- Name: iso_system_life_cycle_processes_id_seq; Type: SEQUENCE; Schema: public; Owner: adminderik
--

CREATE SEQUENCE public.iso_system_life_cycle_processes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: iso_system_life_cycle_processes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: adminderik
--

ALTER SEQUENCE public.iso_system_life_cycle_processes_id_seq OWNED BY public.iso_system_life_cycle_processes.id;


--
-- Name: iso_tasks; Type: TABLE; Schema: public; Owner: adminderik
--

CREATE TABLE public.iso_tasks (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    activity_id integer
);



--
-- Name: iso_tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: adminderik
--

CREATE SEQUENCE public.iso_tasks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: iso_tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: adminderik
--

ALTER SEQUENCE public.iso_tasks_id_seq OWNED BY public.iso_tasks.id;


--
-- Name: new_survey_user; Type: TABLE; Schema: public; Owner: adminderik
--

CREATE TABLE public.new_survey_user (
    id integer NOT NULL,
    username character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    survey_completion_status boolean DEFAULT false NOT NULL
);



--
-- Name: new_survey_user_id_seq; Type: SEQUENCE; Schema: public; Owner: adminderik
--

CREATE SEQUENCE public.new_survey_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: new_survey_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: adminderik
--

ALTER SEQUENCE public.new_survey_user_id_seq OWNED BY public.new_survey_user.id;


--
-- Name: organization; Type: TABLE; Schema: public; Owner: adminderik
--

CREATE TABLE public.organization (
    id integer NOT NULL,
    organization_name character varying(255) NOT NULL,
    organization_public_key character varying(50) DEFAULT 'singleuser'::character varying NOT NULL
);



--
-- Name: organization_id_seq; Type: SEQUENCE; Schema: public; Owner: adminderik
--

CREATE SEQUENCE public.organization_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: organization_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: adminderik
--

ALTER SEQUENCE public.organization_id_seq OWNED BY public.organization.id;


--
-- Name: process_competency_matrix; Type: TABLE; Schema: public; Owner: adminderik
--

CREATE TABLE public.process_competency_matrix (
    id integer NOT NULL,
    iso_process_id integer NOT NULL,
    competency_id integer NOT NULL,
    process_competency_value integer DEFAULT '-100'::integer,
    CONSTRAINT process_competency_matrix_process_competency_value_check CHECK ((process_competency_value = ANY (ARRAY['-100'::integer, 0, 1, 2])))
);



--
-- Name: process_competency_matrix_id_seq; Type: SEQUENCE; Schema: public; Owner: adminderik
--

CREATE SEQUENCE public.process_competency_matrix_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: process_competency_matrix_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: adminderik
--

ALTER SEQUENCE public.process_competency_matrix_id_seq OWNED BY public.process_competency_matrix.id;


--
-- Name: role_cluster; Type: TABLE; Schema: public; Owner: adminderik
--

CREATE TABLE public.role_cluster (
    id integer NOT NULL,
    role_cluster_name character varying(255) NOT NULL,
    role_cluster_description text NOT NULL
);



--
-- Name: role_cluster_id_seq; Type: SEQUENCE; Schema: public; Owner: adminderik
--

CREATE SEQUENCE public.role_cluster_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: role_cluster_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: adminderik
--

ALTER SEQUENCE public.role_cluster_id_seq OWNED BY public.role_cluster.id;


--
-- Name: role_competency_matrix; Type: TABLE; Schema: public; Owner: adminderik
--

CREATE TABLE public.role_competency_matrix (
    id integer NOT NULL,
    role_cluster_id integer NOT NULL,
    competency_id integer NOT NULL,
    role_competency_value integer DEFAULT '-100'::integer NOT NULL,
    organization_id integer NOT NULL,
    CONSTRAINT role_competency_matrix_role_competency_value_check CHECK ((role_competency_value = ANY (ARRAY['-100'::integer, 0, 1, 2, 3, 4, 6])))
);



--
-- Name: role_competency_matrix_id_seq; Type: SEQUENCE; Schema: public; Owner: adminderik
--

CREATE SEQUENCE public.role_competency_matrix_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: role_competency_matrix_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: adminderik
--

ALTER SEQUENCE public.role_competency_matrix_id_seq OWNED BY public.role_competency_matrix.id;


--
-- Name: role_process_matrix; Type: TABLE; Schema: public; Owner: adminderik
--

CREATE TABLE public.role_process_matrix (
    id integer NOT NULL,
    role_cluster_id integer NOT NULL,
    iso_process_id integer NOT NULL,
    role_process_value integer DEFAULT '-100'::integer,
    organization_id integer NOT NULL,
    CONSTRAINT role_process_matrix_role_process_value_check CHECK ((role_process_value = ANY (ARRAY['-100'::integer, 0, 1, 2, 3])))
);



--
-- Name: role_process_matrix_id_seq; Type: SEQUENCE; Schema: public; Owner: adminderik
--

CREATE SEQUENCE public.role_process_matrix_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: role_process_matrix_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: adminderik
--

ALTER SEQUENCE public.role_process_matrix_id_seq OWNED BY public.role_process_matrix.id;


--
-- Name: unknown_role_competency_matrix; Type: TABLE; Schema: public; Owner: adminderik
--

CREATE TABLE public.unknown_role_competency_matrix (
    id integer NOT NULL,
    user_name character varying(50) NOT NULL,
    competency_id integer NOT NULL,
    role_competency_value integer DEFAULT '-100'::integer NOT NULL,
    organization_id integer NOT NULL,
    CONSTRAINT unknown_role_competency_matrix_role_competency_value_check CHECK ((role_competency_value = ANY (ARRAY['-100'::integer, 0, 1, 2, 3, 4, 6])))
);



--
-- Name: unknown_role_competency_matrix_id_seq; Type: SEQUENCE; Schema: public; Owner: adminderik
--

CREATE SEQUENCE public.unknown_role_competency_matrix_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: unknown_role_competency_matrix_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: adminderik
--

ALTER SEQUENCE public.unknown_role_competency_matrix_id_seq OWNED BY public.unknown_role_competency_matrix.id;


--
-- Name: unknown_role_process_matrix; Type: TABLE; Schema: public; Owner: adminderik
--

CREATE TABLE public.unknown_role_process_matrix (
    id integer NOT NULL,
    user_name character varying(50) NOT NULL,
    iso_process_id integer NOT NULL,
    role_process_value integer DEFAULT '-100'::integer,
    organization_id integer NOT NULL,
    CONSTRAINT unknown_role_process_matrix_role_process_value_check CHECK ((role_process_value = ANY (ARRAY['-100'::integer, 0, 1, 2, 3])))
);



--
-- Name: unknown_role_process_matrix_id_seq; Type: SEQUENCE; Schema: public; Owner: adminderik
--

CREATE SEQUENCE public.unknown_role_process_matrix_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: unknown_role_process_matrix_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: adminderik
--

ALTER SEQUENCE public.unknown_role_process_matrix_id_seq OWNED BY public.unknown_role_process_matrix.id;


--
-- Name: user_competency_survey_feedback; Type: TABLE; Schema: public; Owner: adminderik
--

CREATE TABLE public.user_competency_survey_feedback (
    id integer NOT NULL,
    user_id integer NOT NULL,
    organization_id integer NOT NULL,
    feedback jsonb NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);



--
-- Name: user_competency_survey_feedback_id_seq; Type: SEQUENCE; Schema: public; Owner: adminderik
--

CREATE SEQUENCE public.user_competency_survey_feedback_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: user_competency_survey_feedback_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: adminderik
--

ALTER SEQUENCE public.user_competency_survey_feedback_id_seq OWNED BY public.user_competency_survey_feedback.id;


--
-- Name: user_role_cluster; Type: TABLE; Schema: public; Owner: adminderik
--

CREATE TABLE public.user_role_cluster (
    user_id integer NOT NULL,
    role_cluster_id integer NOT NULL
);



--
-- Name: user_se_competency_survey_results; Type: TABLE; Schema: public; Owner: adminderik
--

CREATE TABLE public.user_se_competency_survey_results (
    id integer NOT NULL,
    user_id integer,
    organization_id integer,
    competency_id integer,
    score integer NOT NULL,
    submitted_at timestamp without time zone DEFAULT now()
);



--
-- Name: user_se_competency_survey_results_id_seq; Type: SEQUENCE; Schema: public; Owner: adminderik
--

CREATE SEQUENCE public.user_se_competency_survey_results_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: user_se_competency_survey_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: adminderik
--

ALTER SEQUENCE public.user_se_competency_survey_results_id_seq OWNED BY public.user_se_competency_survey_results.id;


--
-- Name: user_survey_type; Type: TABLE; Schema: public; Owner: adminderik
--

CREATE TABLE public.user_survey_type (
    id integer NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    survey_type character varying(50) DEFAULT 'known_role'::character varying NOT NULL
);



--
-- Name: user_survey_type_id_seq; Type: SEQUENCE; Schema: public; Owner: adminderik
--

CREATE SEQUENCE public.user_survey_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: user_survey_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: adminderik
--

ALTER SEQUENCE public.user_survey_type_id_seq OWNED BY public.user_survey_type.id;


--
-- Name: admin_user id; Type: DEFAULT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.admin_user ALTER COLUMN id SET DEFAULT nextval('public.admin_user_id_seq'::regclass);


--
-- Name: app_user id; Type: DEFAULT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.app_user ALTER COLUMN id SET DEFAULT nextval('public.app_user_id_seq'::regclass);


--
-- Name: competency id; Type: DEFAULT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.competency ALTER COLUMN id SET DEFAULT nextval('public.competency_id_seq'::regclass);


--
-- Name: competency_indicators id; Type: DEFAULT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.competency_indicators ALTER COLUMN id SET DEFAULT nextval('public.competency_indicators_id_seq'::regclass);


--
-- Name: iso_activities id; Type: DEFAULT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.iso_activities ALTER COLUMN id SET DEFAULT nextval('public.iso_activities_id_seq'::regclass);


--
-- Name: iso_processes id; Type: DEFAULT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.iso_processes ALTER COLUMN id SET DEFAULT nextval('public.iso_processes_id_seq'::regclass);


--
-- Name: iso_system_life_cycle_processes id; Type: DEFAULT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.iso_system_life_cycle_processes ALTER COLUMN id SET DEFAULT nextval('public.iso_system_life_cycle_processes_id_seq'::regclass);


--
-- Name: iso_tasks id; Type: DEFAULT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.iso_tasks ALTER COLUMN id SET DEFAULT nextval('public.iso_tasks_id_seq'::regclass);


--
-- Name: new_survey_user id; Type: DEFAULT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.new_survey_user ALTER COLUMN id SET DEFAULT nextval('public.new_survey_user_id_seq'::regclass);


--
-- Name: organization id; Type: DEFAULT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.organization ALTER COLUMN id SET DEFAULT nextval('public.organization_id_seq'::regclass);


--
-- Name: process_competency_matrix id; Type: DEFAULT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.process_competency_matrix ALTER COLUMN id SET DEFAULT nextval('public.process_competency_matrix_id_seq'::regclass);


--
-- Name: role_cluster id; Type: DEFAULT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.role_cluster ALTER COLUMN id SET DEFAULT nextval('public.role_cluster_id_seq'::regclass);


--
-- Name: role_competency_matrix id; Type: DEFAULT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.role_competency_matrix ALTER COLUMN id SET DEFAULT nextval('public.role_competency_matrix_id_seq'::regclass);


--
-- Name: role_process_matrix id; Type: DEFAULT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.role_process_matrix ALTER COLUMN id SET DEFAULT nextval('public.role_process_matrix_id_seq'::regclass);


--
-- Name: unknown_role_competency_matrix id; Type: DEFAULT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.unknown_role_competency_matrix ALTER COLUMN id SET DEFAULT nextval('public.unknown_role_competency_matrix_id_seq'::regclass);


--
-- Name: unknown_role_process_matrix id; Type: DEFAULT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.unknown_role_process_matrix ALTER COLUMN id SET DEFAULT nextval('public.unknown_role_process_matrix_id_seq'::regclass);


--
-- Name: user_competency_survey_feedback id; Type: DEFAULT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.user_competency_survey_feedback ALTER COLUMN id SET DEFAULT nextval('public.user_competency_survey_feedback_id_seq'::regclass);


--
-- Name: user_se_competency_survey_results id; Type: DEFAULT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.user_se_competency_survey_results ALTER COLUMN id SET DEFAULT nextval('public.user_se_competency_survey_results_id_seq'::regclass);


--
-- Name: user_survey_type id; Type: DEFAULT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.user_survey_type ALTER COLUMN id SET DEFAULT nextval('public.user_survey_type_id_seq'::regclass);


--
-- Data for Name: admin_user; Type: TABLE DATA; Schema: public; Owner: adminderik
--

COPY public.admin_user (id, username, password_hash, created_at) FROM stdin;
1	admin	$2b$12$50.2oFpOycIpErhBCN5oAOijGM4g8db9bXRwTti0hh.5JLLmcYCA2	2024-12-12 12:25:57.530938
\.


--
-- Data for Name: alembic_version; Type: TABLE DATA; Schema: public; Owner: adminderik
--

COPY public.alembic_version (version_num) FROM stdin;
9cbcb251f482
\.


--
-- Data for Name: app_user; Type: TABLE DATA; Schema: public; Owner: adminderik
--

COPY public.app_user (id, organization_id, name, username, tasks_responsibilities) FROM stdin;
1	1	Cerin Sabu	cerin	"{\\"responsible_for\\": \\"Requirement Documentation: Document detailed system requirements, ensuring they are comprehensive, traceable, and understandable by all stakeholders.\\\\nRequirement Validation: Verify that the documented requirements meet the customer\\\\u2019s expectations and project goals.\\\\nChange Management: Manage changes to requirements, updating relevant documents and communicating changes to the team.\\", \\"supporting\\": \\"Customer Interaction: Assist the customer representative in clarifying requirements and resolving ambiguities during initial requirements gathering.\\\\nSystem Testing Team: Work with the verification and validation team to ensure test cases are properly derived from the requirements.\\\\nRisk Management Team: Help identify risks related to requirements, such as conflicting needs or feasibility concerns.\\", \\"designing_and_improving\\": \\"Requirement Traceability Matrix: Create a traceability matrix to map each requirement to its corresponding test cases and design elements.\\\\nUse Case Scenarios: Define detailed use case scenarios to help guide system behavior modeling and validation efforts.\\\\nRequirement Specifications: Develop both functional and non-functional requirement specifications, ensuring clarity in system expectations.\\"}"
2	1	Derik 	Roby	"{\\"responsible_for\\": \\"Subsystem Integration: Integrate software, hardware, and network components into the main system, ensuring compatibility and correct functionality.\\\\nIntegration Testing: Conduct integration testing to validate that components interact as expected, resolving any interface issues that arise.\\\\nConfiguration Management: Oversee the configuration of system components during integration, maintaining consistency across versions.\\", \\"supporting\\": \\"Core Systems Engineers: Assist with troubleshooting issues that arise during the integration phase, providing insights into interface requirements and subsystem interactions.\\\\nSpecialist Developers: Work closely with developers to address component-specific issues that affect integration.\\\\nDeployment Team: Support the deployment team by providing guidelines on system configurations, dependencies, and operational workflows.\\", \\"designing_and_improving\\": \\"Integration Strategy: Define the strategy for integrating various system components, outlining steps, sequencing, and dependencies.\\\\nInterface Specifications: Design and document interface specifications for subsystems to ensure proper communication and data exchange.\\\\nIntegration Test Plan: Develop detailed plans for integration testing, specifying the sequence of tests, tools required, and success criteria.\\"}"
3	1	cerin	sabu	"{\\"responsible_for\\": \\"Quality Standards Compliance: Ensure the system complies with relevant industry quality standards and company policies.\\\\nDefect Tracking: Manage a defect tracking system to monitor and resolve issues identified during testing.\\\\nAudit Preparation: Prepare for and support quality audits, ensuring all necessary documentation and evidence are in place.\\", \\"supporting\\": \\"Verification and Validation Team: Collaborate to improve the efficiency and coverage of test cases.\\\\nCustomer Representatives: Assist in translating customer quality expectations into actionable testing and quality criteria.\\\\nProject Management Team: Provide regular updates on quality metrics and status, supporting project decision-making.\\", \\"designing_and_improving\\": \\"Quality Assurance Plan: Design a comprehensive QA plan, outlining processes for testing, inspection, review, and defect management.\\\\nTest Case Development: Define the criteria for test case development, including the scope of functional, performance, and security tests.\\\\nContinuous Improvement Process: Develop procedures for continuous quality improvement, including post-mortem reviews and lessons-learned documentation.\\\\n\\"}"
4	1	derikr	derikr	"{\\"responsible_for\\": \\"test\\", \\"supporting\\": \\"test\\", \\"designing_and_improving\\": \\"test\\"}"
5	1	derikroby	derik	"{\\"responsible_for\\": \\"test\\", \\"supporting\\": \\"test\\", \\"designing_and_improving\\": \\"test\\"}"
6	1	derik	roby	"{\\"responsible_for\\": \\"test\\", \\"supporting\\": \\"test\\", \\"designing_and_improving\\": \\"test\\"}"
7	1	cerin	csabu	"{\\"responsible_for\\": \\"test\\", \\"supporting\\": \\"test\\", \\"designing_and_improving\\": \\"test\\"}"
8	1	csabu	cerappu	"{\\"responsible_for\\": \\"test\\", \\"supporting\\": \\"test\\", \\"designing_and_improving\\": \\"test\\"}"
9	1	derik	drdr	"{\\"responsible_for\\": \\"test\\", \\"supporting\\": \\"test\\", \\"designing_and_improving\\": \\"test\\"}"
10	3	tester	testing	"{\\"responsible_for\\": \\"test\\", \\"supporting\\": \\"test\\", \\"designing_and_improving\\": \\"test\\"}"
11	1	twst	test	"{\\"responsible_for\\": \\"test\\", \\"supporting\\": \\"test\\", \\"designing_and_improving\\": \\"test\\"}"
12	1	derikroby	12345	"{\\"responsible_for\\": \\"task\\", \\"supporting\\": \\"task\\", \\"designing_and_improving\\": \\"task\\"}"
13	1	testuser	testudername	"{\\"responsible_for\\": \\"test\\", \\"supporting\\": \\"test\\", \\"designing_and_improving\\": \\"test\\"}"
14	1	ffdfd	dfdf	"{\\"responsible_for\\": \\"dfdfdf\\", \\"supporting\\": \\"fdf\\", \\"designing_and_improving\\": \\"fdfd\\"}"
15	1	tester123	123	"{\\"responsible_for\\": \\"dsds\\", \\"supporting\\": \\"sdds\\", \\"designing_and_improving\\": \\"sdsds\\"}"
16	1	sddsds	dssd	"{\\"responsible_for\\": \\"dssd\\", \\"supporting\\": \\"sdds\\", \\"designing_and_improving\\": \\"sds\\"}"
17	1	tester123	hellotest	"{\\"responsible_for\\": \\"testing 123\\", \\"supporting\\": \\"testing 123\\", \\"designing_and_improving\\": \\"testing 123\\"}"
18	1	Derik	etstert1234s	"{\\"responsible_for\\": \\"sdsdsd\\", \\"supporting\\": \\"dsdsd\\", \\"designing_and_improving\\": \\"dsdsd\\"}"
19	1	fsfs	fsf	"{\\"responsible_for\\": \\"sffs\\", \\"supporting\\": \\"sffs\\", \\"designing_and_improving\\": \\"fsf\\"}"
20	1	derikrobyderik	d	"{\\"responsible_for\\": \\"dads\\", \\"supporting\\": \\"sdsd\\", \\"designing_and_improving\\": \\"dssdsd\\"}"
21	1	ddderik	drdrdr	"{\\"responsible_for\\": \\"dddd\\", \\"supporting\\": \\"rrrr\\", \\"designing_and_improving\\": \\"cccc\\"}"
22	1	12345	sdsdd	"{\\"responsible_for\\": \\"dsd\\", \\"supporting\\": \\"sdsd\\", \\"designing_and_improving\\": \\"dssd\\"}"
23	1	testingagain	ta	"{\\"responsible_for\\": \\"asas\\", \\"supporting\\": \\"asas\\", \\"designing_and_improving\\": \\"saqs\\"}"
24	1	testing	sdds	"{\\"responsible_for\\": \\"sdsd\\", \\"supporting\\": \\"sdsd\\", \\"designing_and_improving\\": \\"ssdsd\\"}"
25	1	12345	dsdsd	"{\\"responsible_for\\": \\"sds\\", \\"supporting\\": \\"dsds\\", \\"designing_and_improving\\": \\"ddds\\"}"
26	1	hello	hello	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
27	1	dsdsd	wwdew	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
28	1	ceru	ceru	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
91	1	tester3111	tester3111	"{\\"responsible_for\\": [\\"i am responsible for sales of our airplane simulators.\\"], \\"supporting\\": [\\"i support verficiation and validation of final products\\"], \\"designing\\": [\\"i design the validation process\\"]}"
29	1	ceru123	cerappuuu	"{\\"responsible_for\\": [\\"Assist in gathering and documenting system requirements from stakeholders.\\", \\"Monitor and report on system performance during test phases.\\"], \\"supporting\\": [\\"Collaborate with senior engineers to troubleshoot system failures.\\", \\"Create and maintain system documentation, including diagrams and test plans.\\"], \\"designing\\": [\\"Draft basic workflows for system validation and acceptance criteria.\\", \\"Develop test case templates for unit and integration testing.\\"]}"
30	1	kolma	kolma	"{\\"responsible_for\\": [\\"Establish enterprise-wide system engineering policies and frameworks.\\", \\"Lead the risk assessment and mitigation planning for complex projects.\\"], \\"supporting\\": [\\"Provide executive-level guidance on system design and strategy alignment.\\", \\"Support teams in crisis resolution for critical system failures\\"], \\"designing\\": [\\"Architect reusable frameworks for modular system development.\\", \\"Design company-wide knowledge management systems for system documentation.\\"]}"
31	1	ceru	deru	"{\\"responsible_for\\": [\\"Establish enterprise-wide system engineering policies and frameworks.\\", \\"Lead the risk assessment and mitigation planning for complex projects.\\"], \\"supporting\\": [\\"Provide executive-level guidance on system design and strategy alignment.\\", \\"Support teams in crisis resolution for critical system failures.\\"], \\"designing\\": [\\"Architect reusable frameworks for modular system development.\\", \\"Design company-wide knowledge management systems for system documentation.\\"]}"
32	1	ceru	der	"{\\"responsible_for\\": [\\"Establish enterprise-wide system engineering policies and frameworks.\\", \\"Lead the risk assessment and mitigation planning for complex projects.\\"], \\"supporting\\": [\\"Provide executive-level guidance on system design and strategy alignment.\\", \\"Support teams in crisis resolution for critical system failures.\\"], \\"designing\\": [\\"Architect reusable frameworks for modular system development.\\", \\"Design company-wide knowledge management systems for system documentation.\\"]}"
33	1	deruceru	dercer	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
34	1	der	cede	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
35	1	sssd	dssdsd	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
36	1	sffsds	sddds	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
37	1	testuser	testuser	"{\\"responsible_for\\": [\\"Establish enterprise-wide system engineering policies and frameworks.\\", \\"Lead the risk assessment and mitigation planning for complex projects.\\"], \\"supporting\\": [\\"Provide executive-level guidance on system design and strategy alignment.\\", \\"Support teams in crisis resolution for critical system failures.\\"], \\"designing\\": [\\"Architect reusable frameworks for modular system development.\\", \\"Design company-wide knowledge management systems for system documentation.\\"]}"
38	1	tester	tester	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
39	1	takitiki	takitikin	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
40	1	bkbkik	bikpa	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
41	1	tikitaka	taka	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
42	1	pkip	assas	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
43	1	cer	dercerder	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
44	1	testd	testd	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
45	1	hfh	hhhl	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
46	3	derik	cerind	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
47	3	der	dcdc	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
48	12	pqpq	ddasdd	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
49	1	hjkm	vcxy	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
50	1	testuser	testuser12345	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
51	1	blaah	12344	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
52	1	Derik Roby	derroby	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
53	1	Derik Roby	deeroo	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
54	1	derikroby	deroby	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
55	1	derik roby	dece	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
56	1	derik roby	derobydece	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
57	1	derikroby	dercerdercer	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
58	1	deerr	derocc	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
59	1	der	dddd	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
60	1	derder	dederoccc	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
61	1	sddds	dsdssd	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
62	1	dercerdercer	cerder	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
63	1	DerikRoby	123DerikCerinRS	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
64	1	blah	lahblah	"{\\"responsible_for\\": [\\"\\\\\\"Assist the PO in analyzing and translating orthodontic software requirements into design specifications.\\\\\\",\\", \\"\\\\\\"Lead the definition of test scenarios and test cases.\\\\\\",\\", \\"\\\\\\"Extend and update the medical device product documentation to ensure full test coverage and traceability.\\\\\\",\\", \\"\\\\\\"Perform integration, functional, system and regression testing.\\\\\\",\\", \\"\\\\\\"Troubleshoot with incoming operational issues.\\\\\\",\\", \\"\\\\\\"Identify, document, track defects till resolved and deployed.\\\\\\",\\", \\"\\\\\\"Communicate solutions and fixes to other departments/customers.\\\\\\"\\"], \\"supporting\\": [\\"sometimes, i support the management in decision making\\"], \\"designing\\": [\\"\\\\\\"Structure, design and perform automated tests.\\\\\\",\\", \\"\\\\\\"Update and extend the test strategy when needed.\\\\\\"\\"]}"
65	1	dinkadinka	dinkan	"{\\"responsible_for\\": [\\"\\\\\\"responsible_for\\\\\\": [\\", \\"\\\\\\"Design, implement, and document software tests for innovative mechatronic projects.\\\\\\",\\", \\"\\\\\\"Develop detailed test reports, including the analysis and documentation of identified issues.\\\\\\",\\", \\"\\\\\\"Conduct thorough reviews of design documents and test specifications to ensure quality and alignment.\\\\\\",\\", \\"\\\\\\"Maintain and enhance existing test automation frameworks to improve efficiency and reliability.\\\\\\"\\", \\"]\\"], \\"supporting\\": [\\"\\\\\\"supporting\\\\\\": [\\", \\"\\\\\\"Collaborate closely with cross-functional teams, including software development and system design, to drive project success.\\\\\\"\\", \\"]\\"], \\"designing\\": [\\"\\\\\\"designing\\\\\\": [\\", \\"\\\\\\"Design, implement, and document software tests for innovative mechatronic projects.\\\\\\"\\", \\"]\\"]}"
66	1	user9	user91	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
67	1	user9	user92	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
68	1	user9	user912	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
69	1	user1	user9123	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
70	1	derik cerin	dercerlubbu	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
71	1	derik roby	derikroby	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
72	1	Derik Ceru	CeruDeru	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
73	1	Derik Ceru	CeruDeruc	"{\\"responsible_for\\": [\\"collect data from different source systems and store them centrally\\"], \\"supporting\\": [\\"sales team for sales or pre sales\\"], \\"designing\\": [\\"how data is collected and stored\\"]}"
74	1	Cerin 	Cerin1	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
75	1	Derik Roby	dercerdercerder	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
76	1	user1028	user1028	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
77	1	user65	user65	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
78	1	ddd	user45	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
79	1	surveyuser	12343	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
80	1	user34	user34	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
81	1	testerr	testerr	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
82	1	tester434	tester434	"{\\"responsible_for\\": [\\"I manage projects. oversees multiple teams.\\"], \\"supporting\\": [\\"colecting requirements from stakeholders\\"], \\"designing\\": [\\"how to deliver projects on time\\"]}"
83	1	Dffkk	12222	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
84	1	Rainer Zufall	RZ2025	"{\\"responsible_for\\": [\\"I bringe die Fachexperten zusammen und diskutiere mit ihnen. Ich halte Schulungen zum Grundlagen des Systems Engineering, Ich modelliere Zusammenh\\\\u00e4nge und manage Schnittstellen\\"], \\"supporting\\": [\\"Ich unterst\\\\u00fctze beim formulieren von Anforderungen, Ich schreibe Angebote\\"], \\"designing\\": [\\"Not designing any tasks\\"]}"
85	1	derikroby	testeruser12345	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
86	1	tester12345	tester123456	"{\\"responsible_for\\": [\\"i am responsible for supporting the product delivery to clients\\"], \\"supporting\\": [\\"i support maintenance of the system\\"], \\"designing\\": [\\"i design the disposal process for our system\\"]}"
87	1	hauser	hasuser	"{\\"responsible_for\\": [\\"\\\\\\"Festlegung der Systemanforderungen f\\\\u00fcr ein autonomes Fahrzeug.\\\\\\",\\", \\"\\\\\\"Leitung der Integration von Hardware und Software f\\\\u00fcr fortschrittliche Fahrerassistenzsysteme.\\\\\\",\\", \\"\\\\\\"Sicherstellung der Einhaltung von Sicherheitsstandards im Systemdesign.\\\\\\"\\"], \\"supporting\\": [\\"\\\\\\"Koordination mit externen Anbietern zur Systemvalidierung.\\\\\\",\\", \\"\\\\\\"Bereitstellung technischer Anleitung f\\\\u00fcr die Implementierung sicherheitskritischer Systeme.\\\\\\",\\", \\"\\\\\\"Unterst\\\\u00fctzung bei der Risikoabsch\\\\u00e4tzung und -minderung.\\\\\\"\\"], \\"designing\\": [\\"\\\\\\"Erstellung der Systemarchitektur f\\\\u00fcr die Sensorfusion.\\\\\\",\\", \\"\\\\\\"Entwurf einer skalierbaren Testumgebung zur Leistungsanalyse des Systems.\\\\\\",\\", \\"\\\\\\"Entwicklung von Simulationsmodellen zur Validierung von Designentscheidungen.\\\\\\"\\"]}"
88	1	hahaha	hahahauser	"{\\"responsible_for\\": [\\"\\\\\\"Developing integrated system requirements for an autonomous vehicle.\\\\\\",\\", \\"\\\\\\"Leading the hardware-software integration for advanced driver-assistance systems.\\\\\\",\\", \\"\\\\\\"Ensuring compliance with safety standards in system design.\\\\\\"\\"], \\"supporting\\": [\\"\\\\\\"Coordinating with external vendors for system validation.\\\\\\",\\", \\"\\\\\\"Providing technical guidance for the implementation of safety-critical systems.\\\\\\",\\", \\"\\\\\\"Assisting in risk assessment and mitigation planning.\\\\\\"\\"], \\"designing\\": [\\"\\\\\\"Creating system architecture for multi-sensor fusion.\\\\\\",\\", \\"\\\\\\"Designing a scalable test environment for system performance analysis.\\\\\\",\\", \\"\\\\\\"Developing simulation models to validate design decisions.\\\\\\"\\"]}"
89	1	tester321	tester321	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
90	1	testfeedback	testfeedback	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
92	1	cerder	dercerderder	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
93	1	se_surver_user_1	se_surver_user_1	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
94	1	se_surver_user_77	se_surver_user_77	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
95	1	se_surver_user_78	se_surver_user_78	"{\\"responsible_for\\": [\\"i collect data for analyzing the production\\"], \\"supporting\\": [\\"i support in verifiication of results\\"], \\"designing\\": [\\"i dont design anything\\"]}"
96	1	se_surver_user_82	se_surver_user_82	"{\\"responsible_for\\": [\\"i do aquisition of raw material\\"], \\"supporting\\": [\\"i am support disposol of production waste\\"], \\"designing\\": [\\"Not designing any tasks\\"]}"
97	1	se_surver_user_83	se_surver_user_83	"{\\"responsible_for\\": \\"Not Applicable\\", \\"supporting\\": \\"Not Applicable\\", \\"designing_and_improving\\": \\"Not Applicable\\"}"
\.


--
-- Data for Name: competency; Type: TABLE DATA; Schema: public; Owner: adminderik
--

COPY public.competency (id, competency_area, competency_name, description, why_it_matters) FROM stdin;
1	Core	Systems Thinking	The application of the fundamental concepts of systems thinking to Systems Engineering. These concepts include understanding what a system is, its context within itsenvironment, its boundaries and interfaces, and that it has a life cycle. Systems thinking applies to the definition, development, and production of systems within an enterprise andtechnological environment and is a framework for curiosity about any system of interest.	Systems thinking is a way of dealing with increasing complexity. The fundamental concepts of systems thinking involve understanding how actions and decisions in one area affectanother, and that the optimization of a system within its environment does not necessarily come from optimizing the individual system components. Systems thinking is conductedwithin an enterprise and technological context. These contexts impact the life cycle of the system and place requirements and constraints on the systems thinking being conducted.Failing to meet such constraints can have a serious effect on the enterprise and the value of the system.
4	Core	Lifecycle Consideration		
5	Core	Customer / Value Orientation		
6	Core	Systems Modeling and Analysis		
7	Social / Personal	Communication		
8	Social / Personal	Leadership		
9	Social / Personal	Self-Organization		
10	Management	Project Management		
11	Management	Decision Management		
12	Management	Information Management		
13	Management	Configuration Management		
14	Technical	Requirements Definition		
15	Technical	System Architecting		
16	Technical	Integration, Verification,  Validation		
17	Technical	Operation and Support		
18	Technical	Agile Methods		
\.


--
-- Data for Name: competency_indicators; Type: TABLE DATA; Schema: public; Owner: adminderik
--

COPY public.competency_indicators (id, competency_id, level, indicator_en, indicator_de) FROM stdin;
1	1	kennen	You are able to recognize the interrelationships of your system and its boundaries.	Sie kennen die Zusammenhänge Ihres Systems und die dazugehörigen Systemgrenzen.
2	1	verstehen	You understand the interaction of the individual components that make up the system.	Sie verstehen die Wechselwirkung der einzelnen Komponenten, die das System ausmachen.
3	1	anwenden	You are able to analyze your present system and derive continuous improvements from it.	Sie sind in der Lage, Ihr vorliegendes System zu analysieren und daraus kontinuierliche Verbesserungen abzuleiten.
4	1	beherrschen	You are able to carry systemic thinking into the company and inspire others for it.	Sie sind in der Lage, systemisches Denken in das Unternehmen zu tragen und andere dafür zu begeistern.
5	6	kennen	You are familiar with the basics of modeling and its benefits.	Sie kennen die Grundlagen der Modellierung und deren Vorteile.
6	6	verstehen	You understand how models support your work and are able to read simple models.	Sie verstehen, wie Modelle Ihre Arbeit unterstützen und sind in der Lage, einfache Modelle zu lesen.
7	6	anwenden	You are able to define your own system models for the relevant scope independently and can differentiate between cross-domain and domain-specific models.	Sie sind in der Lage, eigene Systemmodelle für ihren relevanten Umfang eigenständig zu definieren und können zwischen domänen-übergreifenden und domänenspezifischen Modellen unterscheiden.
8	6	beherrschen	You can set guidelines for necessary models and write guidelines for good modeling practices.	Sie können Vorgaben für notwendige Modelle machen und Richtlinien für gute Modellierung schreiben.
9	4	kennen	You are able to identify the lifecycle phases of your system.	Sie kennen die Lebenszyklusphasen Ihres Systems.
10	4	verstehen	You understand why and how all lifecycle phases need to be considered during development.	Sie verstehen, warum und wie alle Lebenszyklusphasen im Rahmen der Entwicklung berücksichtigt werden müssen.
11	4	anwenden	You are able to identify, consider, and assess all lifecycle phases relevant to your scope.	Sie sind in der Lage, alle für Ihren Umfang relevanten Lebenszyklusphasen zu identifizieren, zu berücksichtigen und zu bewerten.
12	4	beherrschen	You are able to evaluate concepts regarding the consideration of all lifecycle phases.	Sie sind in der Lage, Konzepte hinsichtlich der Berücksichtigung von allen Lebenszyklusphasen zu bewerten.
13	5	kennen	You are able to identify the fundamental principles of agile thinking.	Sie kennen die Grundprinzipien des agilen Denkens.
14	5	verstehen	You understand how to integrate agile thinking into daily work.	Sie verstehen, wie agiles Denken in den Arbeitsalltag integriert werden kann.
15	5	anwenden	You are able to develop a system using agile methodologies and focus on customer benefit.	Sie sind in der Lage, ein System nach agilen Denkweisen zu entwickeln und den Kundennutzen in den Mittelpunkt zu stellen.
16	5	beherrschen	You are able to promote agile thinking within the organization and inspire others.	Sie sind in der Lage, agiles Denken im Unternehmen zu tragen und andere dafür zu begeistern.
17	14	kennen	You are able to distinguish between needs, stakeholder requirements, system requirements, and system element requirements. You understand the importance of traceability and why tools are necessary for it.	Sie können zwischen Bedürfnissen, Stakeholderanforderungen, Systemanforderungen und Systemelementanforderungen unterscheiden. Sie verstehen die Bedeutung der Nachverfolgbarkeit und warum Werkzeuge dafür notwendig sind.
18	14	kennen	You know the basic process of requirement management including identifying, formulating, deriving and analyzing requirements.	Sie kennen den grundlegenden Ablauf des Anforderungsmanagements, einschließlich des Identifizierens, Formulierens, Ableitens und Analysierens von Anforderungen.
19	14	verstehen	You understand how to identify sources of requirements, derive and write them. You know the different types and levels of requirements.	Sie verstehen, wie Anforderungsquellen identifiziert, Anforderungen abgeleitet und geschrieben werden. Sie kennen die unterschiedlichen Arten und Ebenen von Anforderungen.
20	14	verstehen	You can read requirement documents or models (links, etc.). You can read and understand context descriptions and interface specifications.	Sie können Anforderungsdokumente oder -modelle lesen (Verknüpfungen usw.). Sie können Kontextbeschreibungen und Schnittstellenspezifikationen lesen und verstehen.
21	14	anwenden	You can independently identify sources of requirements, derive, write, and document requirements in documents or models, link, derive, and analyze them.	Sie können selbständig Anforderungsquellen identifizieren, Anforderungen daraus ableiten, schreiben, in Anforderungsdokumenten oder -modellen dokumentieren, verknüpfen, ableiten und analysieren.
22	14	anwenden	You can independently document, link, and analyze requirement documents or models. You can create and analyze context descriptions and interface specifications.	Sie können selbständig Anforderungsdokumente oder -modelle dokumentieren, verknüpfen und analysieren. Sie können Kontextbeschreibungen und Schnittstellenspezifikationen erstellen und analysieren.
23	14	beherrschen	You are able to recognize deficiencies in the process and develop suggestions for improvement.	Sie sind in der Lage, Unzulänglichkeiten im Prozess zu erkennen und Verbesserungsvorschläge zu erarbeiten.
24	14	beherrschen	You can create context and interface descriptions and discuss these with stakeholders.	Sie können Kontext- und Schnittstellenbeschreibungen erstellen und diese mit Stakeholdern diskutieren.
25	15	kennen	You are aware of the purpose of architectural models and can broadly categorize them in the development process.	Sie kennen den Zweck von Architekturmodellen und können sie grob in den Entwicklungsprozess einordnen.
26	15	kennen	You know that there is a dedicated methodology and modeling language for architectural modeling.	Sie wissen, dass es eine dedizierte Methodik und Modellierungssprache zur Architekturmodellierung gibt.
27	15	verstehen	You understand why architectural models are relevant as inputs and outputs of the development process.	Sie können nachvollziehen, warum Architekturmodelle als Inputs und Outputs des Entwicklungsprozesses relevant sind.
28	15	verstehen	You can read architectural models and extract relevant information from them.	Sie können Architekturmodelle lesen und daraus relevante Informationen entnehmen.
29	15	anwenden	You know the relevant process steps for architectural models, where their inputs come from, and the outputs they produce within the development process.	Sie kennen relevante Prozessschritte für Architekturmodelle und wissen, woher ihre Inputs kommen und welche Outputs sie im Entwicklungsprozess produzieren.
30	15	anwenden	You can create architectural models of average complexity, ensuring the information is reproducible and aligned with the methodology and modeling language.	Sie können Architekturmodelle von durchschnittlicher Komplexität erstellen. Sie sind in der Lage, relevante Informationen reproduzierbar und im Einklang mit der Methode und Modellierungssprache abzubilden.
31	15	beherrschen	You can identify shortcomings in the process and develop suggestions for improvement.	Sie sind in der Lage, Unzulänglichkeiten im Prozess zu erkennen und Verbesserungsvorschläge zu erarbeiten.
32	15	beherrschen	You are capable of creating and managing highly complex models, recognizing deficiencies in the method or modeling language, and suggesting improvements.	Sie sind in der Lage, Modelle von hoher Komplexität zu erstellen und zu verwalten. Sie können Unzulänglichkeiten in der Methode oder der Modellierungssprache erkennen und Verbesserungsvorschläge erarbeiten.
33	16	kennen	You are aware of the objectives of verification and validation and know various types and approaches of V&V.	Sie kennen die Ziele der Verifikation und Validierung sowie verschiedene Arten und Vorgehensweisen der V&V.
34	16	verstehen	You can read and understand test plans, test cases, and results.	Sie können Testpläne, Testfälle und -ergebnisse lesen und verstehen.
35	16	anwenden	You can create test plans and are capable of conducting and documenting tests and simulations.	Sie können Testpläne erstellen und sind in der Lage, Tests und Simulationen durchzuführen und zu dokumentieren.
36	16	beherrschen	You are able to independently and proactively set up a testing strategy and an experimental plan. Based on requirements and verification/validation criteria, you can derive necessary test cases and orchestrate and document the tests and simulations.	Sie sind in der Lage, selbständig und frühzeitig eine Teststrategie sowie einen Erprobungsplan aufzusetzen. Anhand der Anforderungen und Verifikation/Validierungskriterien können Sie notwendige Testfälle ableiten und die Tests sowie Simulationen orchestrieren und dokumentieren.
37	17	kennen	You are familiar with the stages of operation, service, and maintenance phases. You understand these are considered during development and involve activities in each phase.	Sie kennen die Phasen des Betriebs, des Services und der Instandhaltung. Sie verstehen, dass diese bereits in der Entwicklung berücksichtigt werden und dass es Tätigkeiten in der jeweiligen Phase gibt.
38	17	verstehen	You understand how the operation, service, and maintenance phases are integrated into the development. You are able to list the activities required throughout the lifecycle.	Sie verstehen, wie die Phasen Betrieb, Service und Instandhaltung in der Entwicklung berücksichtigt werden. Sie sind in der Lage, die im Rahmen des Lebenszyklus notwendigen Tätigkeiten zu nennen.
39	17	anwenden	You can execute the operation, service, and maintenance phases and identify improvements for future projects.	Sie können die Phasen Betrieb, Service und Instandhaltung abwickeln und Verbesserungen für zukünftige Projekte identifizieren.
41	18	kennen	You are able to recognize and list the Agile values and relevant Agile methods.	Sie können die agilen Werte erkennen und die relevanten agilen Methoden auflisten.
42	18	kennen	You are aware of the basic principles of Agile methodologies.	Sie kennen die Grundprinzipien agiler Methodologien.
43	18	verstehen	You understand the fundamentals of Agile workflows and how to apply Agile methods within a development process.	Sie verstehen die Grundlagen agiler Arbeitsweisen und wie sich die agilen Methoden in einem Entwicklungsprozess anwenden lassen.
44	18	verstehen	You are able to explain the impact of Agile practices on project success.	Sie können die Auswirkungen agiler Praktiken auf den Projekterfolg erklären.
45	18	anwenden	You can effectively work in an Agile environment and apply the necessary methods.	Sie können effektiv in einem agilen Umfeld arbeiten und die dafür notwendigen Methoden anwenden.
46	18	anwenden	You are able to adapt Agile techniques to various project scenarios.	Sie können agile Techniken an verschiedene Projektszenarien anpassen.
47	18	beherrschen	You can define and implement the relevant Agile methods for a project, and are convinced of the benefits of using Agile methods.	Sie können die relevanten agilen Methoden für ein Projekt definieren und umsetzen und sind überzeugt von den Vorteilen des Einsatzes agiler Methoden.
48	18	beherrschen	You can motivate others to adopt Agile methods and lead Agile teams successfully.	Sie können andere dazu motivieren, agile Methoden anzuwenden, und agile Teams erfolgreich führen.
49	9	kennen	You are aware of the concepts of self-organization.	Sie kennen die Konzepte der Selbstorganisation.
50	9	verstehen	You understand how self-organization concepts can influence your daily work.	Sie verstehen, wie die Konzepte der Selbstorganisation Ihren Arbeitsalltag beeinflussen können.
51	9	anwenden	You are able to independently manage projects, processes, and tasks using self-organization skills.	Sie sind in der Lage, Projekte, Prozesse und Aufgaben selbstorganisiert abzuarbeiten.
52	9	beherrschen	You can masterfully manage and optimize complex projects and processes through self-organization.	Sie können komplexe Projekte und Prozesse durch Selbstorganisation meisterhaft verwalten und optimieren.
53	7	kennen	You are aware of the necessity of these competencies.	Sie kennen die Notwendigkeit dieser Kompetenzen.
54	7	verstehen	You recognize and understand the relevance of this competency, especially in terms of its application in systems engineering.	Sie erkennen und verstehen die Relevanz dieser Kompetenz, insbesondere im Hinblick auf die Anwendung im Systems Engineering.
55	7	anwenden	You are able to communicate constructively and efficiently while being empathetic towards your communication partner.	Sie sind in der Lage, konstruktiv und effizient zu kommunizieren und gleichzeitig empathisch gegenüber Ihrem Kommunikationspartner zu sein.
56	7	beherrschen	You are able to sustain and fairly manage your relationships with colleagues and supervisors.	Sie sind darüber hinaus in der Lage, Ihre Beziehungen zu Kollegen und Vorgesetzten nachhaltig und fair zu gestalten.
57	8	kennen	You are aware of the necessity of leadership competencies.	Sie kennen die Notwendigkeit von Führungskompetenzen.
58	8	verstehen	You understand the relevance of defining objectives for a system and can articulate these objectives clearly to the entire team.	Sie verstehen die Bedeutung der Definition von Zielen für ein System und können diese für das gesamte Team verständlich definieren.
59	8	anwenden	You are able to negotiate objectives with your team and find an efficient path to achieve them.	Sie sind in der Lage, Ziele mit dem Team zu verhandeln und einen effizienten Weg zur Erreichung dieser zu finden.
60	8	beherrschen	You are able to strategically develop team members so that they evolve in their problem-solving capabilities.	Sie sind in der Lage, Teammitglieder strategisch weiterzuentwickeln, sodass diese sich bei der Lösungsfindung weiterentwickeln.
61	10	kennen	You are able to identify your activities within a project plan.	Sie können Ihre Tätigkeiten in einem Projektplan einordnen.
62	10	kennen	You are familiar with common project management methods.	Sie kennen die gängigen Methoden des Projektmanagements.
63	10	verstehen	You understand the project mandate and can contextualize project management within systems engineering.	Sie verstehen den Projektauftrag und können das Projektmanagement im Kontext des System Engineerings einordnen.
64	10	verstehen	You can create relevant project plans and generate corresponding status reports independently.	Sie können eigenständig die für Sie relevanten Projektpläne erstellen und entsprechende Statusberichte erzeugen.
65	10	anwenden	You are able to define a project mandate, establish conditions, create complex project plans, and produce meaningful reports.	Sie sind in der Lage, einen Projektauftrag zu definieren, Rahmenbedingungen festzulegen, komplexe Projektpläne zu erstellen und aussagekräftige Berichte zu erzeugen.
66	10	anwenden	You are skilled in communicating with stakeholders.	In der Kommunikation mit Stakeholdern sind Sie geübt.
67	10	beherrschen	You can identify inadequacies in the process and suggest improvements.	Sie sind in der Lage, Unzulänglichkeiten im Prozess zu identifizieren und Verbesserungsvorschläge zu machen.
68	10	beherrschen	You can successfully communicate reports, plans, and mandates to all stakeholders.	Sie sind in der Lage, Berichte, Pläne und Aufträge erfolgreich an alle Stakeholder zu kommunizieren.
69	11	kennen	You are aware of the main decision-making bodies and understand how decisions are made.	Sie kennen die wesentlichen Entscheidungsgremien und wissen, wie Entscheidungen getroffen werden.
70	11	verstehen	You understand decision support methods and know which decisions you can make yourself and which are made by committees.	Sie verstehen Entscheidungsunterstützungsmethoden und wissen, welche Entscheidungen Sie selbst treffen können und welche von Gremien getroffen werden.
71	11	anwenden	You are able to prepare or make decisions for your relevant scopes and document them accordingly. You can apply decision support methods, such as utility analysis.	Sie sind in der Lage, Entscheidungen für Ihre relevanten Bereiche vorzubereiten oder selbst zu treffen und diese entsprechend zu dokumentieren. Sie können Methoden der Entscheidungsunterstützung, wie z.B. Nutzwertanalyse, anwenden.
72	11	beherrschen	You can evaluate decisions and are able to define and establish overarching decision-making bodies. You can define good guidelines for making decisions.	Sie können Entscheidungen bewerten und sind in der Lage, übergreifende Entscheidungsgremien zu definieren und zu etablieren. Sie können gute Richtlinien für das Treffen von Entscheidungen definieren.
73	12	kennen	You are aware of the benefits of established information and knowledge management.	Sie kennen die Vorteile eines etablierten Informations- und Wissensmanagements.
74	12	verstehen	You understand the key platforms for knowledge transfer and know which information needs to be shared with whom.	Sie verstehen die wesentlichen Plattformen für den Wissen-Transfer und wissen, welche Informationen an wen weitergegeben werden müssen.
75	12	anwenden	You are able to define storage structures and documentation guidelines for projects, and can provide relevant information at the right place.	Sie sind in der Lage, Ablagestrukturen und Dokumentationsrichtlinien für Projekte zu definieren und können die relevanten Informationen an der entsprechenden Stelle zur Verfügung stellen.
76	12	beherrschen	You can define a comprehensive information management process.	Sie können einen umfangreichen Informationsmanagementprozess definieren.
77	13	kennen	You are aware of the necessity of configuration management.	Sie verstehen die Notwendigkeit des Konfigurationsmanagements.
78	13	kennen	You know which tools are used to create configurations.	Sie wissen, in welchen Werkzeugen Konfigurationen zu bilden sind.
79	13	verstehen	You understand the process of defining configuration items and can identify those relevant to you.	Sie verstehen das Vorgehen zur Festlegung von Konfigurationsitems und können die für Sie relevanten erkennen.
80	13	verstehen	You are able to use the tools necessary to create configurations for your scopes.	Sie sind in der Lage, in den entsprechenden Werkzeugen Konfigurationen für Ihre Bereiche zu bilden.
81	13	anwenden	You can define sensible configuration items and recognize those relevant to you.	Sie können sinnvolle Konfigurationsitems definieren und die für Sie relevanten erkennen.
82	13	anwenden	You are capable of using tools to define configuration items and create configurations for your scopes.	Sie sind fähig, in den Werkzeugen Konfigurationsitems zu definieren und für Ihre Bereiche eine Konfiguration zu bilden.
83	13	beherrschen	You are able to recognize all relevant configuration items and create a comprehensive configuration across all items.	Sie sind fähig, alle relevanten Konfigurationsitems zu erkennen und eine integre Konfiguration über alle Konfigurationsitems zu bilden.
84	13	beherrschen	You can identify improvements, propose solutions, and assist others in configuration management.	Sie können Verbesserungen identifizieren, Lösungsvorschläge herausarbeiten und andere bei der Bildung von Konfigurationen unterstützen.
85	17	beherrschen	You are able to define organizational processes for operation, maintenance, and servicing.	Sie sind in der Lage, die Organisationsprozesse für den Betrieb, die Wartung und die Instandhaltung zu definieren.
\.


--
-- Data for Name: competency_indicators_backup01112024; Type: TABLE DATA; Schema: public; Owner: adminderik
--

COPY public.competency_indicators_backup01112024 (id, competency_id, level, indicator) FROM stdin;
6	1	Awareness	Explains what “systems thinking” is and explains why it is important. 
8	1	Awareness	Explains what “emergence” is, why it is important, and how it can be “positive” or “negative”in its effect upon the system as a whole.
9	1	Awareness	Explains what a “system hierarchy” is and why it is important.
10	1	Awareness	Explains what “system context”is for a given system of interest and describes why it is important.
11	1	Awareness	Explains why it is important to be able to identify and understand what interfaces are.
12	1	Awareness	Explains why it is important to recognise interactions among systems and their elements.
13	1	Awareness	Explains why it is important to understand purpose and functionality of a system of interest.
14	1	Awareness	Explains how business, enterprise, and technology can each influence the definition and development of the system and vice versa. 
15	1	Awareness	Explains why it may be necessary to approach systems thinking in different ways, depending on the situation, and provides examples.
16	1	Supervised Practitioner	Defines the properties of a system.
17	1	Supervised Practitioner	Explains how system behavior produces emergent properties.
18	1	Supervised Practitioner	Uses the principles of system partitioning within system hierarchy on a project.
19	1	Supervised Practitioner	Defines system characteristics in order to improve understanding of need.
20	1	Supervised Practitioner	Explains why the boundary of a system needs to be managed.
21	1	Supervised Practitioner	Explains how humans and systems interact and how humans can be elements of systems.
22	1	Supervised Practitioner	Identifies the influence of wider enterprise on a project.
23	1	Supervised Practitioner	Uses systems thinking to contribute to enterprise technology development activities.
24	1	Supervised Practitioner	Develops their own systems thinking insights to share thinking across the wider project(e.g. working groups and other teams).
26	1	Practitioner	Identifies and manages complexity using appropriate techniques. 
27	1	Practitioner	Uses analysis of a system functions and parts to predict resultant system behavior.
28	1	Practitioner	Identifies the context of a system from a range of view points including system boundaries and external interfaces. 
29	1	Practitioner	Identifies the interaction between humans and systems, and systems and systems.
30	1	Practitioner	Identifies enterprise and technology issues affecting the design of a system and addresses them using a systems thinking approach.
31	1	Practitioner	Uses appropriate systems thinking approaches to a range of situations, integrating the outcomes to get a full understanding of the whole.
32	1	Practitioner	Identifies potential enterprise improvements to enable system development.
33	1	Practitioner	Guides team systems thinking activities in order to ensure current activities align to purpose.
34	1	Practitioner	Develops existing case studies and examples of systems thinking to apply in new situations.
35	1	Practitioner	Guides new or supervised practitioners in systems thinking techniques in order to develop their knowledge, abilities, skills, or associated behaviors.
37	1	Lead Practitioner	Creates enterprise-level policies, procedures, guidance, and best practice for systems thinking, including associated tools.
38	1	Lead Practitioner	Judges the suitability of project-level systems thinking on behalf of the enterprise, to ensure its validity.
39	1	Lead Practitioner	Persuades key enterprise-level stakeholders across the enterprise to support and maintain the technical capability and strategy of the enterprise.
40	1	Lead Practitioner	Adapts existing systems thinking practices on behalf of the enterprise to accommodate novel, complex, or difficult system situations or problems. 
41	1	Lead Practitioner	Persuades project stakeholders across the enterprise to improve the suitability of project technical strategies in order to maintain their validity.
42	1	Lead Practitioner	Persuades key stakeholders to address enterprise-level issues identified through systems thinking.
43	1	Lead Practitioner	Coaches or mentors practitioners across the enterprise in systems thinking in order to develop their knowledge, abilities, skills, or associated behaviors.
46	1	Expert	Communicates own knowledge and experience in systems thinking in order to improve best practice beyond the enterprise boundary.
47	1	Expert	Influences individuals and activities beyond the enterprise boundary to support the systems thinking approach of their own enterprise.
48	1	Expert	Advises organizations beyond the enterprise boundary on the suitability of their approach to systems thinking.
49	1	Expert	Advises organizations beyond the enterprise boundary on complex or sensitive systems thinking issues.
50	1	Expert	Champions the introduction of novel techniques and ideas in systems thinking beyond the enterprise boundary, in order to develop the wider Systems Engineering community in this competency.
51	1	Expert	Coaches individuals beyond the enterprise boundary in systems thinking techniques, in order to further develop their knowledge, abilities, skills, or associated behaviors.
53	6	Awareness	Explains why system representations are required and the benefits they can bring to developments.
54	6	Awareness	Explains the scope and limitations of models and simulations, including definition, implementation, and analysis.
55	6	Awareness	Explains different types of modeling and simulation approaches.
56	6	Awareness	Explains how the purpose of modeling and simulation affect the approach taken.
57	6	Awareness	Explains why functional analysis and modeling is important in Systems Engineering.
58	6	Awareness	Explains the relevance of outputs from systems modeling and analysis, and how these relate to overall system development. 
59	6	Awareness	Explains the difference between modeling and simulation.
60	6	Awareness	Describes a variety of system analysis techniques that can be used to derive information about a system.
61	6	Awareness	Explains why the benefits of modeling can only be realized if choices made in defining the model are correct.
62	6	Awareness	Explains why models and simulations have a limit of valid use, and the risks of using models and simulations outside those limits.
63	6	Supervised Practitioner	Uses modeling and simulation tools and techniques to represent a system or system element.
64	6	Supervised Practitioner	Analyzes outcomes of modeling and analysis and uses this to improve understanding of a system.
65	6	Supervised Practitioner	Analyzes risks or limits of a model or simulation.
66	6	Supervised Practitioner	Uses systems modeling and analysis tools and techniques to verify a model or simulation.
67	6	Supervised Practitioner	Prepares inputs used in support of model development activities.
68	6	Supervised Practitioner	Uses different types of models for different reasons. 
69	6	Supervised Practitioner	Uses system analysis techniques to derive information about the real system. 
71	6	Practitioner	Identifies project-specific modeling or analysis needs that need to be addressed when performing modeling on a project.
72	6	Practitioner	Creates a governing process, plan, and associated tools for systems modeling and analysis in order to monitor and control systems modeling and analysis activities on a system or system element. 
73	6	Practitioner	Determines key parameters or constraints, which scope or limit the modeling and analysis activities.
74	6	Practitioner	Uses a governing process and appropriate tools to manage and control their own system modeling and analysis activities. 
75	6	Practitioner	Analyzes a system, determining the representation of the system or system element, collaborating with model stakeholders as required.
79	6	Lead Practitioner	Creates enterprise-level policies, procedures, guidance, and best practice for systems modeling and analysis definition and management, including associated tools. 
80	6	Practitioner	Selects appropriate tools and techniques for system modeling and analysis.
81	6	Practitioner	Defines appropriate representations of a system or system element.
82	6	Practitioner	Uses appropriate representations and analysis techniques to derive information about a real system.
83	6	Practitioner	Ensures the content of models that are produced within a project are controlled and coordinated.
84	6	Practitioner	Uses systems modeling and analysis tools and techniques to validate a model or simulation. 
85	6	Practitioner	Guides new or supervised practitioners in modeling and systems analysis to operation in order to develop their knowledge, abilities, skills, or associated behaviors. 
87	6	Lead Practitioner	Judges the correctness of tailoring of enterprise-level modeling and analysis processes to meet the needs of a project, on behalf of the enterprise.
88	6	Lead Practitioner	Advises stakeholders across the enterprise, on systems modeling and analysis. 
89	6	Lead Practitioner	Coordinates modeling or analysis activities across the enterprise in order to determine appropriate representations or analysis of complex system or system elements. 
90	6	Lead Practitioner	Adapts approaches used to accommodate complex or challenging aspects of a system of interest being modeled or analyze on projects across the enterprise. 
91	6	Lead Practitioner	Assesses the outputs of systems modeling and analysis across the enterprise to ensure that the results can be used for the intended purpose. 
92	6	Lead Practitioner	Advises stakeholders across the enterprise on selection of appropriate modeling or analysis approach across the enterprise.
93	6	Lead Practitioner	Coordinates the integration and combination of different models and analyses for a system or system element across the enterprise.
94	6	Lead Practitioner	Coaches or mentors practitioners across the enterprise in systems modeling and analysis in order to develop their knowledge, abilities, skills, or associated behaviors.
95	6	Lead Practitioner	Promotes the introduction and use of novel techniques and ideas in Systems Modeling and Analysis across the enterprise, to improve enterprise competence in this area.
97	6	Expert	Communicates own knowledge and experience in Systems Modeling and Analysis in order to improve best practice beyond the enterprise boundary. 
98	6	Expert	Advises organizations beyond the enterprise on the appropriateness of their selected approaches in any given level of complexity and novelty. 
99	6	Expert	Advises organizations beyond the enterprise boundary on the modeling and analysis of complex or novel systems, or system elements.
100	6	Expert	Advises organizations beyond the enterprise boundary on the model or analysis validation issues and risks.
101	6	Expert	Advises organizations beyond the enterprise boundary on the suitability of their approach to systems modeling and analysis.
102	6	Expert	Advises organizations beyond the enterprise boundary on complex or sensitive systems modeling and analysis issues. 
103	6	Expert	Champions the introduction of novel techniques and ideas in systems modeling and analysis, beyond the enterprise boundary, in order to develop the wider Systems Engineering community in this competency. 
104	6	Expert	Coaches individuals beyond the enterprise boundary in systems modeling and analysis, in order to further develop their knowledge, abilities, skills, or associated behaviors. 
106	1	Awareness	Explains the concept of capability and how its use can prove beneficial.
107	1	Awareness	Explains how capability requirements can be satisfied by integrating several systems.
108	1	Awareness	Explains how super system capability needs impact on the development of each system that contributes to the capability.
109	1	Awareness	Describes the difficulties of translating capability needs of the wider system into system requirements.
112	1	Supervised Practitioner	Explains how project capability and environment are linked.
113	1	Supervised Practitioner	Identifies capability issues from the wider system, which will affect the design of a system of interest.
114	1	Supervised Practitioner	Prepares inputs to technology planning activities required in order to provide capability.
115	1	Supervised Practitioner	Prepares information that supports the embedding or utilization of capability.
116	1	Supervised Practitioner	Identifies different elements that make up capability. 
122	1	Practitioner	Identifies capability issues of the wider (super) system which will affect the design of own system and translates these into system requirements.
123	1	Practitioner	Reviews proposed system solutions to ensure their ability to deliver the capability required by a wider system, making changes as necessary. 
124	1	Practitioner	Prepares technology plan that includes technology innovation, risk, maturity, readiness levels, and insertion points into existing capability.
125	1	Practitioner	Creates an operational concept for a capability (what it does, why, how, where, when, and who).
126	1	Practitioner	Reviews existing capability to identify gaps relative to desired capability, documenting approaches which reduce or eliminate this deficit. 
127	1	Practitioner	Prepares information that supports improvements to enterprise capabilities.
128	1	Practitioner	Identifies key “pinch points” in the development and implementation of specific capability.
129	1	Practitioner	Uses multiple views to analyze alignment, balance, and trade-offs in and between the different elements (in a level) ensuring that capability performance is not traded out.
130	1	Practitioner	Guides new or supervised practitioners in Capability engineering in order to develop their knowledge, abilities, skills, or associated behaviors. 
132	1	Supervised Practitioner	Prepares multiple views that focus on value, purpose, and solution for capability.
134	1	Lead Practitioner	Creates enterprise-level policies, procedures, guidance, and best practice for capability engineering, including associated tools.
135	1	Lead Practitioner	Judges the suitability of capability solutions and the planned approach on projects across the enterprise. 
136	1	Lead Practitioner	Identifies impact and changes needed in super system environment as a result of the capability development on behalf of the enterprise. 
137	1	Lead Practitioner	Identifies improvements required to enterprise capabilities on behalf of the enterprise. 
138	1	Lead Practitioner	Coaches or mentors practitioners across the enterprise in capability engineering in order to develop their knowledge, abilities, skills, or associated behaviors. 
139	1	Lead Practitioner	Promotes the introduction and use of novel techniques and ideas in Capability Engineering across the enterprise, to improve enterprise competence in the area.
141	1	Expert	Communicates own knowledge and experience in capability engineering in order to improve best practice beyond the enterprise boundary. 
142	1	Expert	Advises organizations beyond the enterprise boundary on the suitability of their approach to capability engineering. 
143	1	Expert	Advises organizations beyond the enterprise boundary on their handling of complex or sensitive capability engineering strategy issues.
144	1	Expert	Advises organizations beyond the enterprise boundary on differences and relationships between capability and product-based systems. 
145	1	Expert	Assesses capability engineering in multiple domains beyond the enterprise boundary in order to develop or improve capability solutions within own enterprise. 
146	1	Expert	Champions the introduction of novel techniques and ideas in capability engineering, beyond the enterprise boundary, in order to develop the wider Systems Engineering community in this competency. 
147	1	Expert	Coaches individuals beyond the enterprise boundary in capability engineering, in order to further develop their knowledge, abilities, skills, or associated behaviors. 
149	14	Awareness	Describes what a requirement is, the purpose of requirements, and why requirements are important.
150	14	Awareness	Describes different types of requirements and constraints that may be placed on a system.
151	14	Awareness	Explains why there is a need for good quality requirements.
152	14	Awareness	Identifies major stakeholders and their needs.
153	14	Awareness	Explains why managing requirements throughout the life cycle is important. 
154	14	Awareness	Describes the relationship between requirements, testing, and acceptance. 
155	14	Supervised Practitioner	Uses a governing process using appropriate tools to manage and control their own requirements definition activities. 
156	14	Supervised Practitioner	Identifies examples of internal and external project stakeholders highlighting their sphere of influence.
157	14	Supervised Practitioner	Elicits requirements from stakeholders under guidance, in order to understand their need and ensuring requirement validity. 
158	14	Supervised Practitioner	Describes the characteristics of good quality requirements and provides examples. 
159	14	Supervised Practitioner	Describes different mechanisms used to gather requirements.
160	14	Supervised Practitioner	Defines acceptance criteria for requirements, under guidance.
161	14	Supervised Practitioner	Explains why there may be potential requirement conflicts within a requirement set.
162	14	Supervised Practitioner	Explains how requirements affect design and vice versa. 
164	14	Supervised Practitioner	Defines (or maintains) requirements traceability information.
165	14	Supervised Practitioner	Reviews developed requirements.
167	14	Practitioner	Creates a strategy for requirements definition on a project to support SE project and wider enterprise needs.
168	14	Practitioner	Creates a governing process, plan, and associated tools for Requirements Definition, which reflect project and business strategy.
169	14	Practitioner	Uses plans and processes for requirements definition, interpreting, evolving, or seeking guidance where appropriate.
170	14	Practitioner	Elicits requirements from stakeholders ensuring their validity, to understand their need.
171	14	Practitioner	Develops good quality, consistent requirements. 
172	14	Practitioner	Determines derived requirements.
173	14	Practitioner	Creates a system to support requirements management and traceability.
174	14	Practitioner	Determines acceptance criteria for requirements.
175	14	Practitioner	Negotiates agreement in requirement conflicts within a requirement set. 
176	14	Practitioner	Analyzes the impact of changes to requirements on the solution and program. 
177	14	Practitioner	Maintains requirements traceability information to ensure source(s) and test records are correctly linked over the life cycle. 
178	14	Practitioner	Guides new or supervised practitioners in Systems Engineering Requirements Definition to develop their knowledge, abilities, skills, or associated behaviors. 
180	14	Lead Practitioner	Creates enterprise-level policies, procedures, guidance, and best practice for requirements elicitation and management, including associated tools.
181	14	Lead Practitioner	Judges the tailoring of enterprise- level requirements elicitation and management processes to meet the needs of a project. 
182	14	Lead Practitioner	Advises on complex or challenging requirements from across the enterprise to ensure completeness and suitability.
183	14	Lead Practitioner	Defines strategies for requirements resolution in situations across the enterprise where stakeholders (or their requirements) demand unusual or sensitive treatment. 
184	14	Lead Practitioner	Persuades key stakeholders across the enterprise to address identified enterprise-level requirements elicitation and management issues to reduce enterprise-level risk. 
185	14	Lead Practitioner	Coaches or mentors practitioners across the enterprise in Systems Engineering Requirements Definition in order to develop their knowledge, abilities, skills, or associated behaviors.
188	14	Expert	Communicates own knowledge and experience in Systems Engineering requirements definition in order to promote best practice beyond the enterprise boundary. 
189	14	Expert	Persuades key stakeholders beyond the enterprise boundary to address identified requirements definition issues to reduce project risk. 
190	14	Expert	Advises organizations beyond the enterprise boundary on the suitability of their approach to requirements definition.
191	14	Expert	Advises organizations beyond the enterprise boundary on the handling of complex or sensitive Systems Engineering requirements definition issues.
193	14	Expert	Coaches individuals beyond the enterprise boundary, in requirements definition in order to further develop their knowledge, abilities, skills, or associated behaviors. 
195	15	Awareness	Describes the principles of architectural design and its role within the life cycle.
196	15	Awareness	Describes different types of architecture and provides examples.
197	15	Awareness	Explains why architectural decisions can constrain and limit future use and evolution and provides examples.
198	15	Awareness	Explains why there is a need to explore alternative and innovative ways of satisfying the requirements.
199	15	Awareness	Explains why alternative discipline technologies can be used to satisfy the same requirement and provides examples.
200	15	Awareness	Describes the process and key artifacts of functional analysis.
201	15	Awareness	Explains why there is a need for functional models of the system.
202	15	Awareness	Explains how outputs from functional analysis relate to the overall system design and provides examples.
203	15	Supervised Practitioner	Uses a governing process using appropriate tools to manage and control their own system architectural design activities.
204	15	Supervised Practitioner	Uses analysis techniques or principles used to support an architectural design process.
205	15	Supervised Practitioner	Develops multiple different architectural solutions (or parts thereof) meeting the same set of requirements to highlight different options available.
206	15	Supervised Practitioner	Produces traceability information linking differing architectural design solutions to requirements.
207	15	Supervised Practitioner	Uses different techniques to develop architectural solutions.
208	15	Supervised Practitioner	Compares the characteristics of different concepts to determine their strengths and weaknesses.
209	15	Supervised Practitioner	Prepares a functional analysis using appropriate tools and techniques to characterize a system.
210	15	Supervised Practitioner	Prepares architectural design work products (or parts thereof) traceable to the requirements.
212	15	Practitioner	Creates a strategy for system architecting on a project to support SE project and wider enterprise needs.
213	15	Practitioner	Creates a governing process, plan, and associated tools for systems architecting, which reflect project and business strategy.
214	15	Practitioner	Uses plans and processes for system architecting, interpreting, evolving, or seeking guidance where appropriate.
215	15	Practitioner	Creates alternative architectural designs traceable to the requirements to demonstrate different approaches to the solution. 
216	15	Practitioner	Analyzes options and concepts in order to demonstrate that credible, feasible options exist. 
217	15	Practitioner	Uses appropriate analysis techniques to ensure different viewpoints are considered.
218	15	Practitioner	Elicits derived discipline specific architectural constraints from specialists to support partitioning and decomposition.
219	15	Practitioner	Uses the results of system analysis activities to inform system architectural design.
220	15	Practitioner	Identifies the strengths and weaknesses of relevant technologies in the context of the requirement and provides examples.
221	15	Practitioner	Monitors key aspects of the evolving design solution in order to adjust architecture, if appropriate.
222	15	Practitioner	Guides new or supervised practitioners in Systems Architecting to develop their knowledge, abilities, skills, or associated behaviors.
224	15	Lead Practitioner	Creates enterprise-level policies, procedures, guidance, and best practice for system architectural design including associated tools.
225	15	Lead Practitioner	Assesses the tailoring of enterprise- level system architectural design processes to meet the needs of a project. 
226	15	Lead Practitioner	Advises stakeholders across the enterprise on selection of architectural design and functional analysis techniques to ensure effectiveness and efficiency of approach.
227	15	Lead Practitioner	Judges the suitability of architectural solutions across the enterprise in areas of complex or challenging technical requirements or needs. 
228	15	Lead Practitioner	Assesses system architectures across the enterprise, to determine whether they meet the overall needs of individual projects.
229	15	Lead Practitioner	Persuades key stakeholders across the enterprise to address identified enterprise-level Systems Engineering architectural design issues to reduce project cost, schedule, or technical risk.
230	15	Lead Practitioner	Coaches or mentors practitioners across the enterprise in Systems Architecting in order to develop their knowledge, abilities, skills, or associated behaviors.
233	15	Expert	Communicates own knowledge and experience in Systems Architecting in order to promote best practice beyond the enterprise boundary.
234	15	Expert	Persuades key stakeholders beyond the enterprise boundary in order to facilitate the system architectural design.
235	15	Expert	Advises organizations beyond the enterprise boundary on the suitability of their approach to system architectural design.
236	15	Expert	Advises organizations beyond the enterprise boundary on improving their handling of complex or sensitive Systems Architecting issues. 
237	15	Expert	Advises organizations beyond the enterprise boundary on improving their concept generation activities.
239	15	Expert	Coaches individuals beyond the enterprise boundary in Systems Architecting, in order to further develop their knowledge, abilities, skills, or associated behaviors.
241	10	Awareness	Explains the role the project management function plays in developing a successful system product or service.
242	10	Awareness	Explains the meaning of commonly used project management terms and applicable standards.
243	10	Awareness	Explains the relationship between cost, schedule, quality, and performance and why this matters. 
244	10	Awareness	Describes the role and typical responsibilities of a project manager on a project team, within the wider project management function.
245	10	Awareness	Describes the differences between performing project management and Systems Engineering management on that project.
246	10	Awareness	Describes the key interfaces between project management stakeholders within the enterprise and the project team.
247	10	Awareness	Describes the wider program environment within which the system is being developed, and the influence each can have on this other. 
248	10	Supervised Practitioner	Follows a governing process in order to interface successfully to project management activities.
249	10	Supervised Practitioner	Prepares inputs to work products which interface to project management stakeholders to ensure Systems Engineering work aligns with wider project management activities.
250	10	Supervised Practitioner	Identifies potential issues with interfacing work products received from project management Stakeholders or produced by Systems Engineering for project management stakeholders taking appropriate action.
251	10	Supervised Practitioner	Prepares Systems Engineering information for project management in support of wider project initiation activities.
252	10	Supervised Practitioner	Prepares Systems Engineering Work Breakdown Structure (WBS) information for project management in support of their creation of a wider project WBS.
253	10	Supervised Practitioner	Prepares Systems Engineering Work Package definitions and estimating information for project management in support of their work creating project-level Work Packages and estimates. 
254	10	Supervised Practitioner	Follows a governing process in order to interface successfully to project management activities.
255	10	Supervised Practitioner	Prepares information used in project management contract reviews for project management on a project. 
256	10	Supervised Practitioner	Prepares Systems Engineering information for project management in support of wider project termination activities.
259	10	Practitioner	Identifies Systems Engineering tasks ensuring that these tasks integrate successfully with project management activities. 
262	10	Practitioner	Develops Systems Engineering inputs for project management status reviews to enable informed decision-making.
265	10	Practitioner	Creates working groups extending beyond Systems Engineering.
271	10	Lead Practitioner	Assesses project management information produced across the enterprise using appropriate techniques for its integration with Systems Engineering data.
274	10	Lead Practitioner	Guides and actively coordinates complex or challenging relationships with key stakeholders affecting Systems Engineering. 
277	10	Lead Practitioner	Promotes the introduction and use of novel techniques and ideas across the enterprise, which improve the integration of Systems Engineering and project management functions. 
282	10	Expert	Advises organizations beyond the enterprise boundary on the suitability of their approach to project management plans affecting Systems Engineering activities.
286	11	Awareness	Identifies the Systems Engineering situations where a structured decision is, and is not, appropriate.
289	11	Awareness	Explains how to frame, tailor, and structure a decision including its objectives and measures and outlines the key characteristics of a structured decision-making approach. 
292	11	Supervised Practitioner	Follows a governing process and appropriate tools to plan and control their own decision management activities.
295	11	Supervised Practitioner	Prepares information in support of decision trade studies.
260	10	Practitioner	Identifies activities required to ensure integration of project management planning and estimating with Systems Engineering planning and estimating. 
263	10	Practitioner	Develops project initiation information required to support Project Start-up by project management on a project.
266	10	Practitioner	Guides new or supervised practitioners in finance and its relationship to Systems Engineering, to develop their knowledge, abilities, skills, or associated behaviors.
269	10	Lead Practitioner	Creates enterprise-level policies, procedures, guidance, and best practice in order to ensure Systems Engineering project management activities integrate with enterprise-level Project Management goals.
272	10	Lead Practitioner	Judges appropriateness of enterprise-level project management decisions in a rational way to ensure alignment with Systems Engineering needs.
275	10	Lead Practitioner	Persuades key project management stakeholders to address identified enterprise-level project management issues affecting Systems Engineering. 
287	11	Awareness	Explains why there is a need to select a preferred solution.
290	11	Awareness	Explains how uncertainty impacts on decision-making.
293	11	Supervised Practitioner	Identifies potential decision criteria and performance parameters for consideration.
296	11	Supervised Practitioner	Monitors the decision process to catalog actions taken and their supporting rationale.
258	10	Practitioner	Follows governing project management plans and processes, and uses appropriate tools to control and monitor project management-related Systems Engineering tasks, interpreting as necessary. 
261	10	Practitioner	Develops inputs to a project management plan for a complete project beyond those required for Systems Engineering planning to support wider project or business project management. 
264	10	Practitioner	Develops Systems Engineering information required to support termination of a project by senior management. 
270	10	Lead Practitioner	Assesses enterprise-level project management processes and tailoring to ensure they integrate with Systems Engineering needs.
273	10	Lead Practitioner	Judges conflicts between project management needs and Systems Engineering needs on behalf of the enterprise, arbitrating as required. 
276	10	Lead Practitioner	Coaches or mentors practitioners across the enterprise in the integration of project management with Systems Engineering, in order to develop their knowledge, abilities, skills, or associated behaviors. 
279	10	Expert	Communicates own knowledge and experience in the integration of project management with Systems Engineering, in order to improve Systems Engineering best practice beyond the enterprise boundary.
281	10	Expert	Advises organizations beyond the enterprise boundary on complex or sensitive project management- related issues affecting Systems Engineering. 
284	10	Expert	Coaches individuals beyond the enterprise boundary, in the relationship between Systems Engineering and project management, to further develop their knowledge, abilities, skills, or associated behaviors. 
288	11	Awareness	Describes the relevance of comparative techniques (e.g. trade studies, and make/buy) to assist decision processes.
291	11	Awareness	Explains why there is a need for communication and accurate recording in all aspects of the decision-making process.
294	11	Supervised Practitioner	Identifies tools and techniques for the decision process.
298	11	Practitioner	Creates a strategy for decision management on a project to support SE project and wider enterprise needs.
299	11	Practitioner	Creates a governing process, plan, and associated tools for systems decision management, which reflect project and business strategy. 
300	11	Practitioner	Complies with governing plans and processes for system decision management, interpreting, evolving, or seeking guidance where appropriate. 
301	11	Practitioner	Develops governing decision management plans, processes, and appropriate tools and uses these to control and monitor decision management activities.
302	11	Practitioner	Guides and actively coordinates ongoing decision management activities to ensure successful outcomes with decision management stakeholders.
303	11	Practitioner	Determines decision selection criteria, weightings of the criteria, and assess alternatives against selection criteria. 
304	11	Practitioner	Selects appropriate tools and techniques for making different types of decision.
305	11	Practitioner	Prepares trade-off analyses and justifies the selection in terms that can be quantified and qualified.
306	11	Practitioner	Assesses sensitivity of selection criteria through a sensitivity analysis, reporting as required.
307	11	Practitioner	Guides new or supervised practitioners in Decision management techniques in order to develop their knowledge, abilities, skills, or associated behaviors.
309	11	Lead Practitioner	Creates enterprise-level policies, procedures, guidance, and best practice for decision management and communication, including associated tools.
310	11	Lead Practitioner	Judges the tailoring of enterprise- level decision management processes and associated work products to meet the needs of a project. 
311	11	Lead Practitioner	Coordinates decision management and trade analysis using different techniques, across multiple diverse projects or across a complex system, with proven success.
312	11	Lead Practitioner	Persuades key stakeholders across the enterprise to address identified enterprise-level decision management issues.
313	11	Lead Practitioner	Negotiates complex trades on behalf of the enterprise.
314	11	Lead Practitioner	Judges decisions affecting solutions and the criteria for making the solution across the enterprise. 
315	11	Lead Practitioner	Coaches or mentors practitioners across the enterprise in Systems Engineering decision management in order to develop their knowledge, abilities, skills, or associated behaviors. 
318	11	Expert	Communicates own knowledge and experience in Systems Engineering decision management, in order to improve best practice beyond the enterprise boundary. 
319	11	Expert	Influences key decision stakeholders beyond the enterprise boundary.
320	11	Expert	Advises organizations beyond the enterprise boundary on complex or sensitive decision management or trade-off issues. 
321	11	Expert	Advises organizations beyond the enterprise boundary on the suitability of their approach to decision management.
322	11	Expert	Identifies strategies for organizations beyond the enterprise boundary, in order to resolve their issues with complex system trade-offs.
324	11	Expert	Coaches individuals beyond the enterprise boundary in Systems Engineering decision management, in order to further develop their knowledge, abilities, skills, or associated behaviors. 
326	12	Awareness	Describes various types of information required to be managed in support of Systems Engineering activities and provides examples.
327	12	Awareness	Describes various types of information assets that may need to be managed within a project or system. 
330	12	Awareness	Describes potential scenarios where information may require modification. 
333	12	Awareness	Describes what constitutes personal data and why its protection and management is important. 
336	12	Supervised Practitioner	Identifies valid sources of information and associated authorities on a project.
339	12	Supervised Practitioner	Identifies designated information requiring archiving in compliance with the requirements on a project.
342	12	Supervised Practitioner	Prepares inputs to plans and work products addressing information management and its communication.
345	12	Practitioner	Creates a strategy for Information Management on a project to support SE project and wider enterprise needs. 
348	12	Practitioner	Identifies valid sources of information and designated authorities and responsibilities for the information.
351	12	Practitioner	Selects information archival requirements reflecting legal, audit, knowledge retention, and project closure obligations.
354	12	Practitioner	Selects and implements information management solutions consistent with project security and privacy requirements, data rights, and information management standards.
358	12	Practitioner	Follows security, data management, privacy standards, and regulations applicable to the project.
328	12	Awareness	Identifies different classes of risk to information integrity and can provide examples of each.
331	12	Awareness	Explains how data rights may affect information management on a project.
334	12	Supervised Practitioner	Follows a governing process and appropriate tools to plan and control information management activities.
337	12	Supervised Practitioner	Maintains information in accordance with integrity, security, privacy requirements, and data rights.
340	12	Supervised Practitioner	Identifies information requiring disposal such as unwanted, invalid, or unverifiable information in accordance with requirements on a project.
343	12	Supervised Practitioner	Records lessons learned and shares beyond the project boundary. 
346	12	Practitioner	Creates governing plans, processes, and appropriate tools and uses these to control and monitor information management and associated communications activities. 
349	12	Practitioner	Maintains information artifacts in accordance with integrity, security, privacy requirements, and data rights.
352	12	Practitioner	Prepares managed information in support of organizational configuration management and knowledge management requirements (e.g. sharing lessons learned). 
355	12	Practitioner	Guides new or supervised practitioners in Information Management to develop their knowledge, abilities, skills, or associated behaviors. 
329	12	Awareness	Describes the relationship between information management and configuration change management.
332	12	Awareness	Describes the legal and ethical responsibilities associated with access to and sharing of enterprise and customer information and summarizes regulations regarding information sharing. 
335	12	Supervised Practitioner	Prepares inputs to a data dictionary and technical data library.
338	12	Supervised Practitioner	Identifies information or approaches which requires replanning in order to implement engineering changes on a project.
341	12	Supervised Practitioner	Prepares information management data products to support management reporting at organizational level.
347	12	Practitioner	Maintains a data dictionary, technical data library appropriate to the project. 
350	12	Practitioner	Determines formats and media for capture, retention, transmission, and retrieval of information, and data requirements for the sharing of information.
359	12	Lead Practitioner	Creates enterprise-level policies, procedures, guidance, and best practice for information management, including associated tools. 
360	12	Lead Practitioner	Judges the tailoring of enterprise- level information management processes and associated work products to meet the needs of a project. 
361	12	Lead Practitioner	Coordinates information management across multiple diverse projects or across a complex system, with proven success. 
362	12	Lead Practitioner	Advises on appropriate information management solutions to be used on projects across the enterprise.
363	12	Lead Practitioner	Influences key stakeholders to address identified enterprise-level information management issues.
364	12	Lead Practitioner	Communicates Systems Engineering lessons learned gathered from projects across the enterprise.
365	12	Lead Practitioner	Coaches or mentors practitioners across the enterprise in information management in order to develop their knowledge, abilities, skills, or associated behaviors. 
366	12	Lead Practitioner	Promotes the introduction and use of novel techniques and ideas in Information Management, across the enterprise, to improve enterprise competence in this area.
368	12	Expert	Communicates own knowledge and experience in information management, in order to best practice beyond the enterprise boundary. 
369	12	Expert	Influences individuals beyond the enterprise boundary to adopt appropriate information management techniques or approaches. 
371	12	Expert	Advises organizations beyond the enterprise boundary on complex or sensitive information management issues recommending appropriate solutions. 
372	12	Expert	Advises organizations beyond the enterprise boundary on the suitability of their approach to information management.
373	12	Expert	Advises organizations beyond the enterprise boundary on security, data management, data rights, privacy standards, and regulations. 
375	12	Expert	Coaches individuals beyond the enterprise boundary in information management, in order to further develop their knowledge, abilities, skills, or associated behaviors. 
377	13	Awareness	Explains why the integrity of the design needs to be maintained and how configuration management supports this. 
378	13	Awareness	Describes the key characteristics of a configuration item (CI) including how configuration items are selected and controlled.
379	13	Awareness	Identifies key baselines and baseline reviews in a typical development life cycle.
380	13	Awareness	Describes the process for changing baselined information and a typical life cycle for an engineering change.
381	13	Awareness	Lists key activities performed as part of configuration management and can outline the key activities involved in each. 
382	13	Awareness	Explains why change occurs and why changes need to be carefully managed. 
383	13	Awareness	Describes the processes and work products used to assist in Change Management.
384	13	Awareness	Describes the meaning of key terminology and acronyms used within Change Management and their relationships.
385	13	Supervised Practitioner	Follows a governing configuration and change management process and appropriate tools to plan and control their own activities relating to maintaining design integrity. 
386	13	Supervised Practitioner	Prepares information for configuration management work products.
387	13	Supervised Practitioner	Describes the need to identify configuration items and why this is done.
388	13	Supervised Practitioner	Prepares information in support of configuration change control activities. 
389	13	Supervised Practitioner	Prepares material in support of change control decisions and associated review meetings.
390	13	Supervised Practitioner	Produces management reports in support of configuration item status accounting and audits.
391	13	Supervised Practitioner	Identifies applicable standards, regulations, and enterprise level processes on their project.
392	13	Supervised Practitioner	Identifies and reports baseline inconsistencies. 
394	13	Practitioner	Creates a strategy for Configuration Management on a project to support SE project and wider enterprise needs. 
396	13	Practitioner	Creates governing configuration and change management plans, processes, and appropriate tools, and uses these to control and monitor design integrity during the full life cycle of a project or system.
397	13	Practitioner	Identifies required remedial actions in the presence of baseline inconsistencies. 
398	13	Practitioner	Coordinates changes to configuration items understanding the potential scope within the context of the project. 
399	13	Practitioner	Identifies selection of configuration items and associated documentation by working with design teams justifying the decisions reached.
400	13	Practitioner	Coordinates change control review activities in conjunction with customer representative and directs resolutions and action items.
402	13	Practitioner	Guides new or supervised practitioners in configuration management to develop their knowledge, abilities, skills, or associated behaviors.
404	13	Lead Practitioner	Creates enterprise-level policies, procedures, guidance, and best practice for configuration management, including associated tools.
406	13	Lead Practitioner	Coordinates configuration management across multiple diverse projects or across a complex system, with proven success. 
408	13	Lead Practitioner	Advises stakeholders across the enterprise on remedial actions to address baseline inconsistencies for projects of various size and complexity. 
410	13	Lead Practitioner	Coaches or mentors practitioners across the enterprise in configuration management in order to develop their knowledge, abilities, skills, or associated behaviors. 
414	13	Expert	Influences individuals beyond the enterprise boundary regarding configuration and change management issues. 
416	13	Expert	Advises organizations beyond the enterprise boundary on complex or sensitive configuration and change management issues.
418	13	Expert	Coaches individuals beyond the enterprise boundary in Configuration Management, in order to further develop their knowledge, abilities, skills, or associated behaviors. 
401	13	Practitioner	Coordinates configuration status accounting reports and audits.
405	13	Lead Practitioner	Judges the tailoring of enterprise- level configuration and change management processes and associated work products to meet the needs of a project. 
407	13	Lead Practitioner	Influences key stakeholders to address identified enterprise-level configuration management issues.
409	13	Lead Practitioner	Advises stakeholders across the enterprise on major changes and influences them to reduce impact of such changes. 
413	13	Expert	Communicates own knowledge and experience in configuration management in order to best practice beyond the enterprise boundary. 
415	13	Expert	Advises organizations beyond the enterprise boundary on the suitability of their approach to configuration management.
420	4	Awareness	Identifies different life cycle types and summarizes the key characteristics of each.
421	4	Awareness	Explains why selection of life cycle is important when developing a system solution.
422	4	Awareness	Explains why it is necessary to define an appropriate life cycle process model and the key steps involved.
423	4	Awareness	Explains why differing engineering approaches are required in different life cycle phases and provides examples.
424	4	Awareness	Explains how different life cycle characteristics relate to the system life cycle.
425	4	Supervised Practitioner	Describes Systems Engineering life cycle processes. 
426	4	Supervised Practitioner	Identifies the impact of failing to consider future life cycle stages in the current stage. 
427	4	Supervised Practitioner	Prepares inputs to life cycle definition activities at system or system element level.
428	4	Supervised Practitioner	Complies with a governing project system life cycle, using appropriate processes and tools to plan and control their own activities. 
429	4	Supervised Practitioner	Describes the system life cycle in which they are working on their project. 
431	4	Practitioner	Explains the advantages and disadvantages of different types of systems life cycle and where each might be used advantageously. 
432	4	Practitioner	Creates a governing project life cycle, using enterprise-level policies, procedures, guidance, and best practice. 
433	4	Practitioner	Identifies dependencies aligning life cycles and life cycle stages of different system elements accordingly. 
434	4	Practitioner	Acts to influence the life cycle of system elements beyond boundary of the system of interest, to improve the development strategy. 
435	4	Practitioner	Prepares plans addressing future life cycle phases to take into consideration their impact on the current phase, improving current activities accordingly. 
436	4	Practitioner	Prepares plans governing transitions between life cycle stages to reduce project impact at those transitions. 
437	4	Practitioner	Guides new or supervised practitioners in Systems Engineering life cycles in order to develop their knowledge, abilities, skills, or associated behaviors.
439	4	Lead Practitioner	Creates enterprise-level policies, procedures, guidance, and best practice for life cycle definition and management, including associated tools.
440	4	Lead Practitioner	Judges life cycle selections across the enterprise, to ensure they meet the needs of the project. 
441	4	Lead Practitioner	Adapts standard life cycle models on behalf of the enterprise, to address complex or difficult situations or to resolve conflicts between life cycles where required. 
442	4	Lead Practitioner	Identifies work or issues relevant to the current life cycle phase by applying knowledge of life cycles to projects across the enterprise.
443	4	Lead Practitioner	Persuades key stakeholders across the enterprise to support activities required now in order to address future life cycle stages.
444	4	Lead Practitioner	Coaches or mentors practitioners across the enterprise in life cycle definition and management in order to develop their knowledge, abilities, skills, or associated behaviors. 
445	4	Lead Practitioner	Promotes the introduction and use of novel techniques and ideas in life cycle definition and management across the enterprise, to improve enterprise competence in this area. 
447	4	Expert	Communicates own knowledge and experience in life cycle definition and management in order to improve best practice beyond the enterprise boundary. 
448	4	Expert	Advises organizations beyond the enterprise boundary on the suitability of life cycle tailoring or life cycle definitions. 
449	4	Expert	Advises organizations beyond the enterprise boundary on complex, concurrent, or sensitive projects.
450	4	Expert	Champions the introduction of novel techniques and ideas in life cycle management, beyond the enterprise boundary, in order to develop the wider Systems Engineering community in this competency. 
451	4	Expert	Coaches individuals beyond the enterprise boundary in life cycle management techniques, in order to further develop their knowledge, abilities, skills, or associated behaviors. 
534	7	Awareness	Explains communications in terms of the sender, the receiver, and the message and why these three parameters are central to the success of any team communication. 
535	7	Awareness	Explains why there is a need for clear and concise communications.
536	7	Awareness	Describes the role communications has in developing positive relationships.
537	7	Awareness	Explains why employing the appropriate means for communications is essential.
538	7	Awareness	Explains why openness and transparency in communications matters.
539	7	Awareness	Explains why systems engineers need to listen to stakeholders’ point of view. 
540	7	Supervised Practitioner	Follows guidance received (e.g. from mentors) when using communications skills to plan and control their own communications activities. 
541	7	Supervised Practitioner	Uses appropriate communications techniques to ensure a shared understanding of information with peers.
542	7	Supervised Practitioner	Fosters positive relationships through effective communications.
543	7	Supervised Practitioner	Uses appropriate communications techniques to interact with others, depending on the nature of the relationship.
544	7	Supervised Practitioner	Fosters trust through openness and transparency in communication.
545	7	Supervised Practitioner	Uses active listening techniques to clarify understanding of information or views.
547	7	Practitioner	Uses a governing communications plan and appropriate tools to control communications.
549	7	Practitioner	Uses appropriate communications techniques to ensure a shared understanding of information with all project stakeholders. 
550	7	Practitioner	Uses appropriate communications techniques to ensure positive relationships are maintained.
551	7	Practitioner	Uses appropriate communications techniques to express alternate points of view in a diplomatic manner using the appropriate means of communication. 
552	7	Practitioner	Fosters a communicating culture by finding appropriate language and communication styles, augmenting where necessary to avoid misunderstanding.
553	7	Practitioner	Uses appropriate communications techniques to express own thoughts effectively and convincingly in order to reinforce the content of the message.
554	7	Practitioner	Uses full range of active listening techniques to clarify information or views.
555	7	Practitioner	Uses appropriate feedback techniques to verify success of communications.
556	7	Practitioner	Guides new or supervised Systems Engineering practitioners in Communications techniques in order to develop their knowledge, abilities, skills, or associated behaviors. 
558	7	Lead Practitioner	Creates enterprise-level policies, procedures, guidance, and best practice for systems engineering communications, including associated tools. 
559	7	Lead Practitioner	Uses best practice communications techniques to improve the effectiveness of Systems Engineering activities across the enterprise. 
560	7	Lead Practitioner	Maintains positive relationships across the enterprise through effective communications in challenging situations, adapting as necessary to achieve communications clarity or to improve the relationship. 
561	7	Lead Practitioner	Uses effective communications techniques to convince stakeholders across the enterprise to reach consensus in challenging situations.
562	7	Lead Practitioner	Uses a proactive style, building consensus among stakeholders across the enterprise using techniques supporting the verbal messages (e.g. nonverbal communication). 
566	7	Lead Practitioner	Adapts communications techniques or expresses ideas differently to improve effectiveness of communications to stakeholders across the enterprise, by changing language, content, or style.
567	7	Lead Practitioner	Reviews ongoing communications across the enterprise, anticipating and mitigating potential problems.
568	7	Lead Practitioner	Fosters the wider enterprise vision, communicating it successfully across the enterprise.
571	7	Expert	Communicates own knowledge and experience in Communications Techniques in order to improve best practice beyond the enterprise boundary. 
572	7	Expert	Advises organizations beyond the enterprise boundary on the suitability of their approach to communications. 
573	7	Expert	Fosters a collaborative learning, listening atmosphere among key stakeholders beyond the enterprise boundary. 
574	7	Expert	Advises organizations beyond the enterprise boundary on complex or sensitive communications-related matters affecting Systems Engineering.
576	7	Expert	Coaches individuals beyond the enterprise boundary in Communications techniques, in order to further develop their knowledge, abilities, skills, or associated behaviors. 
578	7	Awareness	Explains why the perception of emotion is important including differentiating one’s own emotions from those of others.
579	7	Awareness	Explains how emotions can be used to facilitate thinking such as reasoning, problem solving, and interpersonal communication and explains why this is important.
580	7	Awareness	Explains why it is important to be able to understand and analyze emotions. 
581	7	Awareness	Explains why managing and regulating emotions in both oneself and in others is important.
582	7	Supervised Practitioner	Identifies emotions in one’s physical states, feelings, and thoughts. 
583	7	Supervised Practitioner	Uses emotional intelligence techniques to identify the emotions of others via verbal and nonverbal cues. 
584	7	Supervised Practitioner	Explains the language used to label emotions.
586	7	Practitioner	Uses Emotional Intelligence techniques to interpret meanings and origins of emotions and acts accordingly. 
588	7	Practitioner	Uses emotional intelligence techniques to monitor their own emotions in relation to others.
590	7	Practitioner	Acts to remain open to feelings, both those that are pleasant and those that are unpleasant.
592	7	Practitioner	Guides new or supervised practitioners in emotional intelligence techniques, in order to develop their knowledge, abilities, skills, or associated behaviors.
594	7	Lead Practitioner	Uses best practice emotional intelligence techniques to improve the effectiveness of Systems Engineering activities across the enterprise. 
596	7	Lead Practitioner	Uses emotional intelligence techniques in tough, challenging situations with both external and internal stakeholders, with demonstrable results. 
598	7	Lead Practitioner	Coaches or mentors practitioners across the enterprise in emotional intelligence techniques in order to develop their knowledge, abilities, skills, or associated behaviors.
602	7	Expert	Uses emotional intelligence to influence beyond the enterprise boundary. 
604	7	Expert	Advises beyond the enterprise boundary on complex or sensitive emotionally charged issues.
606	7	Expert	Coaches individuals beyond the enterprise boundary, in emotional intelligence techniques in order to further develop their knowledge, abilities, skills, or associated behaviors. 
587	7	Practitioner	Uses Emotional Intelligence techniques to identify needs related to emotional feelings.
589	7	Practitioner	Acts to capitalize fully upon changing moods in order to best fit the task at hand. 
591	7	Practitioner	Acts to control own emotion by preventing, reducing, enhancing, or modifying an emotional response.
595	7	Lead Practitioner	Guides others across the enterprise in controlling their own emotional responses.
597	7	Lead Practitioner	Uses emotional intelligence to influence key stakeholders within the enterprise.
599	7	Lead Practitioner	Promotes the introduction and use of novel techniques and ideas in Emotional Intelligence techniques across the enterprise, to improve enterprise competence in this area. 
601	7	Expert	Communicates own knowledge and experience in emotional intelligence in order to improve best practice beyond the enterprise boundary.
603	7	Expert	Advises organizations beyond the enterprise boundary on the suitability of their approach to emotional intelligence awareness and its utilization. 
605	7	Expert	Champions the introduction of novel techniques and ideas in the application of emotional intelligence, beyond the enterprise boundary, in order to develop the wider Systems Engineering community in this competency. 
608	8	Awareness	Explains the role of technical leadership within Systems Engineering. 
609	8	Awareness	Defines the terms “vision,” “strategy,” and “goal” terms explaining why each is important in leadership.
610	8	Awareness	Explains why understanding the strategy is central to Systems Engineering leadership.
611	8	Awareness	Explains why fostering collaboration is central to Systems Engineering.
612	8	Awareness	Explains why the art of communications is central to Systems Engineering including the impact of poor communications. 
613	8	Awareness	Explains how technical analysis, problem-solving techniques, and established best practices can be used to improve the excellence of Systems Engineering solutions.
614	8	Awareness	Explains how creativity, ingenuity, experimentation, and accidents or errors, often lead to technological and engineering successes and advances and provides examples.
615	8	Awareness	Explains how different sciences impact the technology domain and the engineering discipline.
616	8	Awareness	Explains how complexity impacts the role of the engineering leader. 
617	8	Supervised Practitioner	Follows guidance received (e.g. from mentors), to plan and control their own technical leadership activities or approaches.
618	8	Supervised Practitioner	Acts to gain trust in their Systems Engineering leadership activities.
619	8	Supervised Practitioner	Complies with a project, or wider, vision in performing Systems Engineering leadership activities.
620	8	Supervised Practitioner	Uses team and project to guide direction, thinking strategically, holistically, and systemically when performing own Systems Engineering leadership activities. 
621	8	Supervised Practitioner	Recognizes constructive criticism from others following guidance to improve their SE leadership. 
622	8	Supervised Practitioner	Uses appropriate mechanisms to offer constructive criticism to others on the team.
623	8	Supervised Practitioner	Elicits viewpoints from others when developing solutions as part of their Systems Engineering leadership role.
624	8	Supervised Practitioner	Uses appropriate communications mechanisms to reinforce their Systems Engineering leadership activities. 
625	8	Supervised Practitioner	Acts creatively and innovatively in their SE leadership activities.
626	8	Supervised Practitioner	Identifies concepts and ideas in sciences, technologies, or engineering disciplines beyond their own discipline, applying them to benefit their own Systems Engineering leadership activities on a project. 
628	8	Practitioner	Follows guidance received to develop their own technical leadership skills, using leadership techniques and tools as instructed.
629	8	Practitioner	Acts with integrity in their leadership activities, being trusted by their team. 
630	8	Practitioner	Guides and actively coordinates Systems Engineering activities across a team, combining appropriate professional and technical competencies, with demonstrable success.
631	8	Practitioner	Develops technical vision for a project team, influencing and integrating the viewpoints of others in order to gain acceptance.
632	8	Practitioner	Identifies a leadership strategy to support of project goals, changing as necessary, to ensure success.
633	8	Practitioner	Recognizes constructive criticism from others within the enterprise following guidance to improve their SE leadership. 
634	8	Practitioner	Uses appropriate communications techniques to offer constructive criticism to others on the team.
635	8	Practitioner	Fosters a collaborative approach in their Systems Engineering leadership activities. 
636	8	Practitioner	Fosters the empowerment of team members, by supporting, facilitating, promoting, giving ownership, and supporting them in their endeavors.
637	8	Practitioner	Uses best practice communications techniques in their leadership activities, in order to express their ideas clearly and effectively. 
638	8	Practitioner	Develops strategies for leadership activities or the resolution of team issues, using creativity and innovation. 
639	8	Practitioner	Guides new or supervised practitioners in matters relating to technical leadership in Systems Engineering, in order to develop their knowledge, abilities, skills, or associated behaviors.
641	8	Lead Practitioner	Uses best practice technical leadership techniques to guide, influence, and gain trust from systems engineering stakeholders across the enterprise. 
642	8	Lead Practitioner	Reacts professionally and positively to constructive criticism received from others across the enterprise. 
643	8	Lead Practitioner	Uses appropriate communications techniques to offer constructive criticism to others across the enterprise. 
645	8	Lead Practitioner	Fosters the empowerment of individuals across the enterprise, by supporting, facilitating, promoting, giving ownership, and supporting them in their endeavors. 
647	8	Lead Practitioner	Coaches or mentors practitioners across the enterprise in technical and leadership issues in order to develop their knowledge, abilities, skills, or associated behaviors.
651	8	Expert	Advises organizations beyond the enterprise boundary on the suitability of their approach to technical leadership issues.
653	8	Expert	Guides and actively coordinates the progress of collaborative activities beyond the enterprise boundary, establishing mutual trust.
655	8	Expert	Advises organizations beyond the enterprise boundary on complex or sensitive team leadership problems or issues, applying creativity and innovation to ensure successful delivery.
657	8	Expert	Champions the introduction of novel techniques and ideas in Systems Engineering technical leadership, beyond the enterprise boundary, in order to develop the wider Systems Engineering community in this competency. 
661	8	Awareness	Explains how those undergoing coaching and mentoring need to act in order to benefit from the activity. 
663	8	Awareness	Lists enterprise goals and describes the influence mentoring may have on meeting those goals.
665	8	Awareness	Describes the design and operation of the enterprise’s coaching and mentoring program.
667	8	Supervised Practitioner	Identifies personal challenges through various perspectives.
671	8	Practitioner	Creates career development goals and objectives with individuals.
673	8	Practitioner	Uses available coaching and mentoring opportunities to develop individuals within the enterprise. 
675	8	Practitioner	Guides new or supervised practitioners in coaching and mentoring techniques, in order to develop their knowledge, abilities, skills, or associated behaviors.
677	8	Lead Practitioner	Promotes the use of best practice coaching and mentoring techniques to improve the effectiveness of Systems Engineering activities across the enterprise.
679	8	Lead Practitioner	Defines the direction of enterprise coaching and mentoring program development. 
681	8	Lead Practitioner	Assesses career development path activities for individuals across the enterprise, providing regular feedback. 
683	8	Lead Practitioner	Coaches or mentors practitioners across the enterprise in coaching and mentoring techniques in order to develop their knowledge, abilities, skills, or associated behaviors. 
687	8	Expert	Persuades key stakeholders beyond the enterprise boundary to follow a particular path for coaching and mentoring activities affecting Systems Engineering.
689	8	Expert	Advises organizations beyond the enterprise boundary on the development of coaching and mentoring programs. 
691	8	Expert	Advises organizations beyond the enterprise boundary on complex or challenging coaching and mentoring issues. 
693	8	Expert	Coaches individuals beyond the enterprise boundary, in coaching and mentoring techniques in order to further develop their knowledge, abilities, skills, or associated behaviors. 
644	8	Lead Practitioner	Fosters stakeholder collaboration across the enterprise, sharing ideas and knowledge, and establishing mutual trust. 
646	8	Lead Practitioner	Acts with creativity and innovation, applying problem- solving techniques to develop strategies or resolve complex project or enterprise technical leadership issues. 
648	8	Lead Practitioner	Promotes the introduction and use of novel techniques and ideas in SE technical leadership across the enterprise, to improve enterprise competence in this area.
650	8	Expert	Communicates own knowledge and experience in technical leadership in order to improve best practice beyond the enterprise boundary. 
652	8	Expert	Guides and actively coordinates the progress of Systems Engineering activities beyond the enterprise boundary, combining appropriate professional competencies with technical knowledge and experience. 
654	8	Expert	Fosters empowerment of others beyond the enterprise boundary. 
656	8	Expert	Uses their extended network and influencing skills to gain collaborative agreement with key stakeholders beyond the enterprise boundary in order to progress project or their own enterprise needs. 
658	8	Expert	Coaches individuals beyond the enterprise boundary, in technical leadership techniques in order to further develop their knowledge, abilities, skills, or associated behaviors. 
660	8	Awareness	Describes key characteristics and personal attributes of coach and mentor roles, and how both approaches help to develop individual potential. 
662	8	Awareness	Explains why listening to an individual’s goals and objectives is important. 
664	8	Awareness	Explains why taking a comprehensive approach to assess an individual’s challenge is important. 
666	8	Supervised Practitioner	Identifies areas of own skills, knowledge, or experience which could be improved.
668	8	Supervised Practitioner	Prepares information supporting the development of others within the team. 
670	8	Practitioner	Coaches (or mentors) others on the project as part of an enterprise coaching and mentoring program.
672	8	Practitioner	Develops individual career development paths based on development goals and objectives.
674	8	Practitioner	Develops individuals within their team by supporting them in solving their individual challenges.
678	8	Lead Practitioner	Judges the suitability of planned coaching and mentoring programs affecting Systems Engineering within the enterprise.
680	8	Lead Practitioner	Guides and actively coordinates the implementation of an enterprise- level coaching and mentoring program.
682	8	Lead Practitioner	Advises stakeholders across the enterprise on individual coaching and mentoring issues with demonstrable success. 
684	8	Lead Practitioner	Promotes the introduction and use of novel techniques and ideas in Coaching and Mentoring across the enterprise, to improve enterprise competence in this area.
686	8	Expert	Communicates own knowledge and experience in coaching and mentoring skills in order to improve best practice beyond the enterprise boundary. 
688	8	Expert	Advises organizations beyond the enterprise boundary on the suitability of their approach to coaching and mentoring. 
690	8	Expert	Assesses the effectiveness of a mentoring program for an organization beyond the enterprise boundary, providing regular feedback. 
692	8	Expert	Champions the introduction of novel techniques and ideas in coaching and mentoring, beyond the enterprise boundary, in order to develop the wider Systems Engineering community in this competency. 
695	16	Awareness	Explains why integration is important and how it confirms the system design, architecture, and interfaces.
696	16	Awareness	Explains why it is important to integrate the system in a logical sequence. 
697	16	Awareness	Explains why planning and management of systems integration is necessary.
698	16	Awareness	Explains the relationship between integration and verification. 
699	16	Supervised Practitioner	Uses a governing process using appropriate tools to manage and control their own integration activities. 
700	16	Supervised Practitioner	Prepares inputs to integration plans based upon governing standards and processes including identification of method and timing for each activity to meet project requirements. 
701	16	Supervised Practitioner	Prepares plans which address integration for system elements (or noncomplex systems) in order to define or scope that activity.
702	16	Supervised Practitioner	Records the causes of simple faults typically found during integration activities in order to communicate with stakeholders.
703	16	Supervised Practitioner	Collates evidence during integration in support of downstream test and acceptance activities.
704	16	Supervised Practitioner	Identifies an integration environment to facilitate system integration activities. 
706	16	Practitioner	Creates a strategy for system integration on a project to support SE project and wider enterprise needs. 
707	16	Practitioner	Creates a governing process, plan, and associated tools for systems integration, which reflect project and business strategy. 
708	16	Practitioner	Uses governing plans and processes to plan and execute system integration activities, interpreting, evolving, or seeking guidance where appropriate. 
709	16	Practitioner	Performs rectification of faults found during integration activities.
710	16	Practitioner	Prepares evidence obtained during integration in support of downstream test and acceptance activities. 
711	16	Practitioner	Guides and actively coordinates integration activities for a system.
712	16	Practitioner	Identifies a suitable integration environment.
713	16	Practitioner	Creates detailed integration procedures.
714	16	Practitioner	Guides new or supervised practitioners in Systems integration to develop their knowledge, abilities, skills, or associated behaviors.
717	16	Lead Practitioner	Judges the tailoring of enterprise- level integration processes to meet the needs of a project. 
716	16	Lead Practitioner	Creates enterprise-level policies, procedures, guidance, and best practice for integration, including associated tools for a project.
718	16	Lead Practitioner	Judges the suitability of integration plans from projects across the enterprise, to ensure project success.
720	16	Lead Practitioner	Judges integration evidence generated by projects across the enterprise, to ensure adequacy of information. 
722	16	Lead Practitioner	Persuades key stakeholders to address identified enterprise-level system integration issues to reduce project cost, schedule, or technical risk.
724	16	Lead Practitioner	Promotes the introduction and use of novel techniques and ideas in systems integration across the enterprise, to improve enterprise competence in this area. 
726	16	Expert	Communicates own knowledge and experience in Systems Integration in order to promote best practice beyond the enterprise boundary.
728	16	Expert	Advises organizations beyond the enterprise boundary on the suitability of their approach to integration to support enterprise needs. 
730	16	Expert	Advises organizations beyond the enterprise boundary on complex or sensitive integration-related issues to support enterprise needs. 
719	16	Lead Practitioner	Judges detailed integration procedures from projects across the enterprise, to ensure project success. 
721	16	Lead Practitioner	Guides and actively coordinates integration activities on complex systems or across multiple projects from projects across the enterprise.
723	16	Lead Practitioner	Coaches or mentors practitioners across the enterprise in systems integration in order to develop their knowledge, abilities, skills, or associated behaviors. 
727	16	Expert	Persuades key stakeholders beyond the enterprise boundary to accept recommendation associated with integration activities. 
729	16	Expert	Advises organizations beyond the enterprise boundary on evidence generated during integration to support enterprise needs. 
731	16	Expert	Champions the introduction of novel techniques and ideas in systems integration, beyond the enterprise boundary, in order to develop the wider Systems Engineering community in this competency. 
732	16	Expert	Coaches individuals beyond the enterprise boundary in Systems Integration, in order to further develop their knowledge, abilities, skills, or associated behaviors. 
734	16	Expert	Maintains expertise in "Integration" competency area through specialist Continual Professional Development (CPD) activities.
735	16	Lead Practitioner	Develops expertise in "Integration" competency area through specialist Continual Professional Development (CPD) activities.
736	16	Practitioner	Maintains and enhances own competence in "Integration" competency area through Continual Professional Development (CPD) activities.
737	16	Supervised Practitioner	Develops own understanding of "Integration" competency area through Continual Professional Development (CPD). 
738	16	Awareness	Explains what verification is, the purpose of verification, and why verification against the system requirements is important. 
739	16	Awareness	Explains why there is a need to verify the system in a logical sequence. 
740	16	Awareness	Explains why planning for system verification is necessary.
741	16	Awareness	Explains how traceability can be used to establish whether a system meets requirements.
742	16	Awareness	Describes the relationship between verification, validation, qualification, certification, and acceptance. 
743	16	Supervised Practitioner	Complies with a governing process and appropriate tools to plan and control their own verification activities. 
744	16	Supervised Practitioner	Prepares inputs to verification plans.
745	16	Supervised Practitioner	Prepares verification plans for smaller projects.
746	16	Supervised Practitioner	Performs verification testing as part of system verification activities. 
747	16	Supervised Practitioner	Identifies simple faults found during verification through diagnosis and consequential corrective actions. 
748	16	Supervised Practitioner	Collates evidence in support of verification, qualification, certification, and acceptance.
749	16	Supervised Practitioner	Reviews verification evidence to establish whether a system meets requirements. 
751	16	Supervised Practitioner	Selects a verification environment to ensure requirements can be fully verified.
752	16	Supervised Practitioner	Develops own understanding of "Verification" competency area through Continual Professional Development (CPD). 
753	16	Practitioner	Creates a strategy for system verification on a project to support SE project and wider enterprise needs.
754	16	Practitioner	Creates a governing process, plan, and associated tools for systems verification, which reflect project and business strategy.
755	16	Practitioner	Uses governing plans and processes for System verification, interpreting, evolving, or seeking guidance where appropriate.
756	16	Practitioner	Prepares verification plans for systems or projects.
757	16	Practitioner	Reviews project-level system verification plans.
758	16	Practitioner	Reviews verification results, diagnosing complex faults found during verification activities.
759	16	Practitioner	Prepares evidence obtained during verification testing to support system verification or downstream qualification, certification, and acceptance activities. 
760	16	Practitioner	Monitors the traceability of verification requirements and tests to system requirements and vice versa. 
761	16	Practitioner	Identifies a suitable verification environment. 
762	16	Practitioner	Creates detailed verification procedures. 
763	16	Practitioner	Performs system verification activities.
764	16	Practitioner	Prepares evidence obtained during verification testing to support downstream verification testing, integration, or validation activities.
765	16	Practitioner	Guides new or supervised practitioners in Systems verification in order to develop their knowledge, abilities, skills, or associated behaviors. 
766	16	Practitioner	Maintains and enhances own competence in "Verification" competency area through Continual Professional Development (CPD) activities. 
767	16	Lead Practitioner	Creates enterprise-level policies, procedures, guidance, and best practice for verification, including associated tools. 
768	16	Lead Practitioner	Judges the tailoring of enterprise- level verification processes to meet the needs of a project. 
769	16	Lead Practitioner	Judges the suitability of verification plans, from multiple projects, on behalf of the enterprise. 
770	16	Lead Practitioner	Advises on verification approaches on complex or challenging systems or projects across the enterprise.
771	16	Lead Practitioner	Judges detailed verification procedures from multiple projects, on behalf of the enterprise.
772	16	Lead Practitioner	Judges verification evidence generated from multiple projects on behalf of the enterprise.
773	16	Lead Practitioner	Guides and actively coordinates verification activities for complex systems or projects across the enterprise.
774	16	Lead Practitioner	Coaches or mentors practitioners across the enterprise in systems verification in order to develop their knowledge, abilities, skills, or associated behaviors. 
775	16	Lead Practitioner	Promotes the introduction and use of novel techniques and ideas in verification across the enterprise, to improve enterprise competence in this area. 
776	16	Lead Practitioner	Develops expertise in "Verification" competency area through specialist Continual Professional Development (CPD) activities. 
777	16	Expert	Communicates own knowledge and experience in Systems Engineering verification in order to improve best practice beyond the enterprise boundary. 
779	16	Expert	Advises organizations beyond the enterprise boundary on their Systems Engineering Verification plans or practices on complex systems or projects. 
781	16	Expert	Champions the introduction of novel techniques and ideas in systems verification, beyond the enterprise boundary, in order to develop the wider Systems Engineering community in this competency.
783	16	Expert	Maintains expertise in "Verification" competency area through specialist Continual Professional Development (CPD) activities.
785	16	Awareness	Explains why there is a need for early planning for validation.
787	16	Awareness	Describes the relationship between traceability and validation.
789	16	Supervised Practitioner	Prepares inputs to validation plans. 
791	16	Supervised Practitioner	Performs validation testing as part of system validation or system acceptance. 
793	16	Supervised Practitioner	Collates evidence in support of validation, qualification, certification, and acceptance.
795	16	Supervised Practitioner	Selects a validation environment to ensure requirements can be fully validated. 
797	16	Practitioner	Creates a strategy for system validation on a project to support SE project and wider enterprise needs.
799	16	Practitioner	Uses governing plans and processes for System validation, interpreting, evolving, or seeking guidance where appropriate. 
801	16	Practitioner	Prepares validation plans for systems or projects. 
803	16	Practitioner	Reviews validation results, diagnosing complex faults found during validation activities.
805	16	Practitioner	Creates detailed validation procedures.
807	16	Practitioner	Prepares evidence obtained during validation testing to support certification and acceptance activities. 
809	16	Practitioner	Guides new or supervised practitioners in System Validation in order to develop their knowledge, abilities, skills, or associated behaviors. 
811	16	Lead Practitioner	Creates enterprise-level policies, procedures, guidance, and best practice for validation, including associated tools.
813	16	Lead Practitioner	Judges the suitability of validation plans from multiple projects, on behalf of the enterprise.
815	16	Lead Practitioner	Judges detailed validation procedures from multiple projects, on behalf of the enterprise. 
817	16	Lead Practitioner	Guides and actively coordinates validation activities on complex systems or projects across the enterprise. 
819	16	Lead Practitioner	Promotes the introduction and use of novel techniques and ideas in validation across the enterprise, to improve enterprise competence in Validation area.
821	16	Expert	Communicates own knowledge and experience in Systems Engineering validation in order to improve best practice beyond the enterprise boundary. 
823	16	Expert	Advises organizations beyond the enterprise boundary on their handling of complex or sensitive Systems Engineering validation issues.
825	16	Expert	Champions the introduction of novel techniques and ideas in system validation, beyond the enterprise boundary, in order to develop the wider Systems Engineering community in this competency. 
828	16	Expert	Maintains expertise in Validation competency area through specialist Continual Professional Development (CPD) activities. 
778	16	Expert	Advises organizations beyond the enterprise boundary on the suitability of their approach to Systems Engineering verification.
780	16	Expert	Advises organizations beyond the enterprise boundary on complex or sensitive verification-related issues.
782	16	Expert	Coaches individuals beyond the enterprise boundary in Systems Verification, in order to further develop their knowledge, abilities, skills, or associated behaviors. 
784	16	Awareness	Explains what validation is, the purpose of validation, and why validation is important.
786	16	Awareness	Describes the relationship between validation, verification, qualification, certification, and acceptance.
788	16	Supervised Practitioner	Complies with a governing process and appropriate tools to plan and control their own validation activities.
790	16	Supervised Practitioner	Prepares validation plans for smaller projects. 
792	16	Supervised Practitioner	Identifies simple faults found during validation through diagnosis and consequential corrective actions. 
794	16	Supervised Practitioner	Reviews validation evidence to establish whether a system will meet the operational need.
796	16	Supervised Practitioner	Develops own understanding of "Validation" competency area through Continual Professional Development (CPD). 
798	16	Practitioner	Creates a governing process, plan, and associated tools for system validation, which reflect project and business strategy.
800	16	Practitioner	Communicates using the terminology of the customer while focusing on customer need.
802	16	Practitioner	Reviews project-level system validation plans. 
804	16	Practitioner	Identifies a suitable validation environment. 
806	16	Practitioner	Performs system validation activities. 
808	16	Practitioner	Monitors the traceability of validation requirements and tests to system requirements and vice versa. 
810	16	Practitioner	Maintains and enhances own competence in "Validation" area through Continual Professional Development (CPD) activities. 
812	16	Lead Practitioner	Judges the tailoring of enterprise- level validation processes to meet the needs of a project.
814	16	Lead Practitioner	Advises on validation approaches on complex or challenging systems or projects across the enterprise.
816	16	Lead Practitioner	Judges validation evidence generated from multiple projects on behalf of the enterprise.
818	16	Lead Practitioner	Coaches or mentors practitioners across the enterprise in systems validation in order to develop their knowledge, abilities, skills, or associated behaviors.
820	16	Lead Practitioner	Develops expertise in Validation competency area through specialist Continual Professional Development (CPD) activities. 
822	16	Expert	Advises organizations beyond the enterprise boundary on the suitability of their approach to Systems Engineering validation. 
824	16	Expert	Advises organizations beyond the enterprise boundary on complex or sensitive validation-related issues.
826	16	Expert	Coaches individuals beyond the enterprise boundary in Systems validation, in order to further develop their knowledge, abilities, skills, or associated behaviors. 
829	17	Awareness	Explains why a system needs to be supported during operation.
830	17	Awareness	Describes the difference between preventive and corrective maintenance.
831	17	Awareness	Explains why it is necessary to address failures, parts obsolescence, and evolving user requirements during system operation. 
832	17	Awareness	Lists the different levels of repair capability and describes the characteristics of each. 
833	17	Awareness	Explains the impact of operations and support on specialty engineering areas.
834	17	Supervised Practitioner	Uses a governing process and appropriate tools to plan and control their own operations and support activities. 
835	17	Supervised Practitioner	Identifies operational data in order to assess system performance. 
836	17	Supervised Practitioner	Reviews system failures or performance issues, proposing design changes to rectify such failures.
837	17	Supervised Practitioner	Performs rectification of system failures or performance issues.
838	17	Supervised Practitioner	Reviews the feasibility and impact of evolving user need on operations, maintenance, and support. 
839	17	Supervised Practitioner	Prepares inputs to concept studies to document the impact or feasibility of new technologies or possible system updates. 
840	17	Supervised Practitioner	Prepares inputs to obsolescence studies to identify obsolescent components and suitable replacements. 
841	17	Supervised Practitioner	Prepares updates to technical data (e.g. procedures, guidelines, checklists, and training materials) to ensure operations and maintenance activities and data are current.
842	17	Supervised Practitioner	Identifies potential changes to system operational environment or external interfaces. 
843	17	Supervised Practitioner	Develops own understanding of Utilization and Support competency area through Continual Professional Development (CPD). 
844	17	Practitioner	Creates a strategy for system utilization and support, which reflects wider project and business strategies.
845	17	Practitioner	Creates a governing process, plan, and associated tools for system utilization and support, which reflect wider project and business plans. 
846	17	Practitioner	Uses governing plans and processes for System Utilization and support, interpreting, evolving, or seeking guidance where appropriate.
847	17	Practitioner	Guides and actively coordinates in-service support activities for a system. 
848	17	Practitioner	Identifies data to be collected in order to assess system operational performance. 
849	17	Practitioner	Reviews system failures or performance issues in order to initiate design change proposals rectifying these failures.
850	17	Practitioner	Identifies system elements approaching obsolescence and conducts studies to identify suitable replacements. 
851	17	Practitioner	Maintains system elements and associated documentation following their replacement due to obsolescence.
852	17	Practitioner	Monitors the effectiveness of system support or operations.
853	17	Practitioner	Reviews the timing of technology upgrade implementations in order to improve the cost–benefit ratio of an upgraded design solution.
854	17	Practitioner	Reviews potential changes to the system operational environment or external interfaces.
855	17	Practitioner	Reviews technical support data (e.g. procedures, guidelines, checklists, training, and maintenance materials) to ensure it is current.
857	17	Practitioner	Maintains and enhances own competence in Utilization and Support area through Continual Professional Development (CPD) activities. 
859	17	Lead Practitioner	Judges the tailoring of enterprise- level utilization and support processes to meet the needs of a project.
861	17	Lead Practitioner	Advises across the enterprise on technology upgrade implementations in order to improve the cost–benefit ratio of an upgraded design solution.
863	17	Lead Practitioner	Coaches or mentors practitioners across the enterprise in systems utilization and support in order to develop their knowledge, abilities, skills, or associated behaviors. 
865	17	Lead Practitioner	Develops expertise in Utilization and Support competency area through specialist Continual Professional Development (CPD) activities. 
867	17	Expert	Advises organizations beyond the enterprise boundary on the suitability of their approach to system utilization and support. 
869	17	Expert	Champions the introduction of novel techniques and ideas in systems utilization and support, beyond the enterprise boundary, in order to develop the wider Systems Engineering community in this competency.
871	17	Expert	Maintains expertise in Utilization and Support competency area through specialist Continual Professional Development (CPD) activities. 
856	17	Practitioner	Guides new or supervised practitioners in System operation, support, and maintenance, in order to develop their knowledge, abilities, skills, or associated behaviors. 
858	17	Lead Practitioner	Creates enterprise-level policies, procedures, guidance, and best practice for utilization and support, including associated tools.
860	17	Lead Practitioner	Advises across the enterprise on the application of advanced practices to improve the effectiveness of project-level system support or operations.
862	17	Lead Practitioner	Persuades key stakeholders across the enterprise to address identified operation, maintenance, and support issues to reduce project or wider enterprise risk.
864	17	Lead Practitioner	Promotes the introduction and use of novel techniques and ideas in systems operations and support across the enterprise, to improve enterprise competence in  Utilization and Support area.
866	17	Expert	Communicates own knowledge and experience in systems utilization and support in order to improve best practice beyond the enterprise boundary.
868	17	Expert	Advises organizations beyond the enterprise boundary on the handling of complex or sensitive operations, maintenance, and support-related issues.
870	17	Expert	Coaches individuals beyond the enterprise boundary in System Utilization and support, in order to further develop their knowledge, abilities, skills, or associated behaviors. 
872	1	Supervised Practitioner	Develops own understanding of Systems Thinking competency area through Continual Professional Development (CPD).
873	1	Practitioner	Maintains and enhances own competence in Systems Thinking area through Continual Professional Development (CPD) activities.
874	1	Lead Practitioner	Promotes the introduction and use of novel techniques and ideas in systems thinking across the enterprise, to improve enterprise competence in Systems Thinking area. 
875	1	Lead Practitioner	Develops expertise in  Systems Thinking competency area through specialist Continual Professional Development (CPD) activities.
876	1	Expert	Maintains expertise in Systems Thinking competency area through specialist Continual Professional Development (CPD) activities.
877	1	Practitioner	Maintains and enhances own competence in Capability Engineering area through Continual Professional Development (CPD) activities. 
878	1	Supervised Practitioner	Develops own understanding of Capability Engineering competency area through Continual Professional Development (CPD). 
879	1	Lead Practitioner	Develops expertise in Capability Engineering competency area through specialist Continual Professional Development (CPD) activities.
880	1	Expert	Maintains expertise in Capability Engineering competency area through specialist Continual Professional Development (CPD) activities. 
881	6	Supervised Practitioner	Develops own understanding of Systems Modeling and Analysis competency area through Continual Professional Development (CPD).
882	6	Practitioner	Maintains and enhances own competence in Systems Modeling and Analysis area through Continual Professional Development (CPD) activities.
883	6	Lead Practitioner	Develops expertise in Systems Modeling and Analysis competency area through specialist Continual Professional Development (CPD) activities.
884	6	Expert	Maintains expertise in Systems Modeling and Analysis competency area through specialist Continual Professional Development (CPD) activities.
885	4	Supervised Practitioner	Develops own understanding of Lifecycle Consideration competency area through Continual Professional Development (CPD).
886	4	Practitioner	Maintains and enhances own competence in Lifecycle Consideration area through Continual Professional Development (CPD) activities.
887	4	Lead Practitioner	Develops expertise in Lifecycle Consideration competency area through specialist Continual Professional Development (CPD) activities.
888	4	Expert	Maintains expertise in Lifecycle Consideration competency area through specialist Continual Professional Development (CPD) activities. 
889	7	Supervised Practitioner	Develops own understanding of Communications competency area through Continual Professional Development (CPD).
890	7	Supervised Practitioner	Develops own understanding of Emotional Intelligence competency area through Continual Professional Development (CPD).
891	7	Practitioner	Maintains and enhances own competence in "Communication" area through Continual Professional Development (CPD) activities.
892	7	Practitioner	Maintains and enhances own competence in "Emotional Intelligence" area through Continual Professional Development (CPD) activities.
893	7	Lead Practitioner	Develops expertise in "Communication" competency area through specialist Continual Professional Development (CPD) activities.
894	7	Lead Practitioner	Develops expertise in "Emotional Intelligence" competency area through specialist Continual Professional Development (CPD) activities.
895	7	Lead Practitioner	Coaches or mentors practitioners across the enterprise, or those new to "Communications" competency area in order to develop their knowledge, abilities, skills, or associated behaviors.
896	7	Expert	Champions the introduction of novel techniques and ideas in “communications competency”, beyond the enterprise boundary, in order to develop the wider Systems Engineering community in this competency.
897	7	Expert	Maintains expertise in "Communication" competency area through specialist Continual Professional Development (CPD) activities.
898	7	Expert	Maintains expertise in "Emotional Intelligence" competency area through specialist Continual Professional Development (CPD) activities.
899	8	Supervised Practitioner	Develops own understanding of "Technical Leadership" competency area through Continual Professional Development (CPD).
900	8	Supervised Practitioner	Develops own understanding of "Coaching and Mentoring" competency area through Continual Professional Development (CPD).
901	8	Practitioner	Maintains and enhances own competence in "Technical Leadership" area through Continual Professional Development (CPD) activities.
902	8	Practitioner	Maintains and enhances own competence in "Coaching and Mentoring" area through Continual Professional Development (CPD) activities.
903	8	Lead Practitioner	Develops expertise in "Technical Leadership" competency area through specialist Continual Professional Development (CPD) activities.
904	8	Lead Practitioner	Develops expertise in "Coaching and Mentoring" competency area through specialist Continual Professional Development (CPD) activities.
905	8	Expert	Maintains expertise in "Technical Leadership" competency area through specialist Continual Professional Development (CPD) activities.
909	10	Lead Practitioner	Develops expertise in "Project Management" competency area through specialist Continual Professional Development (CPD) activities.
915	11	Lead Practitioner	Promotes the introduction and use of novel techniques and ideas in decision resolution and management across the enterprise, to improve enterprise competence in "Decision Management" area. 
906	8	Expert	Maintains expertise in "Coaching and Mentoring" competency area through specialist Continual Professional Development (CPD) activities.
907	10	Supervised Practitioner	Develops own understanding of "Project Management" competency area through Continual Professional Development (CPD). 
913	11	Practitioner	Maintains and enhances own competence in "Decision Management" area through Continual Professional Development (CPD) activities.
908	10	Practitioner	Maintains and enhances own competence in "Project Management" area through Continual Professional Development (CPD) activities.
914	11	Lead Practitioner	Develops expertise in "Decision Management" competency area through specialist Continual Professional Development (CPD) activities.
910	10	Expert	Champions the introduction of novel techniques and ideas to improve the integration of Systems Engineering and project management functions, beyond the enterprise boundary, in order to develop the wider Systems Engineering community in "Project Management" competency. 
911	10	Expert	Maintains expertise in "Project Management" competency area through specialist Continual Professional Development (CPD) activities.
912	11	Supervised Practitioner	Develops own understanding of "Decision Management" competency area through Continual Professional Development (CPD).
916	11	Expert	Maintains expertise in "Decision Management" competency area through specialist Continual Professional Development (CPD) activities.
917	11	Expert	Champions the introduction of novel techniques and ideas in Systems Engineering decision management, beyond the enterprise boundary, in order to develop the wider Systems Engineering community in "Decision Management" competency.
918	12	Supervised Practitioner	Develops own understanding of Information Management competency area through Continual Professional Development (CPD).
919	12	Practitioner	Maintains and enhances own competence in Information Management area through Continual Professional Development (CPD) activities.
920	12	Lead Practitioner	Develops expertise in Information Management competency area through specialist Continual Professional Development (CPD) activities.
921	12	Expert	Maintains expertise in Information Management competency area through specialist Continual Professional Development (CPD) activities.
922	12	Expert	Champions the introduction of novel techniques and ideas in information management, beyond the enterprise boundary, in order to develop the wider Systems Engineering community in "Information Management" competency.
923	13	Supervised Practitioner	Develops own understanding of Configuration Management competency area through Continual Professional Development (CPD).
924	13	Supervised Practitioner	Maintains and enhances own competence in Configuration Management area through Continual Professional Development (CPD) activities.
925	13	Lead Practitioner	Promotes the introduction and use of novel techniques and ideas in Configuration Management, across the enterprise, to improve enterprise competence in "Configuration Management" area. 
926	13	Lead Practitioner	Develops expertise in Configuration Management competency area through specialist Continual Professional Development (CPD) activities.
927	13	Expert	Champions the introduction of novel techniques and ideas in configuration management, beyond the enterprise boundary, in order to develop the wider Systems Engineering community in "Configuration Management" competency. 
928	13	Expert	Maintains expertise in Configuration Management competency area through specialist Continual Professional Development (CPD) activities.
929	14	Supervised Practitioner	Develops own understanding of Requirements Definition competency area through Continual Professional Development (CPD).
930	14	Practitioner	Maintains and enhances own competence in Requirements Definition area through Continual Professional Development (CPD) activities.
931	14	Lead Practitioner	Develops expertise in Requirements Definition competency area through specialist Continual Professional Development (CPD) activities.
932	14	Lead Practitioner	Promotes the introduction and use of novel techniques and ideas in Requirements Definition across the enterprise, to improve enterprise competence in Requirements Definition area. 
933	14	Expert	Maintains expertise in Requirements Definition competency area through specialist Continual Professional Development (CPD) activities.
934	14	Expert	Champions the introduction of novel techniques and ideas in the requirements definition, beyond the enterprise boundary, in order to develop the wider Systems Engineering community in "Requirements Definition" competency. 
935	15	Supervised Practitioner	Develops own understanding of System Architecting competency area through Continual Professional Development (CPD).
936	15	Practitioner	Maintains and enhances own competence in System Architecting area through Continual Professional Development (CPD) activities.
937	15	Lead Practitioner	Develops expertise in System Architecting competency area through specialist Continual Professional Development (CPD) activities.
938	15	Lead Practitioner	Promotes the introduction and use of novel techniques and ideas in Systems Architecting across the enterprise, to improve enterprise competence in "System Architecting" area. 
939	15	Expert	Maintains expertise in System Architecting competency area through specialist Continual Professional Development (CPD) activities.
940	15	Expert	Champions the introduction of novel techniques and ideas in systems architecting, beyond the enterprise boundary, in order to develop the wider Systems Engineering community in "System Architecting" competency.
\.


--
-- Data for Name: iso_activities; Type: TABLE DATA; Schema: public; Owner: adminderik
--

COPY public.iso_activities (id, name, process_id) FROM stdin;
1	Prepare for the acquisition	1
2	Advertise the acquisition and select the supplier	1
4	Monitor the agreement	1
5	Accept the product or service	1
6	Prepare for the supply	2
7	Respond to a request for supply of products or services	2
9	Execute the agreement	2
10	Deliver and support the product or service	2
11	Establish the life cycle processes	3
12	Assess the life cycle processes	3
13	Improve the process	3
14	Establish the infrastructure	4
15	Maintain the infrastructure	4
16	Define and authorise projects	5
17	Evaluate the portfolio of projects	5
18	Terminate projects	5
19	Identify skills	6
20	Develop skills	6
21	Acquire and provide skills	6
22	Plan quality management	7
23	Assess quality management	7
24	Perform quality management corrective and preventive action	7
25	Plan knowledge management	8
26	Share knowledge and skills throughout the organization	8
27	Share knowledge assets throughout the organization	8
28	Manage knowledge, skills, and knowledge assets	8
29	Define the project	9
30	Plan project and technical management	9
31	Activate the project	9
32	Plan for project assessment and control	10
33	Assess the project	10
34	Control the project	10
35	Prepare for decisions	11
36	Analyse the decision information	11
37	Make and manage decisions	11
38	Plan risk management	12
39	Maintain the risk profile	12
40	Analyse risks	12
41	Treat risks that exceed their risk threshold	12
42	Monitor risks	12
43	Prepare for configuration management	13
44	Perform configuration identification	13
45	Perform configuration change management	13
46	Perform configuration status accounting	13
47	Perform configuration verification and audit	13
48	Prepare for information management	14
49	Perform information management	14
50	Prepare for measurement	15
51	Perform measurement	15
52	Prepare for quality assurance	16
53	Perform product or service evaluations	16
54	Perform process evaluations	16
55	Manage QA records and reports	16
56	Treat incidents and problems	16
57	Prepare for business or mission analysis	17
58	Define the problem or opportunity space	17
59	Characterize the solution space	17
60	Evaluate alternative solution classes	17
61	Manage the business or mission analysis	17
62	Prepare for stakeholder needs and requirements definition	18
63	Develop the operational concept and other life cycle concepts This activity consists of the followingtasks	18
64	Define stakeholder needs	18
65	Transform stakeholder needs into stakeholder requirements	18
66	Analyse stakeholder needs and requirements	18
67	Manage the stakeholder needs and requirements definition	18
68	Prepare for system requirements definition	19
69	Define system requirements	19
70	Analyse system requirements	19
71	Manage system requirements	19
72	Prepare for system architecture definition	20
73	Conceptualise the system architecture	20
74	Evaluate the system architecture	20
75	Elaborate the system architecture	20
76	Manage results of system architecture definition	20
77	Prepare for design definition	21
78	Create the system design	21
79	Evaluate the system design	21
80	Manage results of design definition	21
81	Prepare for system analysis	22
82	Perform system analysis	22
83	Manage system analysis	22
84	Prepare for implementation	23
85	Perform implementation	23
86	Manage results of implementation	23
87	Prepare for integration	24
88	Perform integration	24
89	Manage results of integration	24
90	Prepare for verification	25
91	Perform verification	25
92	Manage results of verification	25
93	Prepare for the transition	26
94	Perform the transition	26
95	Manage results of transition	26
96	Prepare for validation	27
97	Perform validation	27
98	Manage results of validation	27
99	Prepare for operation	28
100	Perform operation	28
101	Manage results of operation	28
102	Support stakeholders	28
103	Prepare for maintenance and logistics	29
104	Perform maintenance	29
105	Perform logistics support	29
106	Manage results of maintenance and logistics	29
107	Prepare for disposal	30
108	Perform disposal	30
109	Finalise the disposal	30
3	Establish and maintain an agreement(acquisition process)	1
8	Establish and maintain an agreement(supply process)	2
\.


--
-- Data for Name: iso_processes; Type: TABLE DATA; Schema: public; Owner: adminderik
--

COPY public.iso_processes (id, name, description, life_cycle_process_id) FROM stdin;
1	acquisition process	Used by organizations for acquiring products or services. The purpose of the acquisition process is to obtain a product or service in accordance with the acquirer'srequirements.	1
2	supply process	Used by organizations for supplying products or services. The purpose of the supply process is to provide an acquirer with a product or service that meets agreedrequirements.	1
3	Life cycle model management process	The purpose of the life cycle model management process is to define, maintain, and help ensureavailability of policies, life cycle processes, life cycle models, and procedures for use by the organizationwith respect to the scope of this document.  This process provides policies, life cycle processes, life cycle models, and procedures that are consistentwith the organization's objectives. These life cycle assets are defined, adapted, improved, andmaintained to support individual project needs in a way that they are capable of being applied usingeffective, proven methods and tools.	2
4	Infrastructure management process	The purpose of the infrastructure management process is to provide the infrastructure and services toprojects to support organization and project objectives throughout the life cycle.This process defines, provides and maintains the facilities, tools, and communications and informationtechnology assets needed for the organization with respect to the scope of this document.	2
5	Portfolio management process	The purpose of the portfolio management process is to initiate and sustain necessary, sufficient, andsuitable projects to meet the strategic objectives of the organization.This process commits the investment of adequate organization funding and resources, and sanctionsthe authorities needed to establish selected projects. It performs continued assessment of projects toconfirm they justify, or can be redirected to justify, continued investment.	2
6	Human resource management process	The purpose of the human resource management process is to provide the organization with necessaryhuman resources and to maintain their competencies, consistent with strategic needs.This process provides a supply of skilled and experienced personnel qualified to perform life cycleprocesses to achieve organization, project, and stakeholder objectives.	2
7	Quality management process	The purpose of the quality management process is to assure that products, services, and implementationsof the quality management process meet organizational and project quality objectives, and achievecustomer satisfaction.	2
8	Knowledge management process	The purpose of the knowledge management process is to create the capability and assets that enablethe organization to exploit opportunities to re-apply existing knowledge.This encompasses knowledge, skills, and knowledge assets, including system elements	2
9	Project planning process	The purpose of the project planning process is to produce and coordinate effective and workable plans.This process determines the scope of the project management and technical activities, identifies processoutputs, tasks and deliverables, establishes schedules for task conduct, including achievement criteria,and required resources to accomplish tasks. This is an on-going process that continues throughout aproject, with regular revisions to plans. ISO/IEC/IEEE 16326 provides additional information on projectplanning.	3
10	Project assessment and control process	The purpose of the project assessment and control process is to assess if the plans are aligned andfeasible; determine the status of the project, technical and process performance; and direct executionto help ensure that the performance is according to plans and schedules, within projected budgets, tosatisfy project objectives.This process evaluates, periodically and at major events, the progress and achievements againstrequirements, plans, and overall strategic objectives. Information is provided for management actionwhen significant variances are detected. This process also includes redirecting the project activities andtasks, as appropriate, to correct identified deviations and variations from other technical managementor technical processes. Redirection may include re-planning as appropriate.	3
11	Decision management process	The purpose of the decision management process is to provide a structured, analytical framework forobjectively identifying, characterizing, and evaluating a set of alternatives for a decision at any point inthe life cycle and select the most beneficial course of action.	3
12	Risk management process	The purpose of the risk management process is to identify, analyse, treat, and monitor the riskscontinually.The risk management process systematically addresses uncertainty throughout the life cycle of asystem product or service towards achieving objectives.	3
13	Configuration management process	The purpose of the configuration management process is to manage system and system elementconfigurations over their life cycle.Managing includes establishing and maintaining consistency, integrity, traceability, and control.Configurations include products and their product configuration information.	3
14	Information management process	The purpose of the information management process is to generate, obtain, confirm, transform, retain,retrieve, disseminate, and dispose of information for designated stakeholders.Information management plans, executes, and controls the provision of information for designatedstakeholders that is unambiguous, complete, verifiable, consistent, modifiable, traceable, andpresentable. Information includes technical, project, organizational, agreement, and user information.Information is often derived from data records of the organization, system, process, or project.	3
15	Measurement process	The purpose of the measurement process is to collect, analyse, and report objective data and informationto support effective management and address information needs about the products, services, andprocesses.	3
16	Quality assurance process	The purpose of the quality assurance process is to help ensure the effective application of theorganization’s quality management process to the project.QA focuses on providing confidence that quality requirements are fulfilled. Proactive analysis of theproject life cycle processes and outputs is performed to help ensure that the product being producedor the service being developed is of the desired quality and that organization and project policies andprocedures are followed.	3
17	Business or mission analysis process	The purpose of the business or mission analysis process is to define the overall strategic problemor opportunity, characterize the solution space, and determine potential solution class(es) that canaddress a problem or take advantage of an opportunity	4
27	Validation process	The purpose of the validation process is to provide objective evidence that the system, when in use,fulfils its business or mission objectives and stakeholder needs and requirements, achieving itsintended use in its intended operational environment.The objective of validating a system, system element, or artefact is to acquire confidence in its ability tomeet validation criteria. Validation is confirmed by stakeholders. This process provides the necessaryinformation so that identified anomalies can be resolved by the appropriate technical process wherethe anomaly was created.	4
18	Stakeholder needs and requirements definition process	The purpose of the stakeholder needs and requirements definition process is to define the stakeholderneeds and requirements for a system that can provide the capabilities needed by users and otherstakeholders in a defined environment.It identifies stakeholders, or stakeholder classes, involved with the system throughout its life cycle, andtheir needs. It analyses and transforms these needs into a common set of stakeholder requirementsthat express the intended interaction the system will have with its operational environment and thatare the reference against which each resulting operational capability is validated. The stakeholderrequirements are defined considering the context of the SoI, which includes the interoperatingsystems and enabling systems. This also includes consideration of laws and regulations, environmentalrestrictions, and ethical values.	4
19	System requirements definition process	The purpose of the system requirements definition process is to transform the stakeholder, useroriented view of desired capabilities into a technical view of a solution that meets the operational needsof the user.This process creates a set of measurable system requirements that specify, from the supplier’sperspective, what characteristics, attributes, and functional and performance requirements the systemis to possess, to satisfy stakeholder requirements. As far as constraints permit, the requirements shouldnot imply any specific implementation.	4
20	System architecture definition process	The purpose of the system architecture definition process is to generate system architecturealternatives, select one or more alternative(s) that address stakeholder concerns and systemrequirements, and express this in consistent views and models.The system architecture definition activities define a solution based on principles, concepts, andproperties logically related to and consistent with each other. The solution architecture has features,properties, and characteristics which satisfy, as far as possible, the problem or opportunity expressedby a set of system requirements (traceable to mission, business and stakeholder requirements) and lifecycle concepts (e.g. operational, support).This process transforms related architectures (e.g. strategic, enterprise, reference, and SoSarchitectures), organizational and project policies and directives, life cycle concepts and constraints,stakeholder concerns and requirements, and system requirements and constraints into the fundamental concepts and properties of the system and the governing principles for evolution of the system and itsrelated life cycle processes.	4
21	Design definition process	The purpose of the design definition process is to provide sufficient detailed data and informationabout the system and its elements to realise the solution in accordance with the system requirementsand architecture.This process transforms architecture and requirements into a design of the system that can be realised.This process results in sufficiently detailed data and information about the system and its elements toenable implementation consistent with architectural entities defined in models and views of the systemarchitecture, in conformance with applicable system requirements, and in alignment with designguidelines and standards adopted by the organization or project.	4
22	System analysis process	The purpose of the system analysis process is to provide a rigorous basis of data and information fortechnical understanding to aid decision-making and technical assessments across the life cycle.System analysis covers a wide range of differing analytic functions, levels of complexity, and levels ofrigor. It is used to provide input for diverse technical assessments and analytical needs concerningoperational concepts, determination of requirement values, resolution of requirements conflicts,assessment of alternative architectures or system elements, performance and risk analyses, andevaluation of engineering strategies (integration, verification, validation, and maintenance). Formalityand rigor of the analysis will depend on the criticality of the information needed or artefact supported,the amount of information/data available, the size of the project, and the schedule for the results.	4
23	Implementation process	The purpose of the implementation process is to realise a specified system element.This process transforms requirements, architecture, and design, including interfaces, into actions thatcreate a system element according to the practices of the selected implementation technology, usingappropriate technical specialties or disciplines. This process results in a system element that satisfies specified system requirements (including allocated and derived requirements), architecture, anddesign.For system elements that need to be manufactured, after the definition of system element is elaboratedto a point that it can be built, a manufacturing approach or procedure is developed or adapted accordingthe system element definition and the desired production rate. The manufacturing of the systemelements is then performed over the time with quality control and production optimisation.	4
24	Integration process	The purpose of the integration process is to synthesize a set of system elements into a realised systemthat satisfies the system requirements.This process encompasses planning for, preparing for, and aggregating a progressively more completeset of system elements or artefacts. Interfaces are identified and activated to enable interoperation andsubsequent verification and possibly validation of the requirements (including characteristics) of thesystem elements or elements as intended. This process also connects and checks out interfaces of theSoI with enabling systems for which there is direct interaction.	4
25	Verification process	The purpose of the verification process is to provide objective evidence that a system, system element,or artefact fulfils its specified requirements and characteristics.The verification process identifies the anomalies in any artefact (e.g. system requirements, architecturedescription, or design description), implemented system elements, or life cycle processes usingappropriate methods, techniques, standards, or rules. This process provides the necessary informationto determine resolution of identified anomalies.	4
26	Transition process	The purpose of the transition process is to establish a capability for a system to provide servicesspecified by stakeholder requirements in the operational environment.This process moves the system in an orderly, planned manner to be operable in the intendedenvironment, which may be a new or changed environment, e.g., operations or validation. As a result ofthe transition, the system is functional and compatible with enabling, interfacing, and interoperatingsystems in the environment. It installs a verified system, together with relevant enabling systems(e.g. planning system, support system, operator training system, user training system), as defined in agreements. The transition process can be used every time the system or system elements aretransitioned from one entity or environment to another	4
28	Operation process	The purpose of the operation process is to use the system to provide its products or services.This process establishes requirements for and assigns personnel to operate the system, and monitorsthe products or services and operator-system performance. To sustain products or services, itidentifies and analyses operational anomalies in relation to agreements, stakeholder requirements, andorganizational constraints.	4
29	Maintenance process	The purpose of the maintenance process is to sustain the capability of the system to provide a productor service.This process monitors the system’s capability to deliver products or services, records incidents foranalysis, takes corrective, preventive, adaptive, additive, and perfective actions and confirms restoredcapability. The process includes packaging, handling, storage, and transportation for the requiredreplacement system elements. This is often required to support the objectives of the Integration andTransition processes, including required system and software assurance.The need for maintenance can arise from multiple causes other than failures, such as changes tointerfacing systems or infrastructure, evolving security threats, and technical obsolescence of systemelements and enabling systems over the system life cycle.	4
30	Disposal process	The purpose of the disposal process is to end the existence of a system element or system for aspecified intended use, appropriately handle replaced or retired elements, appropriately handle anywaste products, and to properly attend to identified critical disposal needs (e.g. per an agreement; perorganizational policy; or for environmental, legal, safety, or security aspects).This process deactivates, disassembles, and removes the system or any of its system elements from thespecific use. It addresses any waste products, consigning them to a final condition and returning theenvironment to its original or an acceptable condition. The waste products can be in-process resultingduring any life cycle stage, e.g. waste materials during fabrication. This process destroys, stores, orreclaims system elements and waste products in an environmentally sound manner, in accordance withlegislation, agreements, organizational constraints and stakeholder requirements. Disposal includespreventing expired, non-reusable, or inadequate elements from getting back into the supply chain.Where required, it maintains records in order that the health of operators and users, and the safety ofthe environment, can be monitored. When part of the system will continue to be in use in a modifiedform, the disposal process helps ensure the proper handling of the portion being disposed of.	4
\.


--
-- Data for Name: iso_system_life_cycle_processes; Type: TABLE DATA; Schema: public; Owner: adminderik
--

COPY public.iso_system_life_cycle_processes (id, name) FROM stdin;
1	Agreement processes
2	Organizational project-enabling processes
3	Technical management processes
4	Technical processes
\.


--
-- Data for Name: iso_tasks; Type: TABLE DATA; Schema: public; Owner: adminderik
--

COPY public.iso_tasks (id, name, activity_id) FROM stdin;
1	Define a strategy for how the acquisition will be conducted	1
2	Prepare a request for the supply of a product or service that includes the requirements	1
3	Communicate the request for the supply of a product or service to potential suppliers.	2
4	Select one or more suppliers.	2
5	Develop and approve an agreement with the supplier that includes acceptance criteria	3
6	Identify necessary changes to the agreement.	3
7	Evaluate impact of changes on the agreement	3
8	Update the agreement with the supplier, as necessary.	3
9	Assess the execution of the agreement.	4
10	Provide data needed by the supplier and resolve issues in a timely manner	4
11	Confirm that the delivered product or service complies with the agreement.	5
12	Provide payment or other agreed consideration.	5
13	Accept the product or service from the supplier, or other party, as directed by the agreement.	5
14	Close the agreement.	5
15	Determine the existence and identity of an acquirer who has a need for a product or service.	6
16	Define a supply strategy.	6
17	Evaluate a request for the supply of a product or service to determine feasibility and how to respond.	7
18	Prepare a response that satisfies the solicitation	7
19	Negotiate and approve an agreement with the acquirer that includes acceptance criteria.	8
20	Identify necessary changes to the agreement.	8
21	Evaluate impact of changes on the agreement.	8
22	Update the agreement with the acquirer, as necessary.	8
23	Execute the agreement in accordance with the established project plans.	9
24	Assess the execution of the agreement.	9
25	Deliver the product or service in accordance with the agreement criteria	10
26	Provide assistance to the acquirer in support of the delivered product or service, per theagreement.	10
27	Accept and acknowledge payment or other agreed consideration	10
28	Transfer the product or service to the acquirer, or other party, as directed by the agreement	10
29	Close the agreement.	10
30	Establish policies and life cycle procedures for process management and deployment that areconsistent with organizational strategies.	11
31	Establish the life cycle processes that implement the requirements of this document and thatare consistent with organizational strategies.	11
32	Define the roles, responsibilities, accountabilities, and authorities to facilitate implementationof life cycle processes and the strategic management of life cycles.	11
33	Define criteria that control progression through the life cycle.	11
34	Establish standard life cycle models for the organization that are comprised of stages anddefine the purpose and outcomes for each stage.	11
35	Monitor process execution across the organization.	12
36	Conduct periodic reviews of the life cycle models used by the projects.	12
37	Identify improvement opportunities from assessment results.	12
38	Prioritise and plan improvement opportunities.	13
39	Implement improvement opportunities and inform relevant stakeholders.	13
40	Define project infrastructure needs.	14
41	Identify, obtain, and provide infrastructure resources and services that are needed toimplement and support projects.	14
42	Evaluate the degree to which delivered infrastructure resources satisfy project needs.	15
43	Identify and provide improvements or changes to the infrastructure resources as needed.	15
44	Identify potential new or modified capabilities or missions.	16
45	Prioritise, select, and establish new strategic opportunities, ventures, or undertakings.	16
46	Define projects, accountabilities, and authorities	16
47	Identify the expected goals, objectives, and outcomes of each project	16
48	Identify and allocate resources for the achievement of project goals and objectives	16
49	Identify any multi-project interfaces and dependencies to be managed or supported by eachproject.	16
50	Specify the project reporting requirements and review milestones that govern the executionof each project.	16
51	Authorise each project to commence execution of project plans	16
52	Evaluate projects to confirm ongoing viability	17
53	Act to continue projects that are satisfactorily progressing.	17
54	Act to redirect projects that can be expected to progress satisfactorily with appropriate redirection	17
55	Where agreements permit, act to cancel or suspend projects whose disadvantages or risks tothe organization outweigh the benefits of continued investments.	18
56	After completion of the agreement for products and services, act to close the projects.	18
57	Identify skill needs based on current and expected projects	19
58	Identify and record skills of personnel.	19
59	Establish skills development strategy.	20
60	Obtain or develop training, education, or mentoring resources	20
61	Provide planned skill development.	20
62	Maintain records of skill development.	20
63	Obtain qualified personnel when skill deficits are identified.	21
64	Maintain and manage the pool of skilled personnel necessary to staff ongoing projects.	21
65	Make project assignments based on project and staff-development needs.	21
66	Motivate personnel, e.g. through career development and reward mechanisms.	21
67	Resolve personnel conflicts across or within projects	21
68	Establish quality management policies, objectives, and procedures.	22
69	Define responsibilities and authority for implementation of quality management	22
70	Define quality evaluation criteria and methods.	22
71	Provide resources and information for quality management.	22
72	Gather and analyse QA evaluation results, in accordance with the defined criteria.	23
73	Assess customer satisfaction.	23
149	Define a configuration management strategy.	43
435	Perform operational logistics.	105
74	Conduct periodic reviews of project QA activities for compliance with the quality managementpolicies, objectives, and procedures.	23
75	Monitor the status of quality improvements on processes, products, and services	23
76	Plan corrective actions when quality management objectives are not achieved.	24
77	Plan preventive actions when there is a sufficient risk that quality management objectives willnot be achieved.	24
78	Monitor corrective and preventive actions to completion and inform relevant stakeholders.	24
79	Define the knowledge management strategy.	25
80	Identify the knowledge, skills, and knowledge assets to be managed.	25
81	Identify projects that can benefit from the application of the knowledge, skills, and knowledgeassets.	25
82	Establish and maintain a classification for capturing and sharing knowledge and skills acrossthe organization.	26
83	Capture or acquire knowledge and skills.	26
84	Make knowledge and skills accessible to the organization.	26
85	Establish a taxonomy to organize knowledge assets.	27
86	Develop or acquire knowledge assets.	27
87	Make knowledge assets accessible to the organization	27
88	Maintain knowledge, skills, and knowledge assets.	28
89	Monitor and record the use of knowledge, skills, and knowledge assets.	28
90	Periodically reassess the currency of technology and market needs of the knowledge assets.	28
91	Identify the project objectives, assumptions, and constraints	29
92	Define the project scope as established in the agreement.	29
93	Define and maintain a life cycle model that is comprised of stages using the defined life cyclemodels of the organization.	29
94	Establish appropriate breakdown structures.	29
95	Define and maintain the life cycle processes that will be applied on the project	29
96	Define and maintain a schedule based on project objectives and work estimates	30
97	Define achievement criteria for the life cycle stage decision gates, delivery dates, and majordependencies on external inputs or outputs.	30
98	Define project performance criteria.	30
99	Define the costs and plan a budget.	30
100	Define roles, responsibilities, accountabilities, and authorities.	30
101	Define the infrastructure and services required	30
102	Plan the acquisition of materials and enabling system services supplied from outside theproject	30
103	Generate and communicate a plan for project and technical management and execution,including reviews.	30
104	Obtain authorization for the project.	31
105	Submit requests and obtain commitments for necessary resources to perform the project.	31
106	Implement project plans.	31
107	Define the project assessment and control strategy.	32
108	Assess alignment of project objectives and plans with the project context.	33
109	Assess management and technical plans against objectives to determine adequacy andfeasibility	33
110	Assess project and technical status against appropriate plans to determine actual and projectedcost, schedule, and performance variances.	33
111	Assess the adequacy of roles, responsibilities, accountabilities, and authorities.	33
112	Assess the adequacy and availability of resources.	33
113	Assess progress using measured achievement and milestone completion	33
114	Conduct required management and technical reviews, audits, and inspections.	33
115	Monitor critical processes and new technologies	33
116	Make recommendations based on measurement results and other project information	33
117	Record and provide status and findings from assessment tasks	33
118	Monitor process execution within the project	33
119	Initiate necessary actions needed to address identified issues.	34
120	Initiate necessary project replanning.	34
121	Initiate necessary change actions when there is a contractual change to cost, time, or qualitydue to the impact of an acquirer or supplier request.	34
122	Authorise the project to proceed toward the next milestone, decision gate, or event, if justified.	34
123	Define a decision management strategy.	35
124	Identify the circumstances and need for a decision.	35
125	Involve relevant stakeholders in the decision-making to draw on experience and knowledge	35
126	Select and declare the decision management strategy for each decision.	36
127	Determine desired outcomes and measurable selection criteria.	36
128	Identify the trade space and alternatives.	36
129	Evaluate each alternative against the criteria.	36
130	Determine preferred alternative for each decision.	37
131	Record the resolution, decision rationale, and assumptions	37
132	Record, track, evaluate, and report decisions	37
133	Define the risk management strategy	38
134	Define and record the context of the risk management process.	38
135	Define and record the risk thresholds and conditions.	39
136	Establish and maintain a risk profile	39
137	Periodically provide the relevant risk profile to stakeholders	39
138	Identify risks in the categories described in the risk management context.	40
139	Estimate the likelihood of occurrence and consequences of each identified risk	40
140	Evaluate each risk against its risk thresholds	40
141	Define and record recommended treatment strategies and measures for each risk that exceedsits risk threshold.	40
142	Identify recommended alternatives for risk treatment	41
143	Define measures for determining the effectiveness of risk treatments.	41
144	Implement selected risk treatments.	41
145	Coordinate management action for selected risk treatments.	41
146	Continually monitor all risks and the risk management context	42
147	Implement and monitor measures to evaluate the effectiveness of risk treatments.	42
148	Continually monitor for the emergence of new risks and sources throughout the life cycle.	42
150	Define the archive and retrieval approach for items under configuration management, as wellas configuration management artefacts and data.	43
151	Identify the system elements and artefacts that need to be under configuration management.	44
152	Identify the configuration data to be managed.	44
153	Establish unique identifiers for the items under configuration management.	44
154	Define baselines through the life cycle.	44
155	Obtain applicable stakeholder agreement to establish a baseline.	44
156	Approve and track system or system element releases.	44
157	Identify and record requests for change and requests for variance.	45
158	Coordinate, evaluate, and disposition requests for change and requests for variance	45
159	Submit requests for review and approval.	45
160	Track and manage approved changes to the baseline, requests for change, and requests forvariance.	45
161	Develop and maintain the configuration management status information, for system elements,baselines, and releases.	46
162	Capture, store, and report configuration management data.	46
163	Identify the need for configuration and configuration management verification activities andaudits.	47
164	Verify the product or service configuration meets the configuration requirements.	47
165	Monitor the incorporation of approved configuration changes.	47
166	Perform configuration and configuration management verification activities and audits to establish product baselines.	47
167	Record the configuration management audit and other configuration evaluation results anddisposition action items.	47
168	Define the strategy for information management.	48
169	Define the items of information that will be managed	48
170	Designate authorities and responsibilities for information management	48
171	Define the content, formats, and structure of information items.	48
172	Define information maintenance actions	48
173	Obtain, develop, or transform the identified items of information.	49
174	Maintain information items and their storage records, and record the status of information.	49
175	Publish, distribute, or provide access to information to designated stakeholders.	49
176	Archive designated information.	49
177	Dispose of unwanted, invalid, or unvalidated information.	49
178	Define the measurement strategy.	50
179	Describe the characteristics of the organization that are relevant to measurement	50
180	Identify and prioritise the information needs.	50
181	Select and specify measures that satisfy the information needs.	50
182	Define data collection, analysis, access, and reporting procedures.	50
183	Define criteria for evaluating the information items and the measurement process.	50
184	Identify and plan for the necessary enabling systems or services to be used	50
185	Obtain or acquire access to the enabling systems or services to be used.	50
186	Integrate procedures for data generation, collection, analysis, and reporting into the relevantprocesses.	51
187	Collect, store, and verify data.	51
188	Analyse data and develop information items.	51
189	Record results and inform the measurement users.	51
190	Define a QA strategy	52
191	Establish independence of QA from other life cycle processes	52
192	Evaluate products and services for conformance to established criteria, contracts, standards,and regulations.	53
193	Perform verification and validation of the outputs of the life cycle processes to determine conformance to specified requirements.	53
194	Evaluate project life cycle processes for conformance	54
195	Evaluate tools and environments that support or automate the process for conformance.	54
196	Evaluate supplier processes for conformance to process requirements.	54
197	Create records and reports related to QA activities	55
198	Maintain, store, and distribute records and reports.	55
199	Identify incidents and problems associated with product, service, and process evaluations.	55
200	Incidents are recorded, analysed, and classified.	56
201	Incidents are resolved or elevated to problems	56
202	Problems are recorded, analysed, and classified	56
203	Treatments for problems are prioritised and implementation is tracked	56
204	Trends in incidents and problems are noted and analysed	56
205	Stakeholders are informed of the status of incidents and problems	56
206	Incidents and problems are tracked to closure.	56
207	Review changes to the organization strategy and concept of operations to identify potentialproblems and opportunities with respect to desired organization mission(s), vision, goals, andobjectives.	57
208	Define the business or mission analysis strategy.	57
209	Identify and plan for the necessary enabling systems or services needed to support business ormission analysis.	57
210	Obtain or acquire access to the enabling systems or services to be used.	57
211	Analyse the problems and opportunities in the context of relevant trade-space factors.	58
212	Define the mission, business, or operational problem or opportunity to be addressed by asolution.	58
213	Prioritise the potential problem or opportunity against other business needs.	58
214	Define preliminary operational concepts and other life cycle concepts.	59
215	Identify alternative solution classes that span the potential solution space.	59
216	Assess each alternative solution class.	60
217	Select the preferred alternative solution class(es).	60
218	Provide feedback to strategic level life cycle concepts to reflect the selected solution class(es).	60
219	Record key business or mission analysis decisions and the rationale.	61
220	Maintain traceability of business or mission analysis and the alternative solution class(es)	61
221	Provide key artefacts that have been selected for baselines.	61
292	Provide key artefacts that have been selected for baselines.	76
222	Identify the stakeholders who have an interest in the solution throughout its life cycle.	62
223	Define the stakeholder needs and requirements definition strategy	62
224	Identify and plan for the necessary enabling systems or services needed to support stakeholderneeds and requirements definition.	62
225	Obtain or acquire access to the enabling systems or services to be used.	62
226	Define context of use within the concept of operations, the preliminary life cycle concepts, andthe preferred solution class(es).	63
227	Define the context of use and a set of scenarios (or use cases) to identify all required capabilitiesthat correspond to anticipated operational concepts and other life cycle concepts.	63
228	Characterize the operational environment and the intended users.	63
229	Identify interactions between users and the system and the factors affecting the interactions.	63
230	Identify all interface boundaries across which the SoI interacts with external systems.	63
231	Identify the constraints on a system solution.	63
232	Identify stakeholder needs within the constraints imposed by the life cycle concepts.	64
233	Prioritise and down-select needs.	64
234	Record the stakeholder needs and rationale.	64
235	Identify the stakeholder requirements and functions that relate to critical quality characteristics,such as assurance, safety, security, environment, or health.	65
236	Define stakeholder requirements, consistent with life cycle concepts, scenarios, interactions,constraints, critical quality characteristics, and SoS considerations.	65
237	Analyse the complete set of stakeholder requirements.	66
238	Define critical performance measures and quality characteristics that enable the assessment oftechnical achievement.	66
239	Feed back the analysed requirements to applicable stakeholders to validate that their needsand expectations have been adequately captured and expressed.	66
240	Resolve stakeholder requirements issues.	66
241	Obtain explicit agreement on the stakeholder requirements	67
242	Record key stakeholder requirements decisions and the rationale.	67
243	Maintain traceability of stakeholder needs and requirements.	67
244	Provide key artefacts that have been selected for baselines	67
245	Define the functional boundary of the system in terms of the behaviour and properties to beprovided.	68
246	Define the system requirements definition strategy.	68
247	Identify and plan for the necessary enabling systems or services needed to support systemrequirements definition.	68
248	Obtain or acquire access to the enabling systems or services to be used.	68
249	Define each function that the system is required to perform	69
250	Define necessary implementation constraints.	69
251	Identify system requirements that relate to risks, criticality of the system, or critical qualitycharacteristics.	69
252	Define system requirements and rationale	69
253	Analyse the complete set of system requirements.	70
254	Define critical performance measures that enable the assessment of technical achievement.	70
255	Feed back the analysed requirements to applicable stakeholders for review.	70
256	Resolve system requirements issues.	70
257	Obtain explicit agreement on the system requirements	71
258	Record key system requirements decisions and the rationale.	71
259	Maintain traceability of the system requirements.	71
260	Provide key artefacts that have been selected for baselines	71
261	Identify key milestones and decisions to be informed by the system architecture effort.	72
262	Define the strategy for system architecture definition.	72
263	Prepare for and plan the support to architecture governance and architecture managementefforts of the organization.	72
264	Identify and plan for the necessary enabling systems or services needed to support systemarchitecture definition efforts.	72
265	Obtain or acquire access to the enabling systems or services to be used in the system architecture definition efforts.	72
266	Characterize the problem space	73
267	Establish architecture objectives and critical success criteria	73
268	Synthesize potential solution(s) in the solution space	73
269	Characterize solutions and the trade space	73
270	Formulate candidate architecture(s)	73
271	Capture architecture concepts and properties	73
272	Relate the architecture to other architectures and to relevant affected entities to help ensureconsistency.	73
273	Coordinate use of architecture by intended users.	73
274	Determine evaluation objectives and criteria	74
275	Determine evaluation methods and integrate with evaluation objectives and criteria	74
276	Collect and review evaluation-related information.	74
277	Analyse architecture concepts and properties and assess the value of the architecture.	74
278	Combine the analyses and assessments into an overall evaluation to select a preferred systemarchitecture solution.	74
279	Characterize architecture(s) based on assessment results.	74
280	Formulate findings and recommendations.	74
281	Capture and communicate evaluation results.	74
282	Identify or develop architecture viewpoints and model kinds and legends that are governedby these architecture viewpoints.	75
283	Develop models and views of the architecture(s).	75
284	Relate the architecture to other architectures and to relevant affected entities to help ensureconsistency of the elaborated system architecture.	75
285	Assess the architecture elaboration.	75
286	Coordinate use of elaborated architecture by intended users	75
287	Monitor, assess, and control the system architecture definition activities and tasks.	76
288	Obtain agreement on the architecture definition.	76
289	Provide support to organizational architecture governance and architecture managementefforts.	76
290	Record key system architecture decisions and the rationale.	76
291	Maintain traceability of the system architecture.	76
293	Define the design definition strategy	77
294	Determine technologies required for each system element comprising the system	77
295	Determine the necessary categories of system characteristics represented in the design	77
296	Define principles for evolution of the design	77
297	Identify and plan for the necessary enabling systems or services needed to support designdefinition efforts.	77
298	Obtain or acquire access to the enabling systems or services to be used in the design definitionefforts.	77
299	Allocate system requirements to system elements.	78
300	Transform architectural entities and relationships into design elements.	78
301	Transform architectural characteristics into design characteristics.	78
302	Define the necessary design enablers.	78
303	Examine design alternatives.	78
304	Refine or define the interfaces between the system elements and with external entities	78
305	Establish the design artefacts.	78
306	Capture the design.	78
307	Analyse each system design alternative against criteria developed from expected designproperties and characteristics.	79
308	Assess each system design alternative for how well it meets the stakeholder requirements andsystem requirements.	79
309	Combine the analyses and assessments into an overall evaluation to select a preferred systemdesign solution.	79
310	Obtain agreement on the design.	80
311	Map design characteristics up to the system elements.	80
312	Record key design decisions and the rationale.	80
313	Maintain traceability of the system design.	80
314	Provide key artefacts that have been selected for baselines.	80
315	Define the system analysis strategy.	81
316	Identify the problem or question that requires system analysis.	81
317	Identify the stakeholders of the system analysis.	81
318	Define the scope, objectives, and level of fidelity of the system analysis	81
319	Select the system analysis methods.	81
320	Identify and plan for the necessary enabling systems or services needed to support systemanalysis	81
321	Obtain or acquire access to the enabling systems or services to be used	81
322	Identify and validate assumptions.	81
323	Plan for and collect the data and inputs needed for the analysis.	81
324	Apply the selected analysis methods to perform the required system analysis.	82
325	Review the analysis results for quality and validity.	82
326	Establish conclusions and recommendations.	82
327	Record the results of the system analysis,	82
328	Maintain traceability of system analysis results.	83
329	Provide key artefacts that have been selected for baselines.	83
330	Define an implementation strategy.	84
331	Identify constraints and objectives from implementation on the system requirements, architecture and design characteristics, or implementation techniques.	84
332	Identify and plan for the necessary enabling systems or services needed to support implementation.	84
333	Obtain or acquire access to the enabling systems or services, and materials to be used.	84
334	Realise or adapt system elements, according to the strategy, constraints, and defined implementation procedures.	85
335	Place the system element in a state for future use, as needed.	85
336	Record objective evidence from check-out that the system element meets requirements.	85
337	Record implementation results and any anomalies encountered	86
338	Maintain traceability of the implemented system elements	86
339	Provide key artefacts that have been selected for baselines.	86
340	Identify and define checkpoints for the correct activation and integrity of the interfaces andthe selected system functions as the system elements are synthesized.	87
341	Define the integration strategy.	87
342	Identify constraints and objectives from integration to be incorporated in the systemrequirements, architecture or design.	87
343	Identify and plan for the necessary enabling systems or services needed to support integration	87
344	Obtain or acquire access to the enabling systems or services, and materials to be used.	87
345	Check interface availability and conformance of the interfaces in accordance with interfacedefinitions and integration schedules.	88
346	Perform actions to address any conformance or availability issues.	88
347	Combine the implemented system elements or artefacts in accordance with planned sequences	88
348	Integrate system element configurations until the complete system is synthesized	88
349	Check for expected results of the interfaces, selected functions, and critical qualitycharacteristics.	88
350	Record integration results and any anomalies encountered.	89
351	Maintain traceability of the integrated system elements.	89
352	Provide key artefacts that have been selected for baselines	89
353	Identify the verification scope and corresponding verification actions.	90
354	Identify the constraints that potentially limit the feasibility of verification actions.	90
355	Select appropriate verification methods and associated success criteria for every verificationaction.	90
356	Define the verification strategy	90
357	Identify constraints and objectives from the verification strategy to be incorporated in thesystem requirements, architecture, and design.	90
358	Identify and plan for the necessary enabling systems or services needed to support verification.	90
359	Obtain or acquire access to the enabling systems or services to be used to support verification.	90
360	Define the verification procedures, each supporting one or a set of verification actions.	91
361	Perform the verification procedures.	91
362	Record verification results and any anomalies encountered.	92
363	Record operational incidents and problems during verification and track their resolution	92
364	Obtain agreement from the approval authority that the system, system element, or artefactmeets the specified requirements.	92
365	Maintain traceability for verification	92
366	Provide key artefacts that have been selected for baselines.	92
367	Define a transition strategy	93
368	Identify and define any facility or site changes needed.	93
369	Identify and arrange training of operators, users, and other stakeholders necessary for systemutilization and support.	93
370	Identify system constraints from transition to be incorporated in the system requirements,architecture or design.	93
371	Identify and plan for the necessary enabling systems or services needed to support transition	93
372	Obtain or acquire access to the enabling systems or services to be used	93
373	Identify and arrange shipping and receiving of system elements and enabling systems	93
374	Prepare the site of operation in accordance with installation requirements.	94
375	Deliver the system for installation at the correct location and time.	94
376	Install the system in its operational environment and interface to its environment.	94
377	Demonstrate proper installation of the system	94
378	Provide training of the operators, users, and other stakeholders necessary for systemutilization and support.	94
379	Perform activation and check-out of the system	94
380	Demonstrate the installed system is capable of delivering its required functions.	94
381	Demonstrate the functions provided by the system are sustainable by the enabling systems.	94
382	Review the system for operational readiness.	94
383	Commission the system for operations	94
384	Record transition results and any anomalies encountered.	95
385	Record operational incidents and problems during transition and track their resolution.	95
386	Maintain traceability of the transitioned system elements.	95
387	Provide key artefacts that have been selected for baselines.	95
388	Identify the validation scope and corresponding validation actions.	96
389	Identify the constraints that potentially limit the feasibility of validation actions.	96
390	Select appropriate validation methods and associated success criteria for each validationaction.	96
391	Define the validation strategy.	96
392	Identify system constraints from the validation strategy to be incorporated in the stakeholderneeds and requirements transformed from those needs.	96
393	Identify and plan for the necessary enabling systems or services needed to support validation.	96
394	Obtain or acquire access to the enabling systems or services to be used to support validation.	96
395	Define the validation procedures, each supporting one or a set of validation actions.	97
396	Perform the validation procedures.	97
397	Record validation results and any anomalies encountered	98
398	Record operational incidents and problems during validation and track their resolution	98
399	Obtain agreement that the validation criteria have been met.	98
400	Maintain traceability for validation.	98
401	Provide key artefacts that have been selected for baselines.	98
402	Define an operation strategy	99
403	Identify system constraints and objectives from operation to be incorporated in the systemrequirements, architecture, or design.	99
404	Identify and plan for the necessary enabling systems or services needed to support operation.	99
405	Obtain or acquire access to the enabling systems or services to be used	99
406	Identify or define training and qualification requirements to sustain the workforce needed forsystem operation.	99
407	Assign trained, qualified personnel to be operators.	99
408	Use the system in its intended operational environment	100
409	Apply materials and other resources, as required, to operate the system and sustain its productand service capabilities.	100
410	Monitor system operation	100
411	Use the measures defined in the strategy and analyse them to confirm that system performance is within acceptable parameters.	100
412	Identify and record when system or service performance is not within acceptable parameters.	100
413	Perform system contingency operations, if necessary.	100
414	Record results of operation and any anomalies encountered.	101
415	Record operational incidents and problems and track their resolution.	101
416	Maintain traceability for operations.	101
417	Provide key artefacts that have been selected for baselines	101
418	Provide assistance and consultation to stakeholders as requested.	102
419	Record and monitor requests and subsequent actions for support.	102
420	Determine the degree to which delivered products or services satisfy the needs of stakeholders.	102
421	Define a maintenance strategy.	103
422	Define a logistics strategy	103
423	Identify constraints and objectives from maintenance or logistics to be incorporated in thesystem requirements, architecture, or design.	103
424	Identify trade-offs such that the system and associated maintenance and logistics actionsresults in a solution that is affordable, operable, supportable, and sustainable.	103
425	Identify and plan for the necessary enabling systems, products, or services needed to supportmaintenance and logistics.	103
426	Obtain or acquire access to the enabling systems or services to be used.	103
427	Monitor and review stakeholder requirements as well as incident and problem reports toidentify future corrective, preventive, adaptive, additive, or perfective maintenance needs.	104
428	Record maintenance incidents and problems and track their resolution	104
429	Analyse the impact of changes introduced by maintenance actions on the system and systemelements.	104
430	Upon encountering faults that cause a system failure, restore the system to operational status.	104
431	Correct anomalies (defects, errors, and faults), replace, or upgrade system elements.	104
432	Perform preventive maintenance by replacing, upgrading, or servicing system elements priorto failure.	104
433	Perform adaptive, additive, or perfective maintenance as required.	104
434	Perform acquisition logistics.	105
436	Implement logistics actions needed during the life cycle	105
437	Confirm that logistics actions are implemented.	105
438	Record maintenance and logistics results and any anomalies encountered.	106
439	Record maintenance and logistics incidents and problems and track their resolution.	106
440	Identify and record trends of incidents, problems, and maintenance and logistics actions.	106
441	Maintain traceability for maintenance and logistics.	106
442	Provide key artefacts that have been selected for baselines.	106
443	Monitor customer satisfaction with the system, maintenance, and logistics	106
444	Define a disposal strategy for the system, to include each system element and any resultingwaste products.	107
445	Identify constraints and objectives from disposal on the system requirements, architectureand design characteristics, or implementation techniques.	107
446	Identify and plan for the necessary enabling systems or services needed to support disposal	107
447	Obtain or acquire access to the enabling systems or services to be used.	107
448	Specify containment facilities, storage locations, inspection criteria, and storage periods, if thesystem is to be stored.	107
449	Define preventive methods to preclude disposed elements and materials that should not berepurposed, reclaimed, or reused from re-entering the supply chain.	107
450	Deactivate the system or system element to prepare it for removal	108
451	Remove the system, system element, or waste material from use or production for appropriatedisposition and action.	108
452	Withdraw impacted operating staff from the system or system element and record relevantoperating knowledge.	108
453	Disassemble the system or system element into manageable elements to facilitate its removalfor reuse, recycling, reconditioning, overhaul, archiving, or destruction.	108
454	Handle system elements and their parts that are not intended for reuse in a manner that willhelp ensure they do not get back into the supply chain.	108
455	Conduct destruction of the system elements, as necessary, to reduce the amount of waste treatment or to make the waste easier to handle.	108
456	Confirm that no detrimental health, safety, security, and environmental factors exist followingdisposal.	109
457	Return the environment to its original state or to a state that is specified by agreement.	109
458	Identify and record information about the disposed system or system element.	109
459	Provide key artefacts that have been selected for baselines.	109
\.


--
-- Data for Name: new_survey_user; Type: TABLE DATA; Schema: public; Owner: adminderik
--

COPY public.new_survey_user (id, username, created_at, survey_completion_status) FROM stdin;
2	user92	2025-01-03 20:21:53.615569	t
3	user912	2025-01-05 13:28:58.648933	t
4	usertest1	2025-01-09 21:59:26.489606	f
5	usertester2	2025-01-09 22:06:10.627174	f
6	usertester3	2025-01-09 22:10:03.199772	f
7	usertester4	2025-01-09 22:14:11.857922	f
8	usertester5	2025-01-09 22:18:28.3324	f
9	usertester6	2025-01-09 22:24:54.546684	f
10	user7	2025-01-09 22:27:46.52882	f
11	usertester7	2025-01-09 22:28:01.961735	f
12	user11	2025-01-09 22:36:35.731972	f
13	user12	2025-01-09 22:42:31.31214	f
14	user13	2025-01-09 22:49:12.02191	f
15	vvfbf	2025-01-09 23:30:36.821697	f
16	fztd	2025-01-09 23:34:26.865773	f
17	giuzg	2025-01-09 23:38:10.960593	f
18	buzigh78	2025-01-09 23:43:49.456812	f
19	user20	2025-01-10 00:13:25.160527	f
20	user21	2025-01-10 00:16:49.575161	f
21	user22	2025-01-10 00:21:43.791431	f
22	user24	2025-01-10 00:24:27.683862	f
23	user25	2025-01-10 00:26:42.152933	f
24	user26	2025-01-10 00:34:58.147442	f
25	user27	2025-01-10 00:53:45.536156	f
26	user29	2025-01-10 00:57:53.413117	f
27	user30	2025-01-10 01:01:12.251055	f
28	user31	2025-01-10 01:05:33.676459	f
29	user9123	2025-01-14 19:51:06.599234	t
30	dercerlubbu	2025-01-14 20:05:48.973398	t
31	user91234567	2025-01-15 07:36:17.463896	f
32	derikroby	2025-01-15 18:52:57.399159	t
33	CeruDeru	2025-01-15 18:56:03.133767	t
34	CeruDeruc	2025-01-15 19:58:13.533313	t
35	Cerin1	2025-01-16 02:30:45.602407	t
36	dercerdercerder	2025-01-16 10:21:13.621025	t
37	Ok	2025-01-16 13:06:40.257737	f
38	1234	2025-01-16 13:07:27.013537	f
39	tester202	2025-01-16 13:30:56.252502	f
40	user201	2025-01-16 14:01:07.56154	f
41	user1028	2025-01-16 14:57:14.869326	t
42	user1025	2025-01-16 15:07:49.788662	f
43	user32	2025-01-30 22:49:36.161624	f
44	user655	2025-01-31 14:13:56.402444	f
45	user757	2025-01-31 15:23:13.556044	f
46	user888	2025-01-31 15:26:22.083697	f
47	derder	2025-02-04 08:39:26.547412	f
48	user65	2025-02-04 19:05:22.012914	t
49	user54	2025-02-04 19:48:44.434588	f
50	User654	2025-02-05 11:32:28.819318	f
51	User222	2025-02-05 11:40:12.928051	f
52	user65new	2025-02-05 22:20:42.4401	f
53	user45	2025-02-17 20:43:41.570807	t
54	12343	2025-02-17 23:33:33.398127	t
55	user34	2025-02-17 23:35:27.911561	t
56	testerr	2025-02-24 18:03:02.615659	t
57	tesrter543	2025-02-28 15:33:30.471243	f
58	tester434	2025-03-01 10:59:13.199287	t
59	5366	2025-03-03 13:35:38.461781	f
60	Hhjkmkm	2025-03-03 13:39:08.781451	f
61	12222	2025-03-03 13:40:39.586157	t
62	sddsdsd	2025-03-05 10:59:38.619069	f
63	RZ2025	2025-03-05 15:20:39.634358	t
64	testeruser12345	2025-03-06 09:40:41.655252	t
65	tester123456	2025-03-06 10:21:53.677651	t
67	hasuser	2025-03-06 14:17:26.350974	t
66	hahahauser	2025-03-06 14:16:31.653603	t
68	tester321	2025-03-06 14:45:31.568995	t
69	testfeedback	2025-03-06 14:53:41.284385	t
70	tester3111	2025-03-07 14:01:53.127554	t
71	dsd	2025-03-07 15:33:02.974774	f
72	dercerderder	2025-03-08 10:05:01.00337	t
73	enter123	2025-03-09 23:43:17.530702	f
74	sddsss	2025-03-10 22:49:57.263328	f
75	dsddssds	2025-03-11 10:01:32.483467	f
76	sddsds	2025-03-11 10:14:30.64537	f
1	se_surver_user_1	2025-03-12 18:17:38.594131	t
77	se_surver_user_77	2025-03-12 19:19:10.032927	t
78	se_surver_user_78	2025-03-12 19:32:20.702947	t
79	se_surver_user_79	2025-03-12 20:13:48.04233	f
80	se_surver_user_80	2025-03-12 20:16:24.330252	f
81	se_surver_user_81	2025-03-12 20:22:41.146533	f
82	se_surver_user_82	2025-03-12 20:27:05.777756	t
83	se_surver_user_83	2025-03-12 21:21:46.771535	t
\.


--
-- Data for Name: organization; Type: TABLE DATA; Schema: public; Owner: adminderik
--

COPY public.organization (id, organization_name, organization_public_key) FROM stdin;
1	Individual	singleuser
3	pmOne AG	pm1ag
12	Fraunhofer	fraunhofer
\.


--
-- Data for Name: process_competency_matrix; Type: TABLE DATA; Schema: public; Owner: adminderik
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
-- Data for Name: role_cluster; Type: TABLE DATA; Schema: public; Owner: adminderik
--

COPY public.role_cluster (id, role_cluster_name, role_cluster_description) FROM stdin;
1	Customer	Represents the party that orders or uses a service (e.g., development order). The customer has influence on the design/technical execution of the system.
2	Customer Representative	Forms the interface between the customer and the company. The roles in this cluster form the voice for all customer-relevant information required for the project.
3	Project Manager	Is responsible for the planning and coordination on the project side. The roles assume responsibility for achieving the project goals and monitoring the resources (time, costs, personnel) within a time-limited framework and also have a moderating role in conflicts and disputes.
5	Specialist Developer	Includes the various specialist areas, e.g., software, hardware, etc. They develop new technologies or realize the product/system on the basis of specifications from the system developer cluster.
6	Production Planner/Coordinator	Takes on the preparation of the product realization and the transfer to the customer.
7	Production Employee	Comprises the processes that are to be assigned to the implementation, assembly, and manufacture of the product through to goods issue and shipping. The individual system components are integrated into the overall system and verified with regard to their functionality.
8	Quality Engineer/Manager	Ensures that the company's quality standards are maintained in order to keep customer satisfaction high and ensure long-term competitiveness in the market. Close cooperation with the V&V operator, e.g., for the analysis of customer complaints and identification of the cause.
9	Verification and Validation (V&V) Operator	Covers the topics of system verification & validation. The involvement of this role cluster in the early phases of system development can ensure that the system is verifiable and validatable.
10	Service Technician	Deals with all service-related tasks at the customer's site, i.e., installation, commissioning, professional training of users, as well as classic service tasks such as maintenance and repairs, or the area of after-sales.
11	Process and Policy Manager	Is divided into a strategic and an operational level: On a strategic level, the process owner serves to develop internal guidelines in the development and creation or revision of process flows. On an operational level, the policy owner controls compliance with policies, laws, and framework conditions that must be taken into account and fulfilled.
12	Internal Support	Represents the advisory and supporting side during the development process within the project. A distinction is made between: - IT support: IT support provides and maintains the necessary IT infrastructure. - Qualification support: On the one hand, this provides support in the area of methods and, on the other hand, the qualification of the employees is individually ensured by means of specialized training. This can be done by the HR department, which also supports the project by acquiring suitable employees. - Systems Engineering (SE) support: The SE support offers separate support with regard to SE methods and handling of SE tools. This offers assistance in order to impart the necessary knowledge in the SE procedure.
13	Innovation Management	Focuses on the commercially successful implementation of products or services, but also new business models or processes.
14	Management	Forms the group of decision-makers and is represented by the management or department management. The cluster keeps an eye on the company's goals, visions, and values. Since the opinion of the cluster is crucial for project progress, management is an important stakeholder in every respect.
4	System Engineer	Has the overview from requirements to the decomposition of the system to the interfaces and the associated system elements (external to the system environment and internal between the elements). The system developer is responsible for integration planning and consults with the appropriate subject matter experts.
40004	Unknown_Role	We use a RAG pipeline on ISO document to find out the role user performs
70007	All_Roles	The user is taking survey for all roles to find which fits him/her the best
\.


--
-- Data for Name: role_competency_matrix; Type: TABLE DATA; Schema: public; Owner: adminderik
--

COPY public.role_competency_matrix (id, role_cluster_id, competency_id, role_competency_value, organization_id) FROM stdin;
2241	5	13	2	1
2242	1	8	1	1
2243	7	8	2	1
2244	6	18	2	1
2245	2	13	2	1
2246	7	14	0	1
2247	3	12	4	1
2248	3	15	2	1
2249	13	11	4	1
2250	9	7	2	1
2251	1	1	2	1
2252	4	8	2	1
2253	5	4	4	1
2254	3	13	4	1
2255	6	9	2	1
2256	9	4	4	1
2257	6	15	2	1
2258	2	17	1	1
2259	4	13	4	1
2260	1	11	1	1
2261	1	9	2	1
2262	9	17	2	1
2263	4	1	4	1
2264	6	16	2	1
2265	6	12	2	1
2266	13	5	4	1
2267	8	12	2	1
2268	5	15	4	1
2269	14	14	2	1
2270	1	5	2	1
2271	12	6	2	1
2272	9	15	2	1
2273	7	7	4	1
2274	12	15	2	1
2275	3	9	4	1
2276	10	8	0	1
2277	3	17	2	1
2278	14	15	1	1
2279	9	11	2	1
2280	14	13	1	1
2281	7	1	2	1
2282	11	14	6	1
2283	5	16	2	1
2284	3	1	4	1
2285	11	18	6	1
2286	14	5	2	1
2287	5	12	2	1
2288	7	6	2	1
2289	9	5	4	1
2290	7	4	2	1
2291	5	11	2	1
2292	6	5	2	1
2293	4	9	4	1
2294	4	7	4	1
2295	7	17	2	1
2296	11	8	6	1
2297	9	16	4	1
2298	14	4	4	1
2299	4	5	4	1
2300	11	6	6	1
2301	8	8	2	1
2302	9	10	4	1
2303	11	9	6	1
2304	7	11	2	1
2305	5	9	4	1
2306	12	12	4	1
2307	13	12	2	1
2308	11	12	6	1
2309	1	13	2	1
2310	3	11	4	1
2311	14	18	2	1
2312	8	13	1	1
2313	4	10	2	1
2314	5	5	4	1
2315	9	6	4	1
2316	14	12	1	1
2317	3	4	4	1
2318	6	10	1	1
2319	11	5	6	1
2320	14	17	1	1
2321	5	14	2	1
2322	9	18	4	1
2323	4	17	2	1
2324	11	11	6	1
2325	12	1	2	1
2326	2	12	2	1
2327	8	6	2	1
2328	4	12	2	1
2329	13	9	4	1
2330	10	17	4	1
2331	6	7	4	1
2332	1	15	0	1
2333	10	16	0	1
2334	11	16	6	1
2335	3	14	2	1
2336	2	18	4	1
2337	2	9	4	1
2338	10	7	4	1
2339	8	5	1	1
2340	12	18	2	1
2341	8	14	4	1
2342	4	18	4	1
2343	4	14	4	1
2344	11	17	6	1
2345	10	4	2	1
2346	10	13	2	1
2347	1	4	2	1
2348	6	11	2	1
2349	2	14	4	1
2350	1	6	2	1
2351	11	15	6	1
2352	12	16	2	1
2353	9	9	4	1
2354	6	6	2	1
2355	14	7	2	1
2356	4	6	4	1
2357	10	12	2	1
2358	8	9	2	1
2359	8	15	4	1
2360	9	14	4	1
2361	6	13	2	1
2362	7	12	2	1
2363	14	9	2	1
2364	10	15	0	1
2365	1	10	0	1
2366	4	4	4	1
2367	12	13	2	1
2368	8	18	2	1
2369	5	8	2	1
2370	9	1	4	1
2371	11	13	6	1
2372	2	6	4	1
2373	11	1	6	1
2374	14	8	2	1
2375	10	10	0	1
2376	7	15	2	1
2377	5	1	2	1
2378	12	5	1	1
2379	13	4	4	1
2380	12	17	2	1
2381	2	4	4	1
2382	2	8	2	1
2383	1	17	4	1
2384	6	8	2	1
2385	5	6	4	1
2386	13	16	2	1
2387	8	4	2	1
2388	10	1	2	1
2389	5	10	2	1
2390	12	14	2	1
2391	8	11	2	1
2392	13	6	4	1
2393	12	9	2	1
2394	8	7	2	1
2395	9	13	2	1
2396	4	16	2	1
2397	3	5	4	1
2398	1	12	2	1
2399	14	10	2	1
2400	10	18	2	1
2401	1	16	2	1
2402	12	11	2	1
2403	4	11	4	1
2404	13	13	2	1
2405	1	7	4	1
2406	4	15	4	1
2407	2	10	2	1
2408	3	16	2	1
2409	10	14	2	1
2410	7	5	2	1
2411	9	12	2	1
2412	10	6	2	1
2413	2	16	2	1
2414	6	17	1	1
2415	8	16	2	1
2416	2	11	4	1
2417	12	7	2	1
2418	13	18	4	1
2419	3	18	4	1
2420	11	4	6	1
2421	14	1	2	1
2422	13	17	0	1
2423	10	5	2	1
2424	3	6	4	1
2425	13	10	2	1
2426	3	7	4	1
2427	13	15	0	1
2428	8	10	4	1
2429	6	4	2	1
2430	11	7	6	1
2431	1	18	2	1
2432	12	10	2	1
2433	2	1	4	1
2434	11	10	6	1
2435	10	11	0	1
2436	10	9	2	1
2437	7	18	2	1
2438	3	10	4	1
2439	13	14	4	1
2440	6	1	2	1
2441	13	1	4	1
2442	7	10	0	1
2443	7	13	4	1
2444	7	9	4	1
2445	5	7	2	1
2446	13	7	4	1
2447	5	18	4	1
2448	2	15	2	1
2449	9	8	2	1
2450	5	17	1	1
2451	12	8	2	1
2452	13	8	4	1
2453	2	5	4	1
2454	1	14	2	1
2455	3	8	4	1
2456	6	14	2	1
2457	8	1	2	1
2458	14	11	4	1
2459	14	16	1	1
2460	14	6	2	1
2461	8	17	1	1
2462	2	7	4	1
2463	7	16	4	1
2464	12	4	2	1
2465	5	13	2	3
2466	1	8	1	3
2467	7	8	2	3
2468	6	18	2	3
2469	2	13	2	3
2470	7	14	0	3
2471	3	12	4	3
2472	3	15	2	3
2473	13	11	4	3
2474	9	7	2	3
2475	1	1	2	3
2476	4	8	2	3
2477	5	4	4	3
2478	3	13	4	3
2479	6	9	2	3
2480	9	4	4	3
2481	6	15	2	3
2482	2	17	1	3
2483	4	13	4	3
2484	1	11	1	3
2485	1	9	2	3
2486	9	17	2	3
2487	4	1	4	3
2488	6	16	2	3
2489	6	12	2	3
2490	13	5	4	3
2491	8	12	2	3
2492	5	15	4	3
2493	14	14	2	3
2494	1	5	2	3
2495	12	6	2	3
2496	9	15	2	3
2497	7	7	4	3
2498	12	15	2	3
2499	3	9	4	3
2500	10	8	0	3
2501	3	17	2	3
2502	14	15	1	3
2503	9	11	2	3
2504	14	13	1	3
2505	7	1	2	3
2506	11	14	6	3
2507	5	16	2	3
2508	3	1	4	3
2509	11	18	6	3
2510	14	5	2	3
2511	5	12	2	3
2512	7	6	2	3
2513	9	5	4	3
2514	7	4	2	3
2515	5	11	2	3
2516	6	5	2	3
2517	4	9	4	3
2518	4	7	4	3
2519	7	17	2	3
2520	11	8	6	3
2521	9	16	4	3
2522	14	4	4	3
2523	4	5	4	3
2524	11	6	6	3
2525	8	8	2	3
2526	9	10	4	3
2527	11	9	6	3
2528	7	11	2	3
2529	5	9	4	3
2530	12	12	4	3
2531	13	12	2	3
2532	11	12	6	3
2533	1	13	2	3
2534	3	11	4	3
2535	14	18	2	3
2536	8	13	1	3
2537	4	10	2	3
2538	5	5	4	3
2539	9	6	4	3
2540	14	12	1	3
2541	3	4	4	3
2542	6	10	1	3
2543	11	5	6	3
2544	14	17	1	3
2545	5	14	2	3
2546	9	18	4	3
2547	4	17	2	3
2548	11	11	6	3
2549	12	1	2	3
2550	2	12	2	3
2551	8	6	2	3
2552	4	12	2	3
2553	13	9	4	3
2554	10	17	4	3
2555	6	7	4	3
2556	1	15	0	3
2557	10	16	0	3
2558	11	16	6	3
2559	3	14	2	3
2560	2	18	4	3
2561	2	9	4	3
2562	10	7	4	3
2563	8	5	1	3
2564	12	18	2	3
2565	8	14	4	3
2566	4	18	4	3
2567	4	14	4	3
2568	11	17	6	3
2569	10	4	2	3
2570	10	13	2	3
2571	1	4	2	3
2572	6	11	2	3
2573	2	14	4	3
2574	1	6	2	3
2575	11	15	6	3
2576	12	16	2	3
2577	9	9	4	3
2578	6	6	2	3
2579	14	7	2	3
2580	4	6	4	3
2581	10	12	2	3
2582	8	9	2	3
2583	8	15	4	3
2584	9	14	4	3
2585	6	13	2	3
2586	7	12	2	3
2587	14	9	2	3
2588	10	15	0	3
2589	1	10	0	3
2590	4	4	4	3
2591	12	13	2	3
2592	8	18	2	3
2593	5	8	2	3
2594	9	1	4	3
2595	11	13	6	3
2596	2	6	4	3
2597	11	1	6	3
2598	14	8	2	3
2599	10	10	0	3
2600	7	15	2	3
2601	5	1	2	3
2602	12	5	1	3
2603	13	4	4	3
2604	12	17	2	3
2605	2	4	4	3
2606	2	8	2	3
2607	1	17	4	3
2608	6	8	2	3
2609	5	6	4	3
2610	13	16	2	3
2611	8	4	2	3
2612	10	1	2	3
2613	5	10	2	3
2614	12	14	2	3
2615	8	11	2	3
2616	13	6	4	3
2617	12	9	2	3
2618	8	7	2	3
2619	9	13	2	3
2620	4	16	2	3
2621	3	5	4	3
2622	1	12	2	3
2623	14	10	2	3
2624	10	18	2	3
2625	1	16	2	3
2626	12	11	2	3
2627	4	11	4	3
2628	13	13	2	3
2629	1	7	4	3
2630	4	15	4	3
2631	2	10	2	3
2632	3	16	2	3
2633	10	14	2	3
2634	7	5	2	3
2635	9	12	2	3
2636	10	6	2	3
2637	2	16	2	3
2638	6	17	1	3
2639	8	16	2	3
2640	2	11	4	3
2641	12	7	2	3
2642	13	18	4	3
2643	3	18	4	3
2644	11	4	6	3
2645	14	1	2	3
2646	13	17	0	3
2647	10	5	2	3
2648	3	6	4	3
2649	13	10	2	3
2650	3	7	4	3
2651	13	15	0	3
2652	8	10	4	3
2653	6	4	2	3
2654	11	7	6	3
2655	1	18	2	3
2656	12	10	2	3
2657	2	1	4	3
2658	11	10	6	3
2659	10	11	0	3
2660	10	9	2	3
2661	7	18	2	3
2662	3	10	4	3
2663	13	14	4	3
2664	6	1	2	3
2665	13	1	4	3
2666	7	10	0	3
2667	7	13	4	3
2668	7	9	4	3
2669	5	7	2	3
2670	13	7	4	3
2671	5	18	4	3
2672	2	15	2	3
2673	9	8	2	3
2674	5	17	1	3
2675	12	8	2	3
2676	13	8	4	3
2677	2	5	4	3
2678	1	14	2	3
2679	3	8	4	3
2680	6	14	2	3
2681	8	1	2	3
2682	14	11	4	3
2683	14	16	1	3
2684	14	6	2	3
2685	8	17	1	3
2686	2	7	4	3
2687	7	16	4	3
2688	12	4	2	3
2689	5	13	2	12
2690	1	8	1	12
2691	7	8	2	12
2692	6	18	2	12
2693	2	13	2	12
2694	7	14	0	12
2695	3	12	4	12
2696	3	15	2	12
2697	13	11	4	12
2698	9	7	2	12
2699	1	1	2	12
2700	4	8	2	12
2701	5	4	4	12
2702	3	13	4	12
2703	6	9	2	12
2704	9	4	4	12
2705	6	15	2	12
2706	2	17	1	12
2707	4	13	4	12
2708	1	11	1	12
2709	1	9	2	12
2710	9	17	2	12
2711	4	1	4	12
2712	6	16	2	12
2713	6	12	2	12
2714	13	5	4	12
2715	8	12	2	12
2716	5	15	4	12
2717	14	14	2	12
2718	1	5	2	12
2719	12	6	2	12
2720	9	15	2	12
2721	7	7	4	12
2722	12	15	2	12
2723	3	9	4	12
2724	10	8	0	12
2725	3	17	2	12
2726	14	15	1	12
2727	9	11	2	12
2728	14	13	1	12
2729	7	1	2	12
2730	11	14	6	12
2731	5	16	2	12
2732	3	1	4	12
2733	11	18	6	12
2734	14	5	2	12
2735	5	12	2	12
2736	7	6	2	12
2737	9	5	4	12
2738	7	4	2	12
2739	5	11	2	12
2740	6	5	2	12
2741	4	9	4	12
2742	4	7	4	12
2743	7	17	2	12
2744	11	8	6	12
2745	9	16	4	12
2746	14	4	4	12
2747	4	5	4	12
2748	11	6	6	12
2749	8	8	2	12
2750	9	10	4	12
2751	11	9	6	12
2752	7	11	2	12
2753	5	9	4	12
2754	12	12	4	12
2755	13	12	2	12
2756	11	12	6	12
2757	1	13	2	12
2758	3	11	4	12
2759	14	18	2	12
2760	8	13	1	12
2761	4	10	2	12
2762	5	5	4	12
2763	9	6	4	12
2764	14	12	1	12
2765	3	4	4	12
2766	6	10	1	12
2767	11	5	6	12
2768	14	17	1	12
2769	5	14	2	12
2770	9	18	4	12
2771	4	17	2	12
2772	11	11	6	12
2773	12	1	2	12
2774	2	12	2	12
2775	8	6	2	12
2776	4	12	2	12
2777	13	9	4	12
2778	10	17	4	12
2779	6	7	4	12
2780	1	15	0	12
2781	10	16	0	12
2782	11	16	6	12
2783	3	14	2	12
2784	2	18	4	12
2785	2	9	4	12
2786	10	7	4	12
2787	8	5	1	12
2788	12	18	2	12
2789	8	14	4	12
2790	4	18	4	12
2791	4	14	4	12
2792	11	17	6	12
2793	10	4	2	12
2794	10	13	2	12
2795	1	4	2	12
2796	6	11	2	12
2797	2	14	4	12
2798	1	6	2	12
2799	11	15	6	12
2800	12	16	2	12
2801	9	9	4	12
2802	6	6	2	12
2803	14	7	2	12
2804	4	6	4	12
2805	10	12	2	12
2806	8	9	2	12
2807	8	15	4	12
2808	9	14	4	12
2809	6	13	2	12
2810	7	12	2	12
2811	14	9	2	12
2812	10	15	0	12
2813	1	10	0	12
2814	4	4	4	12
2815	12	13	2	12
2816	8	18	2	12
2817	5	8	2	12
2818	9	1	4	12
2819	11	13	6	12
2820	2	6	4	12
2821	11	1	6	12
2822	14	8	2	12
2823	10	10	0	12
2824	7	15	2	12
2825	5	1	2	12
2826	12	5	1	12
2827	13	4	4	12
2828	12	17	2	12
2829	2	4	4	12
2830	2	8	2	12
2831	1	17	4	12
2832	6	8	2	12
2833	5	6	4	12
2834	13	16	2	12
2835	8	4	2	12
2836	10	1	2	12
2837	5	10	2	12
2838	12	14	2	12
2839	8	11	2	12
2840	13	6	4	12
2841	12	9	2	12
2842	8	7	2	12
2843	9	13	2	12
2844	4	16	2	12
2845	3	5	4	12
2846	1	12	2	12
2847	14	10	2	12
2848	10	18	2	12
2849	1	16	2	12
2850	12	11	2	12
2851	4	11	4	12
2852	13	13	2	12
2853	1	7	4	12
2854	4	15	4	12
2855	2	10	2	12
2856	3	16	2	12
2857	10	14	2	12
2858	7	5	2	12
2859	9	12	2	12
2860	10	6	2	12
2861	2	16	2	12
2862	6	17	1	12
2863	8	16	2	12
2864	2	11	4	12
2865	12	7	2	12
2866	13	18	4	12
2867	3	18	4	12
2868	11	4	6	12
2869	14	1	2	12
2870	13	17	0	12
2871	10	5	2	12
2872	3	6	4	12
2873	13	10	2	12
2874	3	7	4	12
2875	13	15	0	12
2876	8	10	4	12
2877	6	4	2	12
2878	11	7	6	12
2879	1	18	2	12
2880	12	10	2	12
2881	2	1	4	12
2882	11	10	6	12
2883	10	11	0	12
2884	10	9	2	12
2885	7	18	2	12
2886	3	10	4	12
2887	13	14	4	12
2888	6	1	2	12
2889	13	1	4	12
2890	7	10	0	12
2891	7	13	4	12
2892	7	9	4	12
2893	5	7	2	12
2894	13	7	4	12
2895	5	18	4	12
2896	2	15	2	12
2897	9	8	2	12
2898	5	17	1	12
2899	12	8	2	12
2900	13	8	4	12
2901	2	5	4	12
2902	1	14	2	12
2903	3	8	4	12
2904	6	14	2	12
2905	8	1	2	12
2906	14	11	4	12
2907	14	16	1	12
2908	14	6	2	12
2909	8	17	1	12
2910	2	7	4	12
2911	7	16	4	12
2912	12	4	2	12
\.


--
-- Data for Name: role_process_matrix; Type: TABLE DATA; Schema: public; Owner: adminderik
--

COPY public.role_process_matrix (id, role_cluster_id, iso_process_id, role_process_value, organization_id) FROM stdin;
1	1	1	0	1
2	1	2	0	1
3	1	3	0	1
4	1	4	0	1
5	1	5	0	1
6	1	6	0	1
7	1	7	0	1
8	1	8	0	1
9	1	9	0	1
10	1	10	0	1
11	1	11	0	1
12	1	12	0	1
13	1	13	0	1
14	1	14	0	1
15	1	15	0	1
16	1	16	0	1
17	1	17	0	1
18	1	18	0	1
19	1	19	0	1
20	1	20	0	1
21	1	21	0	1
22	1	22	0	1
23	1	23	0	1
24	1	24	0	1
25	1	25	0	1
26	1	26	2	1
27	1	27	1	1
28	1	28	2	1
29	1	29	2	1
30	1	30	2	1
31	2	1	0	1
32	2	2	2	1
33	2	3	0	1
34	2	4	0	1
35	2	5	1	1
36	2	6	0	1
37	2	7	0	1
38	2	8	0	1
39	2	9	0	1
40	2	10	0	1
41	2	11	2	1
42	2	12	1	1
43	2	13	1	1
44	2	14	1	1
45	2	15	0	1
46	2	16	1	1
47	2	17	2	1
48	2	18	2	1
49	2	19	2	1
50	2	20	1	1
51	2	21	1	1
52	2	22	0	1
53	2	23	0	1
54	2	24	1	1
55	2	25	1	1
56	2	26	2	1
57	2	27	1	1
58	2	28	0	1
59	2	29	0	1
60	2	30	0	1
61	3	1	0	1
62	3	2	1	1
63	3	3	0	1
64	3	4	0	1
65	3	5	1	1
66	3	6	0	1
67	3	7	0	1
68	3	8	0	1
69	3	9	2	1
70	3	10	2	1
71	3	11	2	1
72	3	12	2	1
73	3	13	2	1
74	3	14	2	1
75	3	15	0	1
76	3	16	1	1
77	3	17	0	1
78	3	18	0	1
79	3	19	0	1
80	3	20	0	1
81	3	21	0	1
82	3	22	0	1
83	3	23	0	1
84	3	24	0	1
85	3	25	0	1
86	3	26	0	1
87	3	27	0	1
88	3	28	0	1
89	3	29	0	1
90	3	30	0	1
91	12	1	0	1
92	12	2	0	1
93	12	3	1	1
94	12	4	2	1
95	12	5	0	1
96	12	6	2	1
97	12	7	0	1
98	12	8	2	1
99	12	9	0	1
100	12	10	0	1
101	12	11	0	1
102	12	12	0	1
103	12	13	0	1
104	12	14	0	1
105	12	15	0	1
106	12	16	0	1
107	12	17	0	1
108	12	18	0	1
109	12	19	0	1
110	12	20	0	1
111	12	21	0	1
112	12	22	0	1
113	12	23	0	1
114	12	24	0	1
115	12	25	0	1
116	12	26	0	1
117	12	27	0	1
118	12	28	0	1
119	12	29	0	1
120	12	30	0	1
121	11	1	3	1
122	11	2	3	1
123	11	3	3	1
124	11	4	3	1
125	11	5	3	1
126	11	6	3	1
127	11	7	3	1
128	11	8	3	1
129	11	9	3	1
130	11	10	3	1
131	11	11	3	1
132	11	12	3	1
133	11	13	3	1
134	11	14	3	1
135	11	15	3	1
136	11	16	3	1
137	11	17	3	1
138	11	18	3	1
139	11	19	3	1
140	11	20	3	1
141	11	21	3	1
142	11	22	3	1
143	11	23	3	1
144	11	24	3	1
145	11	25	3	1
146	11	26	3	1
147	11	27	3	1
148	11	28	3	1
149	11	29	3	1
150	11	30	3	1
151	4	1	1	1
152	4	2	1	1
153	4	3	0	1
154	4	4	0	1
155	4	5	0	1
156	4	6	0	1
157	4	7	0	1
158	4	8	0	1
159	4	9	0	1
160	4	10	0	1
161	4	11	2	1
162	4	12	2	1
163	4	13	2	1
164	4	14	1	1
165	4	15	0	1
166	4	16	0	1
167	4	17	0	1
168	4	18	1	1
169	4	19	2	1
170	4	20	2	1
171	4	21	2	1
172	4	22	1	1
173	4	23	0	1
174	4	24	0	1
175	4	25	1	1
176	4	26	0	1
177	4	27	0	1
178	4	28	1	1
179	4	29	1	1
180	4	30	0	1
181	5	1	1	1
182	5	2	0	1
183	5	3	0	1
184	5	4	0	1
185	5	5	0	1
186	5	6	0	1
187	5	7	0	1
188	5	8	0	1
189	5	9	0	1
190	5	10	0	1
191	5	11	1	1
192	5	12	1	1
193	5	13	1	1
194	5	14	1	1
195	5	15	1	1
196	5	16	0	1
197	5	17	0	1
198	5	18	0	1
199	5	19	1	1
200	5	20	1	1
201	5	21	2	1
202	5	22	0	1
203	5	23	2	1
204	5	24	0	1
205	5	25	1	1
206	5	26	0	1
207	5	27	0	1
208	5	28	0	1
209	5	29	0	1
210	5	30	0	1
211	6	1	2	1
212	6	2	1	1
213	6	3	0	1
214	6	4	0	1
215	6	5	0	1
216	6	6	0	1
217	6	7	0	1
218	6	8	0	1
219	6	9	0	1
220	6	10	0	1
221	6	11	1	1
222	6	12	1	1
223	6	13	0	1
224	6	14	0	1
225	6	15	0	1
226	6	16	0	1
227	6	17	0	1
228	6	18	0	1
229	6	19	0	1
230	6	20	0	1
231	6	21	0	1
232	6	22	0	1
233	6	23	2	1
234	6	24	1	1
235	6	25	0	1
236	6	26	2	1
237	6	27	0	1
238	6	28	0	1
239	6	29	0	1
240	6	30	0	1
241	9	1	1	1
242	9	2	0	1
243	9	3	0	1
244	9	4	0	1
245	9	5	0	1
246	9	6	0	1
247	9	7	1	1
248	9	8	0	1
249	9	9	0	1
250	9	10	0	1
251	9	11	1	1
252	9	12	0	1
253	9	13	1	1
254	9	14	1	1
255	9	15	2	1
256	9	16	2	1
257	9	17	0	1
258	9	18	1	1
259	9	19	1	1
260	9	20	0	1
261	9	21	0	1
262	9	22	2	1
263	9	23	0	1
264	9	24	1	1
265	9	25	2	1
266	9	26	0	1
267	9	27	2	1
268	9	28	0	1
269	9	29	0	1
270	9	30	0	1
271	7	1	0	1
272	7	2	0	1
273	7	3	0	1
274	7	4	0	1
275	7	5	0	1
276	7	6	0	1
277	7	7	0	1
278	7	8	0	1
279	7	9	0	1
280	7	10	0	1
281	7	11	0	1
282	7	12	0	1
283	7	13	0	1
284	7	14	0	1
285	7	15	0	1
286	7	16	0	1
287	7	17	0	1
288	7	18	0	1
289	7	19	0	1
290	7	20	0	1
291	7	21	0	1
292	7	22	0	1
293	7	23	2	1
294	7	24	2	1
295	7	25	0	1
296	7	26	0	1
297	7	27	0	1
298	7	28	0	1
299	7	29	0	1
300	7	30	0	1
301	10	1	0	1
302	10	2	1	1
303	10	3	0	1
304	10	4	0	1
305	10	5	0	1
306	10	6	0	1
307	10	7	0	1
308	10	8	0	1
309	10	9	0	1
310	10	10	0	1
311	10	11	0	1
312	10	12	0	1
313	10	13	0	1
314	10	14	0	1
315	10	15	0	1
316	10	16	0	1
317	10	17	0	1
318	10	18	0	1
319	10	19	0	1
320	10	20	0	1
321	10	21	0	1
322	10	22	0	1
323	10	23	0	1
324	10	24	0	1
325	10	25	0	1
326	10	26	2	1
327	10	27	0	1
328	10	28	1	1
329	10	29	2	1
330	10	30	1	1
331	8	1	0	1
332	8	2	0	1
333	8	3	0	1
334	8	4	0	1
335	8	5	0	1
336	8	6	0	1
337	8	7	2	1
338	8	8	0	1
339	8	9	0	1
340	8	10	0	1
341	8	11	0	1
342	8	12	1	1
343	8	13	0	1
344	8	14	0	1
345	8	15	0	1
346	8	16	2	1
347	8	17	0	1
348	8	18	0	1
349	8	19	0	1
350	8	20	0	1
351	8	21	0	1
352	8	22	0	1
353	8	23	0	1
354	8	24	0	1
355	8	25	1	1
356	8	26	0	1
357	8	27	1	1
358	8	28	0	1
359	8	29	0	1
360	8	30	0	1
361	13	1	0	1
362	13	2	0	1
363	13	3	0	1
364	13	4	0	1
365	13	5	2	1
366	13	6	0	1
367	13	7	0	1
368	13	8	0	1
369	13	9	0	1
370	13	10	0	1
371	13	11	1	1
372	13	12	0	1
373	13	13	0	1
374	13	14	0	1
375	13	15	0	1
376	13	16	0	1
377	13	17	2	1
378	13	18	0	1
379	13	19	0	1
380	13	20	0	1
381	13	21	0	1
382	13	22	0	1
383	13	23	0	1
384	13	24	0	1
385	13	25	0	1
386	13	26	0	1
387	13	27	0	1
388	13	28	0	1
389	13	29	0	1
390	13	30	0	1
391	14	1	0	1
392	14	2	0	1
393	14	3	0	1
394	14	4	0	1
395	14	5	1	1
396	14	6	1	1
397	14	7	0	1
398	14	8	0	1
399	14	9	0	1
400	14	10	1	1
401	14	11	2	1
402	14	12	0	1
403	14	13	0	1
404	14	14	0	1
405	14	15	0	1
406	14	16	0	1
407	14	17	1	1
408	14	18	0	1
409	14	19	0	1
410	14	20	0	1
411	14	21	0	1
412	14	22	0	1
413	14	23	0	1
414	14	24	0	1
415	14	25	0	1
416	14	26	0	1
417	14	27	0	1
418	14	28	0	1
419	14	29	0	1
420	14	30	0	1
421	1	1	0	3
422	1	2	0	3
423	1	3	0	3
424	1	4	0	3
425	1	5	0	3
426	1	6	0	3
427	1	7	0	3
428	1	8	0	3
429	1	9	0	3
430	1	10	0	3
431	1	11	0	3
432	1	12	0	3
433	1	13	0	3
434	1	14	0	3
435	1	15	0	3
436	1	16	0	3
437	1	17	0	3
438	1	18	0	3
439	1	19	0	3
440	1	20	0	3
441	1	21	0	3
442	1	22	0	3
443	1	23	0	3
444	1	24	0	3
445	1	25	0	3
446	1	26	2	3
447	1	27	1	3
448	1	28	2	3
449	1	29	2	3
450	1	30	2	3
451	2	1	0	3
452	2	2	2	3
453	2	3	0	3
454	2	4	0	3
455	2	5	1	3
456	2	6	0	3
457	2	7	0	3
458	2	8	0	3
459	2	9	0	3
460	2	10	0	3
461	2	11	2	3
462	2	12	1	3
463	2	13	1	3
464	2	14	1	3
465	2	15	0	3
466	2	16	1	3
467	2	17	2	3
468	2	18	2	3
469	2	19	2	3
470	2	20	1	3
471	2	21	1	3
472	2	22	0	3
473	2	23	0	3
474	2	24	1	3
475	2	25	1	3
476	2	26	2	3
477	2	27	1	3
478	2	28	0	3
479	2	29	0	3
480	2	30	0	3
481	3	1	0	3
482	3	2	1	3
483	3	3	0	3
484	3	4	0	3
485	3	5	1	3
486	3	6	0	3
487	3	7	0	3
488	3	8	0	3
489	3	9	2	3
490	3	10	2	3
491	3	11	2	3
492	3	12	2	3
493	3	13	2	3
494	3	14	2	3
495	3	15	0	3
496	3	16	1	3
497	3	17	0	3
498	3	18	0	3
499	3	19	0	3
500	3	20	0	3
501	3	21	0	3
502	3	22	0	3
503	3	23	0	3
504	3	24	0	3
505	3	25	0	3
506	3	26	0	3
507	3	27	0	3
508	3	28	0	3
509	3	29	0	3
510	3	30	0	3
511	12	1	0	3
512	12	2	0	3
513	12	3	1	3
514	12	4	2	3
515	12	5	0	3
516	12	6	2	3
517	12	7	0	3
518	12	8	2	3
519	12	9	0	3
520	12	10	0	3
521	12	11	0	3
522	12	12	0	3
523	12	13	0	3
524	12	14	0	3
525	12	15	0	3
526	12	16	0	3
527	12	17	0	3
528	12	18	0	3
529	12	19	0	3
530	12	20	0	3
531	12	21	0	3
532	12	22	0	3
533	12	23	0	3
534	12	24	0	3
535	12	25	0	3
536	12	26	0	3
537	12	27	0	3
538	12	28	0	3
539	12	29	0	3
540	12	30	0	3
541	11	1	3	3
542	11	2	3	3
543	11	3	3	3
544	11	4	3	3
545	11	5	3	3
546	11	6	3	3
547	11	7	3	3
548	11	8	3	3
549	11	9	3	3
550	11	10	3	3
551	11	11	3	3
552	11	12	3	3
553	11	13	3	3
554	11	14	3	3
555	11	15	3	3
556	11	16	3	3
557	11	17	3	3
558	11	18	3	3
559	11	19	3	3
560	11	20	3	3
561	11	21	3	3
562	11	22	3	3
563	11	23	3	3
564	11	24	3	3
565	11	25	3	3
566	11	26	3	3
567	11	27	3	3
568	11	28	3	3
569	11	29	3	3
570	11	30	3	3
571	4	1	1	3
572	4	2	1	3
573	4	3	0	3
574	4	4	0	3
575	4	5	0	3
576	4	6	0	3
577	4	7	0	3
578	4	8	0	3
579	4	9	0	3
580	4	10	0	3
581	4	11	2	3
582	4	12	2	3
583	4	13	2	3
584	4	14	1	3
585	4	15	0	3
586	4	16	0	3
587	4	17	0	3
588	4	18	1	3
589	4	19	2	3
590	4	20	2	3
591	4	21	2	3
592	4	22	1	3
593	4	23	0	3
594	4	24	0	3
595	4	25	1	3
596	4	26	0	3
597	4	27	0	3
598	4	28	1	3
599	4	29	1	3
600	4	30	0	3
601	5	1	1	3
602	5	2	0	3
603	5	3	0	3
604	5	4	0	3
605	5	5	0	3
606	5	6	0	3
607	5	7	0	3
608	5	8	0	3
609	5	9	0	3
610	5	10	0	3
611	5	11	1	3
612	5	12	1	3
613	5	13	1	3
614	5	14	1	3
615	5	15	1	3
616	5	16	0	3
617	5	17	0	3
618	5	18	0	3
619	5	19	1	3
620	5	20	1	3
621	5	21	2	3
622	5	22	0	3
623	5	23	2	3
624	5	24	0	3
625	5	25	1	3
626	5	26	0	3
627	5	27	0	3
628	5	28	0	3
629	5	29	0	3
630	5	30	0	3
631	6	1	2	3
632	6	2	1	3
633	6	3	0	3
634	6	4	0	3
635	6	5	0	3
636	6	6	0	3
637	6	7	0	3
638	6	8	0	3
639	6	9	0	3
640	6	10	0	3
641	6	11	1	3
642	6	12	1	3
643	6	13	0	3
644	6	14	0	3
645	6	15	0	3
646	6	16	0	3
647	6	17	0	3
648	6	18	0	3
649	6	19	0	3
650	6	20	0	3
651	6	21	0	3
652	6	22	0	3
653	6	23	2	3
654	6	24	1	3
655	6	25	0	3
656	6	26	2	3
657	6	27	0	3
658	6	28	0	3
659	6	29	0	3
660	6	30	0	3
661	9	1	1	3
662	9	2	0	3
663	9	3	0	3
664	9	4	0	3
665	9	5	0	3
666	9	6	0	3
667	9	7	1	3
668	9	8	0	3
669	9	9	0	3
670	9	10	0	3
671	9	11	1	3
672	9	12	0	3
673	9	13	1	3
674	9	14	1	3
675	9	15	2	3
676	9	16	2	3
677	9	17	0	3
678	9	18	1	3
679	9	19	1	3
680	9	20	0	3
681	9	21	0	3
682	9	22	2	3
683	9	23	0	3
684	9	24	1	3
685	9	25	2	3
686	9	26	0	3
687	9	27	2	3
688	9	28	0	3
689	9	29	0	3
690	9	30	0	3
691	7	1	0	3
692	7	2	0	3
693	7	3	0	3
694	7	4	0	3
695	7	5	0	3
696	7	6	0	3
697	7	7	0	3
698	7	8	0	3
699	7	9	0	3
700	7	10	0	3
701	7	11	0	3
702	7	12	0	3
703	7	13	0	3
704	7	14	0	3
705	7	15	0	3
706	7	16	0	3
707	7	17	0	3
708	7	18	0	3
709	7	19	0	3
710	7	20	0	3
711	7	21	0	3
712	7	22	0	3
713	7	23	2	3
714	7	24	2	3
715	7	25	0	3
716	7	26	0	3
717	7	27	0	3
718	7	28	0	3
719	7	29	0	3
720	7	30	0	3
721	10	1	0	3
722	10	2	1	3
723	10	3	0	3
724	10	4	0	3
725	10	5	0	3
726	10	6	0	3
727	10	7	0	3
728	10	8	0	3
729	10	9	0	3
730	10	10	0	3
731	10	11	0	3
732	10	12	0	3
733	10	13	0	3
734	10	14	0	3
735	10	15	0	3
736	10	16	0	3
737	10	17	0	3
738	10	18	0	3
739	10	19	0	3
740	10	20	0	3
741	10	21	0	3
742	10	22	0	3
743	10	23	0	3
744	10	24	0	3
745	10	25	0	3
746	10	26	2	3
747	10	27	0	3
748	10	28	1	3
749	10	29	2	3
750	10	30	1	3
751	8	1	0	3
752	8	2	0	3
753	8	3	0	3
754	8	4	0	3
755	8	5	0	3
756	8	6	0	3
757	8	7	2	3
758	8	8	0	3
759	8	9	0	3
760	8	10	0	3
761	8	11	0	3
762	8	12	1	3
763	8	13	0	3
764	8	14	0	3
765	8	15	0	3
766	8	16	2	3
767	8	17	0	3
768	8	18	0	3
769	8	19	0	3
770	8	20	0	3
771	8	21	0	3
772	8	22	0	3
773	8	23	0	3
774	8	24	0	3
775	8	25	1	3
776	8	26	0	3
777	8	27	1	3
778	8	28	0	3
779	8	29	0	3
780	8	30	0	3
781	13	1	0	3
782	13	2	0	3
783	13	3	0	3
784	13	4	0	3
785	13	5	2	3
786	13	6	0	3
787	13	7	0	3
788	13	8	0	3
789	13	9	0	3
790	13	10	0	3
791	13	11	1	3
792	13	12	0	3
793	13	13	0	3
794	13	14	0	3
795	13	15	0	3
796	13	16	0	3
797	13	17	2	3
798	13	18	0	3
799	13	19	0	3
800	13	20	0	3
801	13	21	0	3
802	13	22	0	3
803	13	23	0	3
804	13	24	0	3
805	13	25	0	3
806	13	26	0	3
807	13	27	0	3
808	13	28	0	3
809	13	29	0	3
810	13	30	0	3
811	14	1	0	3
812	14	2	0	3
813	14	3	0	3
814	14	4	0	3
815	14	5	1	3
816	14	6	1	3
817	14	7	0	3
818	14	8	0	3
819	14	9	0	3
820	14	10	1	3
821	14	11	2	3
822	14	12	0	3
823	14	13	0	3
824	14	14	0	3
825	14	15	0	3
826	14	16	0	3
827	14	17	1	3
828	14	18	0	3
829	14	19	0	3
830	14	20	0	3
831	14	21	0	3
832	14	22	0	3
833	14	23	0	3
834	14	24	0	3
835	14	25	0	3
836	14	26	0	3
837	14	27	0	3
838	14	28	0	3
839	14	29	0	3
840	14	30	0	3
1681	1	1	0	12
1682	1	2	0	12
1683	1	3	0	12
1684	1	4	0	12
1685	1	5	0	12
1686	1	6	0	12
1687	1	7	0	12
1688	1	8	0	12
1689	1	9	0	12
1690	1	10	0	12
1691	1	11	0	12
1692	1	12	0	12
1693	1	13	0	12
1694	1	14	0	12
1695	1	15	0	12
1696	1	16	0	12
1697	1	17	0	12
1698	1	18	0	12
1699	1	19	0	12
1700	1	20	0	12
1701	1	21	0	12
1702	1	22	0	12
1703	1	23	0	12
1704	1	24	0	12
1705	1	25	0	12
1706	1	26	2	12
1707	1	27	1	12
1708	1	28	2	12
1709	1	29	2	12
1710	1	30	2	12
1711	2	1	0	12
1712	2	2	2	12
1713	2	3	0	12
1714	2	4	0	12
1715	2	5	1	12
1716	2	6	0	12
1717	2	7	0	12
1718	2	8	0	12
1719	2	9	0	12
1720	2	10	0	12
1721	2	11	2	12
1722	2	12	1	12
1723	2	13	1	12
1724	2	14	1	12
1725	2	15	0	12
1726	2	16	1	12
1727	2	17	2	12
1728	2	18	2	12
1729	2	19	2	12
1730	2	20	1	12
1731	2	21	1	12
1732	2	22	0	12
1733	2	23	0	12
1734	2	24	1	12
1735	2	25	1	12
1736	2	26	2	12
1737	2	27	1	12
1738	2	28	0	12
1739	2	29	0	12
1740	2	30	0	12
1741	3	1	0	12
1742	3	2	1	12
1743	3	3	0	12
1744	3	4	0	12
1745	3	5	1	12
1746	3	6	0	12
1747	3	7	0	12
1748	3	8	0	12
1749	3	9	2	12
1750	3	10	2	12
1751	3	11	2	12
1752	3	12	2	12
1753	3	13	2	12
1754	3	14	2	12
1755	3	15	0	12
1756	3	16	1	12
1757	3	17	0	12
1758	3	18	0	12
1759	3	19	0	12
1760	3	20	0	12
1761	3	21	0	12
1762	3	22	0	12
1763	3	23	0	12
1764	3	24	0	12
1765	3	25	0	12
1766	3	26	0	12
1767	3	27	0	12
1768	3	28	0	12
1769	3	29	0	12
1770	3	30	0	12
1771	12	1	0	12
1772	12	2	0	12
1773	12	3	1	12
1774	12	4	2	12
1775	12	5	0	12
1776	12	6	2	12
1777	12	7	0	12
1778	12	8	2	12
1779	12	9	0	12
1780	12	10	0	12
1781	12	11	0	12
1782	12	12	0	12
1783	12	13	0	12
1784	12	14	0	12
1785	12	15	0	12
1786	12	16	0	12
1787	12	17	0	12
1788	12	18	0	12
1789	12	19	0	12
1790	12	20	0	12
1791	12	21	0	12
1792	12	22	0	12
1793	12	23	0	12
1794	12	24	0	12
1795	12	25	0	12
1796	12	26	0	12
1797	12	27	0	12
1798	12	28	0	12
1799	12	29	0	12
1800	12	30	0	12
1801	11	1	3	12
1802	11	2	3	12
1803	11	3	3	12
1804	11	4	3	12
1805	11	5	3	12
1806	11	6	3	12
1807	11	7	3	12
1808	11	8	3	12
1809	11	9	3	12
1810	11	10	3	12
1811	11	11	3	12
1812	11	12	3	12
1813	11	13	3	12
1814	11	14	3	12
1815	11	15	3	12
1816	11	16	3	12
1817	11	17	3	12
1818	11	18	3	12
1819	11	19	3	12
1820	11	20	3	12
1821	11	21	3	12
1822	11	22	3	12
1823	11	23	3	12
1824	11	24	3	12
1825	11	25	3	12
1826	11	26	3	12
1827	11	27	3	12
1828	11	28	3	12
1829	11	29	3	12
1830	11	30	3	12
1831	4	1	1	12
1832	4	2	1	12
1833	4	3	0	12
1834	4	4	0	12
1835	4	5	0	12
1836	4	6	0	12
1837	4	7	0	12
1838	4	8	0	12
1839	4	9	0	12
1840	4	10	0	12
1841	4	11	2	12
1842	4	12	2	12
1843	4	13	2	12
1844	4	14	1	12
1845	4	15	0	12
1846	4	16	0	12
1847	4	17	0	12
1848	4	18	1	12
1849	4	19	2	12
1850	4	20	2	12
1851	4	21	2	12
1852	4	22	1	12
1853	4	23	0	12
1854	4	24	0	12
1855	4	25	1	12
1856	4	26	0	12
1857	4	27	0	12
1858	4	28	1	12
1859	4	29	1	12
1860	4	30	0	12
1861	5	1	1	12
1862	5	2	0	12
1863	5	3	0	12
1864	5	4	0	12
1865	5	5	0	12
1866	5	6	0	12
1867	5	7	0	12
1868	5	8	0	12
1869	5	9	0	12
1870	5	10	0	12
1871	5	11	1	12
1872	5	12	1	12
1873	5	13	1	12
1874	5	14	1	12
1875	5	15	1	12
1876	5	16	0	12
1877	5	17	0	12
1878	5	18	0	12
1879	5	19	1	12
1880	5	20	1	12
1881	5	21	2	12
1882	5	22	0	12
1883	5	23	2	12
1884	5	24	0	12
1885	5	25	1	12
1886	5	26	0	12
1887	5	27	0	12
1888	5	28	0	12
1889	5	29	0	12
1890	5	30	0	12
1891	6	1	2	12
1892	6	2	1	12
1893	6	3	0	12
1894	6	4	0	12
1895	6	5	0	12
1896	6	6	0	12
1897	6	7	0	12
1898	6	8	0	12
1899	6	9	0	12
1900	6	10	0	12
1901	6	11	1	12
1902	6	12	1	12
1903	6	13	0	12
1904	6	14	0	12
1905	6	15	0	12
1906	6	16	0	12
1907	6	17	0	12
1908	6	18	0	12
1909	6	19	0	12
1910	6	20	0	12
1911	6	21	0	12
1912	6	22	0	12
1913	6	23	2	12
1914	6	24	1	12
1915	6	25	0	12
1916	6	26	2	12
1917	6	27	0	12
1918	6	28	0	12
1919	6	29	0	12
1920	6	30	0	12
1921	9	1	1	12
1922	9	2	0	12
1923	9	3	0	12
1924	9	4	0	12
1925	9	5	0	12
1926	9	6	0	12
1927	9	7	1	12
1928	9	8	0	12
1929	9	9	0	12
1930	9	10	0	12
1931	9	11	1	12
1932	9	12	0	12
1933	9	13	1	12
1934	9	14	1	12
1935	9	15	2	12
1936	9	16	2	12
1937	9	17	0	12
1938	9	18	1	12
1939	9	19	1	12
1940	9	20	0	12
1941	9	21	0	12
1942	9	22	2	12
1943	9	23	0	12
1944	9	24	1	12
1945	9	25	2	12
1946	9	26	0	12
1947	9	27	2	12
1948	9	28	0	12
1949	9	29	0	12
1950	9	30	0	12
1951	7	1	0	12
1952	7	2	0	12
1953	7	3	0	12
1954	7	4	0	12
1955	7	5	0	12
1956	7	6	0	12
1957	7	7	0	12
1958	7	8	0	12
1959	7	9	0	12
1960	7	10	0	12
1961	7	11	0	12
1962	7	12	0	12
1963	7	13	0	12
1964	7	14	0	12
1965	7	15	0	12
1966	7	16	0	12
1967	7	17	0	12
1968	7	18	0	12
1969	7	19	0	12
1970	7	20	0	12
1971	7	21	0	12
1972	7	22	0	12
1973	7	23	2	12
1974	7	24	2	12
1975	7	25	0	12
1976	7	26	0	12
1977	7	27	0	12
1978	7	28	0	12
1979	7	29	0	12
1980	7	30	0	12
1981	10	1	0	12
1982	10	2	1	12
1983	10	3	0	12
1984	10	4	0	12
1985	10	5	0	12
1986	10	6	0	12
1987	10	7	0	12
1988	10	8	0	12
1989	10	9	0	12
1990	10	10	0	12
1991	10	11	0	12
1992	10	12	0	12
1993	10	13	0	12
1994	10	14	0	12
1995	10	15	0	12
1996	10	16	0	12
1997	10	17	0	12
1998	10	18	0	12
1999	10	19	0	12
2000	10	20	0	12
2001	10	21	0	12
2002	10	22	0	12
2003	10	23	0	12
2004	10	24	0	12
2005	10	25	0	12
2006	10	26	2	12
2007	10	27	0	12
2008	10	28	1	12
2009	10	29	2	12
2010	10	30	1	12
2011	8	1	0	12
2012	8	2	0	12
2013	8	3	0	12
2014	8	4	0	12
2015	8	5	0	12
2016	8	6	0	12
2017	8	7	2	12
2018	8	8	0	12
2019	8	9	0	12
2020	8	10	0	12
2021	8	11	0	12
2022	8	12	1	12
2023	8	13	0	12
2024	8	14	0	12
2025	8	15	0	12
2026	8	16	2	12
2027	8	17	0	12
2028	8	18	0	12
2029	8	19	0	12
2030	8	20	0	12
2031	8	21	0	12
2032	8	22	0	12
2033	8	23	0	12
2034	8	24	0	12
2035	8	25	1	12
2036	8	26	0	12
2037	8	27	1	12
2038	8	28	0	12
2039	8	29	0	12
2040	8	30	0	12
2041	13	1	0	12
2042	13	2	0	12
2043	13	3	0	12
2044	13	4	0	12
2045	13	5	2	12
2046	13	6	0	12
2047	13	7	0	12
2048	13	8	0	12
2049	13	9	0	12
2050	13	10	0	12
2051	13	11	1	12
2052	13	12	0	12
2053	13	13	0	12
2054	13	14	0	12
2055	13	15	0	12
2056	13	16	0	12
2057	13	17	2	12
2058	13	18	0	12
2059	13	19	0	12
2060	13	20	0	12
2061	13	21	0	12
2062	13	22	0	12
2063	13	23	0	12
2064	13	24	0	12
2065	13	25	0	12
2066	13	26	0	12
2067	13	27	0	12
2068	13	28	0	12
2069	13	29	0	12
2070	13	30	0	12
2071	14	1	0	12
2072	14	2	0	12
2073	14	3	0	12
2074	14	4	0	12
2075	14	5	1	12
2076	14	6	1	12
2077	14	7	0	12
2078	14	8	0	12
2079	14	9	0	12
2080	14	10	1	12
2081	14	11	2	12
2082	14	12	0	12
2083	14	13	0	12
2084	14	14	0	12
2085	14	15	0	12
2086	14	16	0	12
2087	14	17	1	12
2088	14	18	0	12
2089	14	19	0	12
2090	14	20	0	12
2091	14	21	0	12
2092	14	22	0	12
2093	14	23	0	12
2094	14	24	0	12
2095	14	25	0	12
2096	14	26	0	12
2097	14	27	0	12
2098	14	28	0	12
2099	14	29	0	12
2100	14	30	0	12
\.


--
-- Data for Name: unknown_role_competency_matrix; Type: TABLE DATA; Schema: public; Owner: adminderik
--

COPY public.unknown_role_competency_matrix (id, user_name, competency_id, role_competency_value, organization_id) FROM stdin;
337	user9	4	3	1
338	user9	14	4	1
339	user9	17	3	1
340	user9	13	3	1
341	user9	10	4	1
342	user9	7	4	1
343	user9	9	6	1
344	user9	1	6	1
345	user9	5	4	1
346	user9	18	6	1
347	user9	16	6	1
348	user9	15	4	1
349	user9	6	3	1
350	user9	12	3	1
351	user9	11	3	1
352	user9	8	4	1
401	user11	4	4	1
402	user11	14	4	1
403	user11	17	2	1
404	user11	13	2	1
405	user11	10	4	1
406	user11	7	4	1
407	user11	9	4	1
408	user11	1	4	1
409	user11	5	4	1
410	user11	18	4	1
411	user11	16	2	1
412	user11	15	2	1
413	user11	6	4	1
414	user11	12	2	1
415	user11	11	2	1
416	user11	8	4	1
417	user12	4	4	1
418	user12	14	4	1
419	user12	17	0	1
420	user12	13	0	1
421	user12	10	4	1
422	user12	7	2	1
423	user12	9	2	1
424	user12	1	2	1
425	user12	5	2	1
426	user12	18	0	1
427	user12	16	0	1
428	user12	15	4	1
429	user12	6	4	1
430	user12	12	2	1
431	user12	11	4	1
432	user12	8	2	1
49	cerappuuu	4	4	1
50	cerappuuu	14	4	1
51	cerappuuu	17	3	1
52	cerappuuu	13	3	1
53	cerappuuu	10	4	1
54	cerappuuu	7	4	1
55	cerappuuu	9	6	1
56	cerappuuu	1	6	1
57	cerappuuu	5	4	1
58	cerappuuu	18	6	1
59	cerappuuu	16	6	1
60	cerappuuu	15	2	1
61	cerappuuu	6	4	1
62	cerappuuu	12	3	1
63	cerappuuu	11	3	1
64	cerappuuu	8	4	1
65	kolma	4	4	1
66	kolma	14	4	1
67	kolma	17	4	1
68	kolma	13	4	1
69	kolma	10	4	1
70	kolma	7	3	1
71	kolma	9	3	1
72	kolma	1	4	1
73	kolma	5	2	1
74	kolma	18	4	1
75	kolma	16	4	1
76	kolma	15	4	1
77	kolma	6	4	1
78	kolma	12	6	1
79	kolma	11	4	1
80	kolma	8	3	1
81	deru	4	4	1
82	deru	14	4	1
83	deru	17	4	1
84	deru	13	4	1
85	deru	10	4	1
86	deru	7	3	1
87	deru	9	3	1
88	deru	1	4	1
89	deru	5	2	1
90	deru	18	4	1
91	deru	16	4	1
92	deru	15	4	1
93	deru	6	4	1
94	deru	12	6	1
95	deru	11	4	1
96	deru	8	3	1
97	der	4	4	1
98	der	14	4	1
99	der	17	4	1
100	der	13	4	1
101	der	10	4	1
102	der	7	3	1
103	der	9	3	1
104	der	1	4	1
105	der	5	2	1
106	der	18	4	1
107	der	16	4	1
108	der	15	4	1
109	der	6	4	1
110	der	12	6	1
111	der	11	4	1
112	der	8	3	1
113	testuser	4	4	1
114	testuser	14	4	1
115	testuser	17	4	1
116	testuser	13	4	1
117	testuser	10	4	1
118	testuser	7	3	1
119	testuser	9	3	1
120	testuser	1	4	1
121	testuser	5	2	1
122	testuser	18	4	1
123	testuser	16	4	1
124	testuser	15	4	1
125	testuser	6	4	1
126	testuser	12	6	1
127	testuser	11	4	1
128	testuser	8	3	1
129	lahblah	4	2	1
130	lahblah	14	4	1
131	lahblah	17	2	1
132	lahblah	13	2	1
133	lahblah	10	4	1
134	lahblah	7	2	1
135	lahblah	9	4	1
136	lahblah	1	4	1
137	lahblah	5	2	1
138	lahblah	18	4	1
139	lahblah	16	4	1
140	lahblah	15	2	1
141	lahblah	6	2	1
142	lahblah	12	2	1
143	lahblah	11	2	1
144	lahblah	8	2	1
145	dinkan	4	2	1
146	dinkan	14	4	1
147	dinkan	17	2	1
148	dinkan	13	2	1
149	dinkan	10	4	1
449	fztd	4	2	1
450	fztd	14	2	1
451	fztd	17	4	1
150	dinkan	7	2	1
151	dinkan	9	4	1
152	dinkan	1	4	1
153	dinkan	5	2	1
154	dinkan	18	4	1
155	dinkan	16	4	1
156	dinkan	15	2	1
157	dinkan	6	2	1
158	dinkan	12	2	1
159	dinkan	11	2	1
160	dinkan	8	2	1
353	usertest1	4	6	1
354	usertest1	14	4	1
355	usertest1	17	2	1
356	usertest1	13	6	1
357	usertest1	10	4	1
358	usertest1	7	6	1
359	usertest1	9	6	1
360	usertest1	1	6	1
361	usertest1	5	6	1
362	usertest1	18	6	1
363	usertest1	16	3	1
364	usertest1	15	6	1
365	usertest1	6	6	1
366	usertest1	12	3	1
367	usertest1	11	6	1
368	usertest1	8	4	1
369	usertester2	4	3	1
370	usertester2	14	4	1
371	usertester2	17	3	1
372	usertester2	13	3	1
373	usertester2	10	4	1
374	usertester2	7	3	1
375	usertester2	9	6	1
376	usertester2	1	3	1
377	usertester2	5	3	1
378	usertester2	18	6	1
379	usertester2	16	6	1
380	usertester2	15	4	1
381	usertester2	6	3	1
382	usertester2	12	3	1
383	usertester2	11	3	1
384	usertester2	8	3	1
385	usertester3	4	2	1
386	usertester3	14	2	1
387	usertester3	17	4	1
388	usertester3	13	2	1
389	usertester3	10	4	1
390	usertester3	7	4	1
391	usertester3	9	4	1
392	usertester3	1	4	1
393	usertester3	5	4	1
394	usertester3	18	4	1
395	usertester3	16	2	1
396	usertester3	15	2	1
397	usertester3	6	2	1
398	usertester3	12	2	1
399	usertester3	11	2	1
400	usertester3	8	4	1
433	vvfbf	4	2	1
434	vvfbf	14	2	1
435	vvfbf	17	2	1
436	vvfbf	13	0	1
437	vvfbf	10	4	1
438	vvfbf	7	4	1
439	vvfbf	9	4	1
440	vvfbf	1	4	1
441	vvfbf	5	4	1
442	vvfbf	18	4	1
443	vvfbf	16	2	1
444	vvfbf	15	2	1
445	vvfbf	6	0	1
446	vvfbf	12	2	1
447	vvfbf	11	4	1
448	vvfbf	8	4	1
452	fztd	13	4	1
453	fztd	10	0	1
454	fztd	7	2	1
455	fztd	9	2	1
456	fztd	1	2	1
457	fztd	5	2	1
458	fztd	18	2	1
459	fztd	16	0	1
460	fztd	15	1	1
461	fztd	6	2	1
462	fztd	12	2	1
463	fztd	11	1	1
464	fztd	8	2	1
465	giuzg	4	6	1
466	giuzg	14	6	1
467	giuzg	17	4	1
468	giuzg	13	3	1
469	giuzg	10	4	1
470	giuzg	7	6	1
471	giuzg	9	6	1
472	giuzg	1	6	1
473	giuzg	5	6	1
474	giuzg	18	6	1
475	giuzg	16	3	1
476	giuzg	15	3	1
477	giuzg	6	6	1
478	giuzg	12	3	1
479	giuzg	11	3	1
480	giuzg	8	4	1
481	buzigh78	4	4	1
482	buzigh78	14	4	1
483	buzigh78	17	2	1
484	buzigh78	13	0	1
485	buzigh78	10	4	1
486	buzigh78	7	4	1
487	buzigh78	9	4	1
488	buzigh78	1	4	1
489	buzigh78	5	4	1
490	buzigh78	18	4	1
491	buzigh78	16	2	1
492	buzigh78	15	4	1
493	buzigh78	6	4	1
494	buzigh78	12	2	1
495	buzigh78	11	4	1
496	buzigh78	8	4	1
497	user20	4	6	1
498	user20	14	6	1
499	user20	17	2	1
500	user20	13	3	1
501	user20	10	4	1
502	user20	7	6	1
503	user20	9	6	1
504	user20	1	6	1
505	user20	5	6	1
506	user20	18	6	1
507	user20	16	3	1
508	user20	15	3	1
509	user20	6	6	1
510	user20	12	3	1
511	user20	11	3	1
512	user20	8	4	1
513	user21	4	2	1
514	user21	14	4	1
515	user21	17	2	1
516	user21	13	2	1
517	user21	10	4	1
518	user21	7	2	1
519	user21	9	4	1
520	user21	1	2	1
521	user21	5	2	1
522	user21	18	4	1
523	user21	16	4	1
524	user21	15	2	1
525	user21	6	2	1
526	user21	12	2	1
527	user21	11	2	1
528	user21	8	2	1
529	user22	4	2	1
530	user22	14	4	1
531	user22	17	2	1
532	user22	13	2	1
533	user22	10	4	1
534	user22	7	2	1
535	user22	9	4	1
536	user22	1	4	1
537	user22	5	2	1
538	user22	18	4	1
539	user22	16	4	1
540	user22	15	4	1
541	user22	6	2	1
542	user22	12	2	1
543	user22	11	2	1
544	user22	8	2	1
545	user24	4	2	1
546	user24	14	4	1
547	user24	17	2	1
548	user24	13	2	1
549	user24	10	4	1
550	user24	7	2	1
551	user24	9	4	1
552	user24	1	4	1
553	user24	5	2	1
554	user24	18	4	1
555	user24	16	4	1
556	user24	15	2	1
557	user24	6	2	1
558	user24	12	2	1
559	user24	11	2	1
560	user24	8	2	1
561	user25	4	2	1
562	user25	14	4	1
563	user25	17	2	1
564	user25	13	2	1
565	user25	10	4	1
566	user25	7	4	1
567	user25	9	4	1
568	user25	1	4	1
569	user25	5	4	1
570	user25	18	4	1
571	user25	16	4	1
572	user25	15	4	1
573	user25	6	2	1
574	user25	12	2	1
575	user25	11	2	1
576	user25	8	4	1
577	user26	4	3	1
578	user26	14	2	1
579	user26	17	3	1
580	user26	13	6	1
581	user26	10	2	1
582	user26	7	6	1
583	user26	9	6	1
584	user26	1	3	1
585	user26	5	3	1
586	user26	18	3	1
587	user26	16	6	1
588	user26	15	3	1
589	user26	6	3	1
590	user26	12	3	1
591	user26	11	3	1
592	user26	8	3	1
593	user27	4	6	1
594	user27	14	4	1
595	user27	17	2	1
596	user27	13	6	1
597	user27	10	4	1
598	user27	7	6	1
599	user27	9	6	1
600	user27	1	6	1
601	user27	5	6	1
602	user27	18	6	1
603	user27	16	3	1
604	user27	15	6	1
605	user27	6	6	1
606	user27	12	3	1
607	user27	11	6	1
608	user27	8	4	1
609	user29	4	6	1
610	user29	14	6	1
611	user29	17	2	1
612	user29	13	3	1
613	user29	10	4	1
614	user29	7	6	1
615	user29	9	6	1
616	user29	1	6	1
617	user29	5	6	1
618	user29	18	6	1
619	user29	16	3	1
620	user29	15	6	1
621	user29	6	6	1
622	user29	12	3	1
623	user29	11	3	1
624	user29	8	4	1
625	user30	4	2	1
626	user30	14	2	1
627	user30	17	2	1
628	user30	13	0	1
629	user30	10	4	1
630	user30	7	4	1
631	user30	9	4	1
632	user30	1	4	1
633	user30	5	4	1
634	user30	18	4	1
635	user30	16	2	1
636	user30	15	2	1
637	user30	6	1	1
638	user30	12	2	1
639	user30	11	4	1
640	user30	8	4	1
641	user31	4	3	1
642	user31	14	3	1
643	user31	17	3	1
644	user31	13	3	1
645	user31	10	4	1
646	user31	7	4	1
647	user31	9	6	1
648	user31	1	6	1
649	user31	5	4	1
650	user31	18	6	1
651	user31	16	6	1
652	user31	15	2	1
653	user31	6	3	1
654	user31	12	3	1
655	user31	11	3	1
656	user31	8	4	1
657	CeruDeruc	4	0	1
658	CeruDeruc	14	2	1
659	CeruDeruc	17	0	1
660	CeruDeruc	13	0	1
661	CeruDeruc	10	0	1
662	CeruDeruc	7	2	1
663	CeruDeruc	9	2	1
664	CeruDeruc	1	2	1
665	CeruDeruc	5	0	1
666	CeruDeruc	18	0	1
667	CeruDeruc	16	0	1
668	CeruDeruc	15	0	1
669	CeruDeruc	6	2	1
670	CeruDeruc	12	4	1
671	CeruDeruc	11	0	1
672	CeruDeruc	8	2	1
673	tester202	4	2	1
674	tester202	14	2	1
675	tester202	17	2	1
676	tester202	13	0	1
677	tester202	10	4	1
678	tester202	7	4	1
679	tester202	9	4	1
680	tester202	1	4	1
681	tester202	5	4	1
682	tester202	18	4	1
683	tester202	16	2	1
684	tester202	15	2	1
685	tester202	6	0	1
686	tester202	12	2	1
687	tester202	11	2	1
688	tester202	8	4	1
689	user32	4	4	1
690	user32	14	4	1
691	user32	17	4	1
692	user32	13	4	1
693	user32	10	4	1
694	user32	7	4	1
695	user32	9	4	1
696	user32	1	4	1
697	user32	5	4	1
698	user32	18	4	1
699	user32	16	4	1
700	user32	15	4	1
701	user32	6	4	1
702	user32	12	4	1
703	user32	11	4	1
704	user32	8	4	1
705	user655	4	3	1
706	user655	14	3	1
707	user655	17	3	1
708	user655	13	3	1
709	user655	10	4	1
710	user655	7	4	1
711	user655	9	6	1
712	user655	1	4	1
713	user655	5	4	1
714	user655	18	6	1
715	user655	16	6	1
716	user655	15	2	1
717	user655	6	3	1
718	user655	12	3	1
719	user655	11	3	1
720	user655	8	4	1
721	user757	4	2	1
722	user757	14	4	1
723	user757	17	0	1
724	user757	13	0	1
725	user757	10	4	1
726	user757	7	2	1
727	user757	9	2	1
728	user757	1	2	1
729	user757	5	1	1
730	user757	18	0	1
731	user757	16	0	1
732	user757	15	4	1
733	user757	6	2	1
734	user757	12	2	1
735	user757	11	2	1
736	user757	8	2	1
737	user888	4	3	1
738	user888	14	0	1
739	user888	17	3	1
740	user888	13	6	1
741	user888	10	0	1
742	user888	7	6	1
743	user888	9	6	1
744	user888	1	3	1
745	user888	5	3	1
746	user888	18	3	1
747	user888	16	6	1
748	user888	15	3	1
749	user888	6	3	1
750	user888	12	3	1
751	user888	11	3	1
752	user888	8	3	1
753	tester434	4	3	1
754	tester434	14	3	1
755	tester434	17	3	1
756	tester434	13	0	1
757	tester434	10	6	1
758	tester434	7	6	1
759	tester434	9	6	1
760	tester434	1	6	1
761	tester434	5	6	1
762	tester434	18	6	1
763	tester434	16	3	1
764	tester434	15	3	1
765	tester434	6	1	1
766	tester434	12	3	1
767	tester434	11	4	1
768	tester434	8	6	1
769	5366	4	2	1
770	5366	14	2	1
771	5366	17	2	1
772	5366	13	1	1
773	5366	10	4	1
774	5366	7	4	1
775	5366	9	4	1
776	5366	1	4	1
777	5366	5	4	1
778	5366	18	4	1
779	5366	16	2	1
780	5366	15	2	1
781	5366	6	2	1
782	5366	12	2	1
783	5366	11	2	1
784	5366	8	4	1
785	RZ2025	4	2	1
786	RZ2025	14	4	1
787	RZ2025	17	2	1
788	RZ2025	13	1	1
789	RZ2025	10	4	1
790	RZ2025	7	4	1
791	RZ2025	9	4	1
792	RZ2025	1	4	1
793	RZ2025	5	4	1
794	RZ2025	18	4	1
795	RZ2025	16	2	1
796	RZ2025	15	4	1
797	RZ2025	6	2	1
798	RZ2025	12	2	1
799	RZ2025	11	2	1
800	RZ2025	8	4	1
801	tester123456	4	3	1
802	tester123456	14	3	1
803	tester123456	17	6	1
804	tester123456	13	3	1
805	tester123456	10	0	1
806	tester123456	7	3	1
807	tester123456	9	3	1
808	tester123456	1	3	1
809	tester123456	5	3	1
810	tester123456	18	3	1
811	tester123456	16	0	1
812	tester123456	15	0	1
813	tester123456	6	3	1
814	tester123456	12	3	1
815	tester123456	11	0	1
816	tester123456	8	0	1
817	hahahauser	4	2	1
818	hahahauser	14	2	1
819	hahahauser	17	2	1
820	hahahauser	13	1	1
821	hahahauser	10	4	1
822	hahahauser	7	4	1
823	hahahauser	9	4	1
824	hahahauser	1	4	1
825	hahahauser	5	4	1
826	hahahauser	18	4	1
827	hahahauser	16	2	1
828	hahahauser	15	2	1
829	hahahauser	6	2	1
830	hahahauser	12	2	1
831	hahahauser	11	2	1
832	hahahauser	8	4	1
833	hasuser	4	6	1
834	hasuser	14	4	1
835	hasuser	17	1	1
836	hasuser	13	6	1
837	hasuser	10	3	1
838	hasuser	7	6	1
839	hasuser	9	6	1
840	hasuser	1	6	1
841	hasuser	5	6	1
842	hasuser	18	6	1
843	hasuser	16	3	1
844	hasuser	15	6	1
845	hasuser	6	6	1
846	hasuser	12	3	1
847	hasuser	11	6	1
848	hasuser	8	3	1
849	tester3111	4	3	1
850	tester3111	14	3	1
851	tester3111	17	3	1
852	tester3111	13	3	1
853	tester3111	10	2	1
854	tester3111	7	3	1
855	tester3111	9	6	1
856	tester3111	1	6	1
857	tester3111	5	3	1
858	tester3111	18	6	1
859	tester3111	16	6	1
860	tester3111	15	0	1
861	tester3111	6	3	1
862	tester3111	12	3	1
863	tester3111	11	3	1
864	tester3111	8	3	1
865	sddsss	4	2	1
866	sddsss	14	2	1
867	sddsss	17	2	1
868	sddsss	13	0	1
869	sddsss	10	4	1
870	sddsss	7	4	1
871	sddsss	9	4	1
872	sddsss	1	4	1
873	sddsss	5	4	1
874	sddsss	18	4	1
875	sddsss	16	2	1
876	sddsss	15	2	1
877	sddsss	6	1	1
878	sddsss	12	2	1
879	sddsss	11	2	1
880	sddsss	8	4	1
881	se_surver_user_78	4	1	1
882	se_surver_user_78	14	2	1
883	se_surver_user_78	17	0	1
884	se_surver_user_78	13	0	1
885	se_surver_user_78	10	4	1
886	se_surver_user_78	7	1	1
887	se_surver_user_78	9	1	1
888	se_surver_user_78	1	2	1
889	se_surver_user_78	5	0	1
890	se_surver_user_78	18	0	1
891	se_surver_user_78	16	0	1
892	se_surver_user_78	15	2	1
893	se_surver_user_78	6	1	1
894	se_surver_user_78	12	2	1
895	se_surver_user_78	11	0	1
896	se_surver_user_78	8	1	1
897	se_surver_user_80	4	1	1
898	se_surver_user_80	14	0	1
899	se_surver_user_80	17	1	1
900	se_surver_user_80	13	2	1
901	se_surver_user_80	10	4	1
902	se_surver_user_80	7	2	1
903	se_surver_user_80	9	2	1
904	se_surver_user_80	1	2	1
905	se_surver_user_80	5	1	1
906	se_surver_user_80	18	1	1
907	se_surver_user_80	16	2	1
908	se_surver_user_80	15	1	1
909	se_surver_user_80	6	1	1
910	se_surver_user_80	12	2	1
911	se_surver_user_80	11	1	1
912	se_surver_user_80	8	1	1
913	se_surver_user_81	4	1	1
914	se_surver_user_81	14	1	1
915	se_surver_user_81	17	2	1
916	se_surver_user_81	13	1	1
917	se_surver_user_81	10	0	1
918	se_surver_user_81	7	1	1
919	se_surver_user_81	9	1	1
920	se_surver_user_81	1	1	1
921	se_surver_user_81	5	1	1
922	se_surver_user_81	18	1	1
923	se_surver_user_81	16	0	1
924	se_surver_user_81	15	0	1
925	se_surver_user_81	6	1	1
926	se_surver_user_81	12	1	1
927	se_surver_user_81	11	0	1
928	se_surver_user_81	8	0	1
929	se_surver_user_82	4	1	1
930	se_surver_user_82	14	2	1
931	se_surver_user_82	17	2	1
932	se_surver_user_82	13	1	1
933	se_surver_user_82	10	0	1
934	se_surver_user_82	7	4	1
935	se_surver_user_82	9	2	1
936	se_surver_user_82	1	2	1
937	se_surver_user_82	5	1	1
938	se_surver_user_82	18	1	1
939	se_surver_user_82	16	0	1
940	se_surver_user_82	15	0	1
941	se_surver_user_82	6	1	1
942	se_surver_user_82	12	1	1
943	se_surver_user_82	11	0	1
944	se_surver_user_82	8	0	1
\.


--
-- Data for Name: unknown_role_process_matrix; Type: TABLE DATA; Schema: public; Owner: adminderik
--

COPY public.unknown_role_process_matrix (id, user_name, iso_process_id, role_process_value, organization_id) FROM stdin;
695	user9	1	0	1
696	user9	2	0	1
697	user9	3	0	1
698	user9	4	0	1
699	user9	5	0	1
700	user9	6	0	1
701	user9	7	2	1
702	user9	8	0	1
703	user9	9	2	1
704	user9	10	1	1
705	user9	11	0	1
706	user9	12	0	1
707	user9	13	0	1
708	user9	14	0	1
709	user9	15	0	1
710	user9	16	1	1
711	user9	17	0	1
712	user9	27	3	1
713	user9	18	0	1
714	user9	19	0	1
715	user9	20	0	1
716	user9	21	0	1
717	user9	22	0	1
718	user9	23	0	1
719	user9	24	0	1
720	user9	25	0	1
721	user9	26	0	1
722	user9	28	0	1
723	user9	29	0	1
724	user9	30	0	1
785	usertester3	1	0	1
786	usertester3	2	0	1
787	usertester3	3	0	1
788	usertester3	4	2	1
789	usertester3	5	0	1
790	usertester3	6	0	1
791	usertester3	7	0	1
792	usertester3	8	0	1
793	usertester3	9	2	1
794	usertester3	10	0	1
795	usertester3	11	0	1
796	usertester3	12	0	1
797	usertester3	13	1	1
798	usertester3	14	1	1
799	usertester3	15	0	1
800	usertester3	16	0	1
801	usertester3	17	0	1
802	usertester3	27	0	1
803	usertester3	18	0	1
804	usertester3	19	0	1
805	usertester3	20	0	1
806	usertester3	21	0	1
807	usertester3	22	0	1
808	usertester3	23	0	1
809	usertester3	24	0	1
810	usertester3	25	0	1
811	usertester3	26	0	1
812	usertester3	28	0	1
813	usertester3	29	2	1
814	usertester3	30	0	1
875	vvfbf	1	0	1
876	vvfbf	2	0	1
877	vvfbf	3	0	1
878	vvfbf	4	0	1
879	vvfbf	5	2	1
880	vvfbf	6	0	1
881	vvfbf	7	0	1
882	vvfbf	8	0	1
883	vvfbf	9	2	1
884	vvfbf	10	0	1
885	vvfbf	11	0	1
886	vvfbf	12	0	1
887	vvfbf	13	0	1
888	vvfbf	14	0	1
889	vvfbf	15	0	1
890	vvfbf	16	0	1
891	vvfbf	17	0	1
892	vvfbf	27	0	1
893	vvfbf	18	0	1
894	vvfbf	19	0	1
895	vvfbf	20	0	1
896	vvfbf	21	0	1
897	vvfbf	22	0	1
898	vvfbf	23	0	1
899	vvfbf	24	0	1
900	vvfbf	25	0	1
901	vvfbf	26	0	1
902	vvfbf	28	0	1
903	vvfbf	29	0	1
904	vvfbf	30	0	1
905	fztd	1	0	1
152	cerappuuu	1	0	1
153	cerappuuu	2	0	1
154	cerappuuu	3	0	1
155	cerappuuu	4	0	1
156	cerappuuu	5	0	1
157	cerappuuu	6	0	1
158	cerappuuu	7	1	1
159	cerappuuu	8	0	1
160	cerappuuu	9	2	1
161	cerappuuu	10	0	1
162	cerappuuu	11	0	1
163	cerappuuu	12	0	1
164	cerappuuu	13	0	1
165	cerappuuu	14	0	1
166	cerappuuu	15	0	1
167	cerappuuu	16	1	1
168	cerappuuu	17	0	1
169	cerappuuu	27	3	1
170	cerappuuu	18	2	1
171	cerappuuu	19	0	1
172	cerappuuu	20	0	1
173	cerappuuu	21	0	1
174	cerappuuu	22	0	1
175	cerappuuu	23	0	1
176	cerappuuu	24	0	1
177	cerappuuu	25	0	1
178	cerappuuu	26	0	1
179	cerappuuu	28	0	1
180	cerappuuu	29	0	1
181	cerappuuu	30	0	1
182	kolma	1	0	1
183	kolma	2	0	1
184	kolma	3	2	1
185	kolma	4	0	1
186	kolma	5	0	1
187	kolma	6	0	1
188	kolma	7	0	1
189	kolma	8	3	1
190	kolma	9	0	1
191	kolma	10	0	1
192	kolma	11	0	1
193	kolma	12	2	1
194	kolma	13	0	1
195	kolma	14	1	1
196	kolma	15	0	1
197	kolma	16	0	1
198	kolma	17	0	1
199	kolma	27	0	1
200	kolma	18	0	1
201	kolma	19	0	1
202	kolma	20	0	1
203	kolma	21	0	1
204	kolma	22	0	1
205	kolma	23	0	1
206	kolma	24	0	1
207	kolma	25	0	1
208	kolma	26	0	1
209	kolma	28	0	1
210	kolma	29	0	1
211	kolma	30	0	1
212	deru	1	0	1
213	deru	2	0	1
214	deru	3	2	1
215	deru	4	0	1
216	deru	5	0	1
217	deru	6	0	1
218	deru	7	0	1
219	deru	8	3	1
220	deru	9	1	1
221	deru	10	0	1
222	deru	11	0	1
223	deru	12	2	1
224	deru	13	0	1
225	deru	14	0	1
226	deru	15	0	1
227	deru	16	0	1
228	deru	17	0	1
229	deru	27	0	1
230	deru	18	0	1
231	deru	19	0	1
232	deru	20	0	1
233	deru	21	0	1
234	deru	22	0	1
235	deru	23	0	1
236	deru	24	0	1
237	deru	25	0	1
238	deru	26	0	1
239	deru	28	0	1
240	deru	29	0	1
241	deru	30	0	1
242	der	1	0	1
243	der	2	0	1
244	der	3	2	1
245	der	4	0	1
246	der	5	0	1
247	der	6	0	1
248	der	7	0	1
249	der	8	3	1
250	der	9	0	1
251	der	10	0	1
252	der	11	0	1
253	der	12	2	1
254	der	13	0	1
255	der	14	0	1
256	der	15	0	1
257	der	16	0	1
258	der	17	0	1
259	der	27	0	1
260	der	18	0	1
261	der	19	0	1
262	der	20	0	1
263	der	21	0	1
264	der	22	0	1
265	der	23	0	1
266	der	24	0	1
267	der	25	0	1
268	der	26	0	1
269	der	28	0	1
270	der	29	0	1
271	der	30	0	1
272	testuser	1	0	1
273	testuser	2	0	1
274	testuser	3	2	1
275	testuser	4	0	1
276	testuser	5	0	1
277	testuser	6	0	1
278	testuser	7	0	1
279	testuser	8	3	1
280	testuser	9	0	1
281	testuser	10	0	1
282	testuser	11	0	1
283	testuser	12	2	1
284	testuser	13	0	1
285	testuser	14	0	1
286	testuser	15	0	1
287	testuser	16	0	1
288	testuser	17	0	1
289	testuser	27	0	1
290	testuser	18	0	1
291	testuser	19	0	1
292	testuser	20	0	1
293	testuser	21	0	1
294	testuser	22	0	1
295	testuser	23	0	1
296	testuser	24	0	1
297	testuser	25	0	1
298	testuser	26	0	1
299	testuser	28	0	1
300	testuser	29	0	1
301	testuser	30	0	1
302	lahblah	1	0	1
303	lahblah	2	0	1
304	lahblah	3	0	1
305	lahblah	4	0	1
306	lahblah	5	0	1
307	lahblah	6	0	1
308	lahblah	7	1	1
309	lahblah	8	0	1
310	lahblah	9	0	1
311	lahblah	10	0	1
312	lahblah	11	1	1
313	lahblah	12	0	1
314	lahblah	13	0	1
315	lahblah	14	0	1
316	lahblah	15	0	1
317	lahblah	16	2	1
318	lahblah	17	0	1
319	lahblah	27	2	1
320	lahblah	18	0	1
321	lahblah	19	0	1
322	lahblah	20	0	1
323	lahblah	21	0	1
324	lahblah	22	0	1
325	lahblah	23	0	1
326	lahblah	24	0	1
327	lahblah	25	2	1
328	lahblah	26	0	1
329	lahblah	28	0	1
330	lahblah	29	0	1
331	lahblah	30	0	1
725	usertest1	1	0	1
333	dinkan	1	0	1
334	dinkan	2	0	1
335	dinkan	3	0	1
336	dinkan	4	0	1
337	dinkan	5	0	1
338	dinkan	6	0	1
339	dinkan	7	1	1
340	dinkan	8	0	1
341	dinkan	9	0	1
342	dinkan	10	0	1
343	dinkan	11	0	1
344	dinkan	12	0	1
345	dinkan	13	0	1
346	dinkan	14	0	1
347	dinkan	15	0	1
348	dinkan	16	2	1
349	dinkan	17	0	1
350	dinkan	27	2	1
351	dinkan	18	0	1
352	dinkan	19	0	1
353	dinkan	20	0	1
354	dinkan	21	0	1
355	dinkan	22	0	1
356	dinkan	23	0	1
357	dinkan	24	0	1
358	dinkan	25	2	1
359	dinkan	26	0	1
360	dinkan	28	0	1
361	dinkan	29	0	1
362	dinkan	30	0	1
726	usertest1	2	0	1
727	usertest1	3	0	1
728	usertest1	4	0	1
729	usertest1	5	2	1
730	usertest1	6	0	1
731	usertest1	7	0	1
732	usertest1	8	1	1
733	usertest1	9	2	1
734	usertest1	10	0	1
735	usertest1	11	1	1
736	usertest1	12	0	1
737	usertest1	13	0	1
738	usertest1	14	0	1
739	usertest1	15	0	1
740	usertest1	16	0	1
741	usertest1	17	0	1
742	usertest1	27	0	1
743	usertest1	18	2	1
744	usertest1	19	0	1
745	usertest1	20	3	1
746	usertest1	21	0	1
747	usertest1	22	0	1
748	usertest1	23	0	1
749	usertest1	24	0	1
750	usertest1	25	0	1
751	usertest1	26	0	1
752	usertest1	28	0	1
753	usertest1	29	0	1
754	usertest1	30	0	1
755	usertester2	1	0	1
756	usertester2	2	0	1
757	usertester2	3	0	1
758	usertester2	4	0	1
759	usertester2	5	0	1
760	usertester2	6	0	1
761	usertester2	7	2	1
762	usertester2	8	0	1
763	usertester2	9	0	1
764	usertester2	10	0	1
765	usertester2	11	0	1
766	usertester2	12	0	1
767	usertester2	13	0	1
768	usertester2	14	0	1
769	usertester2	15	0	1
770	usertester2	16	1	1
771	usertester2	17	0	1
772	usertester2	27	0	1
773	usertester2	18	0	1
774	usertester2	19	0	1
775	usertester2	20	0	1
776	usertester2	21	0	1
777	usertester2	22	0	1
778	usertester2	23	0	1
779	usertester2	24	0	1
780	usertester2	25	3	1
781	usertester2	26	0	1
782	usertester2	28	0	1
783	usertester2	29	0	1
784	usertester2	30	0	1
815	user11	1	0	1
816	user11	2	0	1
817	user11	3	0	1
818	user11	4	0	1
819	user11	5	0	1
820	user11	6	0	1
821	user11	7	1	1
822	user11	8	0	1
823	user11	9	2	1
824	user11	10	0	1
825	user11	11	1	1
826	user11	12	0	1
827	user11	13	0	1
828	user11	14	1	1
829	user11	15	2	1
830	user11	16	1	1
831	user11	17	0	1
832	user11	27	0	1
833	user11	18	2	1
834	user11	19	0	1
835	user11	20	0	1
836	user11	21	0	1
837	user11	22	0	1
838	user11	23	0	1
839	user11	24	0	1
840	user11	25	0	1
841	user11	26	0	1
842	user11	28	0	1
843	user11	29	0	1
844	user11	30	0	1
845	user12	1	0	1
846	user12	2	0	1
847	user12	3	0	1
848	user12	4	0	1
849	user12	5	0	1
850	user12	6	0	1
851	user12	7	2	1
852	user12	8	0	1
853	user12	9	0	1
854	user12	10	0	1
855	user12	11	0	1
856	user12	12	2	1
857	user12	13	0	1
858	user12	14	0	1
859	user12	15	0	1
860	user12	16	1	1
861	user12	17	0	1
862	user12	27	0	1
863	user12	18	0	1
864	user12	19	0	1
865	user12	20	0	1
866	user12	21	0	1
867	user12	22	0	1
868	user12	23	0	1
869	user12	24	0	1
870	user12	25	0	1
871	user12	26	0	1
872	user12	28	0	1
873	user12	29	0	1
874	user12	30	0	1
906	fztd	2	0	1
907	fztd	3	0	1
908	fztd	4	1	1
909	fztd	5	0	1
910	fztd	6	0	1
911	fztd	7	0	1
912	fztd	8	0	1
913	fztd	9	0	1
914	fztd	10	0	1
915	fztd	11	0	1
916	fztd	12	0	1
917	fztd	13	2	1
918	fztd	14	0	1
919	fztd	15	0	1
920	fztd	16	0	1
921	fztd	17	0	1
922	fztd	27	0	1
923	fztd	18	0	1
924	fztd	19	0	1
925	fztd	20	0	1
926	fztd	21	0	1
927	fztd	22	0	1
928	fztd	23	0	1
929	fztd	24	0	1
930	fztd	25	0	1
931	fztd	26	0	1
932	fztd	28	1	1
933	fztd	29	2	1
934	fztd	30	0	1
935	giuzg	1	0	1
936	giuzg	2	0	1
937	giuzg	3	0	1
938	giuzg	4	0	1
939	giuzg	5	0	1
940	giuzg	6	0	1
941	giuzg	7	0	1
942	giuzg	8	0	1
943	giuzg	9	2	1
944	giuzg	10	0	1
945	giuzg	11	0	1
946	giuzg	12	0	1
947	giuzg	13	0	1
948	giuzg	14	1	1
949	giuzg	15	0	1
950	giuzg	16	0	1
951	giuzg	17	0	1
952	giuzg	27	0	1
953	giuzg	18	1	1
954	giuzg	19	3	1
955	giuzg	20	0	1
956	giuzg	21	0	1
957	giuzg	22	0	1
958	giuzg	23	0	1
959	giuzg	24	0	1
960	giuzg	25	0	1
961	giuzg	26	0	1
962	giuzg	28	2	1
963	giuzg	29	0	1
964	giuzg	30	0	1
965	buzigh78	1	0	1
966	buzigh78	2	0	1
967	buzigh78	3	0	1
968	buzigh78	4	0	1
969	buzigh78	5	0	1
970	buzigh78	6	0	1
971	buzigh78	7	2	1
972	buzigh78	8	0	1
973	buzigh78	9	2	1
974	buzigh78	10	1	1
975	buzigh78	11	0	1
976	buzigh78	12	2	1
977	buzigh78	13	0	1
978	buzigh78	14	0	1
979	buzigh78	15	0	1
980	buzigh78	16	1	1
981	buzigh78	17	0	1
982	buzigh78	27	0	1
983	buzigh78	18	0	1
984	buzigh78	19	0	1
985	buzigh78	20	0	1
986	buzigh78	21	0	1
987	buzigh78	22	0	1
988	buzigh78	23	0	1
989	buzigh78	24	0	1
990	buzigh78	25	0	1
991	buzigh78	26	0	1
992	buzigh78	28	0	1
993	buzigh78	29	0	1
994	buzigh78	30	0	1
995	user20	1	0	1
996	user20	2	0	1
997	user20	3	0	1
998	user20	4	0	1
999	user20	5	0	1
1000	user20	6	0	1
1001	user20	7	1	1
1002	user20	8	0	1
1003	user20	9	2	1
1004	user20	10	0	1
1005	user20	11	0	1
1006	user20	12	0	1
1007	user20	13	0	1
1008	user20	14	0	1
1009	user20	15	0	1
1010	user20	16	1	1
1011	user20	17	0	1
1012	user20	27	0	1
1013	user20	18	3	1
1014	user20	19	3	1
1015	user20	20	0	1
1016	user20	21	0	1
1017	user20	22	0	1
1018	user20	23	0	1
1019	user20	24	0	1
1020	user20	25	0	1
1021	user20	26	0	1
1022	user20	28	0	1
1023	user20	29	0	1
1024	user20	30	0	1
1025	user21	1	0	1
1026	user21	2	0	1
1027	user21	3	0	1
1028	user21	4	0	1
1029	user21	5	0	1
1030	user21	6	0	1
1031	user21	7	1	1
1032	user21	8	0	1
1033	user21	9	0	1
1034	user21	10	0	1
1035	user21	11	0	1
1036	user21	12	0	1
1037	user21	13	0	1
1038	user21	14	0	1
1039	user21	15	0	1
1040	user21	16	2	1
1041	user21	17	0	1
1042	user21	27	0	1
1043	user21	18	0	1
1044	user21	19	0	1
1045	user21	20	0	1
1046	user21	21	0	1
1047	user21	22	0	1
1048	user21	23	0	1
1049	user21	24	0	1
1050	user21	25	2	1
1051	user21	26	0	1
1052	user21	28	0	1
1053	user21	29	0	1
1054	user21	30	0	1
1055	user22	1	0	1
1056	user22	2	0	1
1057	user22	3	0	1
1058	user22	4	0	1
1059	user22	5	0	1
1060	user22	6	0	1
1061	user22	7	2	1
1062	user22	8	0	1
1063	user22	9	0	1
1064	user22	10	0	1
1065	user22	11	0	1
1066	user22	12	0	1
1067	user22	13	0	1
1068	user22	14	0	1
1069	user22	15	0	1
1070	user22	16	1	1
1071	user22	17	0	1
1072	user22	27	2	1
1073	user22	18	0	1
1074	user22	19	0	1
1075	user22	20	0	1
1076	user22	21	0	1
1077	user22	22	0	1
1078	user22	23	0	1
1079	user22	24	0	1
1080	user22	25	2	1
1081	user22	26	0	1
1082	user22	28	0	1
1083	user22	29	0	1
1084	user22	30	0	1
1085	user24	1	0	1
1086	user24	2	0	1
1087	user24	3	0	1
1088	user24	4	0	1
1089	user24	5	0	1
1090	user24	6	0	1
1091	user24	7	1	1
1092	user24	8	0	1
1093	user24	9	0	1
1094	user24	10	0	1
1095	user24	11	0	1
1096	user24	12	0	1
1097	user24	13	0	1
1098	user24	14	0	1
1099	user24	15	0	1
1100	user24	16	2	1
1101	user24	17	0	1
1102	user24	27	2	1
1103	user24	18	0	1
1104	user24	19	0	1
1105	user24	20	0	1
1106	user24	21	0	1
1107	user24	22	0	1
1108	user24	23	0	1
1109	user24	24	0	1
1110	user24	25	2	1
1111	user24	26	0	1
1112	user24	28	0	1
1113	user24	29	0	1
1114	user24	30	0	1
1115	user25	1	0	1
1116	user25	2	0	1
1117	user25	3	0	1
1118	user25	4	0	1
1119	user25	5	0	1
1120	user25	6	0	1
1121	user25	7	2	1
1122	user25	8	0	1
1123	user25	9	0	1
1124	user25	10	2	1
1125	user25	11	0	1
1126	user25	12	1	1
1127	user25	13	0	1
1128	user25	14	0	1
1129	user25	15	0	1
1130	user25	16	1	1
1131	user25	17	0	1
1132	user25	27	2	1
1133	user25	18	0	1
1134	user25	19	0	1
1135	user25	20	0	1
1136	user25	21	0	1
1137	user25	22	0	1
1138	user25	23	0	1
1139	user25	24	0	1
1140	user25	25	0	1
1141	user25	26	0	1
1142	user25	28	0	1
1143	user25	29	0	1
1144	user25	30	0	1
1145	user26	1	0	1
1146	user26	2	0	1
1147	user26	3	0	1
1148	user26	4	0	1
1149	user26	5	0	1
1150	user26	6	0	1
1151	user26	7	1	1
1152	user26	8	1	1
1153	user26	9	0	1
1154	user26	10	0	1
1155	user26	11	0	1
1156	user26	12	0	1
1157	user26	13	2	1
1158	user26	14	1	1
1159	user26	15	0	1
1160	user26	16	0	1
1161	user26	17	0	1
1162	user26	27	0	1
1163	user26	18	0	1
1164	user26	19	0	1
1165	user26	20	0	1
1166	user26	21	0	1
1167	user26	22	0	1
1168	user26	23	0	1
1169	user26	24	3	1
1170	user26	25	0	1
1171	user26	26	0	1
1172	user26	28	0	1
1173	user26	29	0	1
1174	user26	30	0	1
1175	user27	1	0	1
1176	user27	2	0	1
1177	user27	3	0	1
1178	user27	4	1	1
1179	user27	5	0	1
1180	user27	6	0	1
1181	user27	7	2	1
1182	user27	8	0	1
1183	user27	9	2	1
1184	user27	10	0	1
1185	user27	11	0	1
1186	user27	12	0	1
1187	user27	13	1	1
1188	user27	14	1	1
1189	user27	15	0	1
1190	user27	16	2	1
1191	user27	17	0	1
1192	user27	27	0	1
1193	user27	18	0	1
1194	user27	19	0	1
1195	user27	20	3	1
1196	user27	21	3	1
1197	user27	22	0	1
1198	user27	23	2	1
1199	user27	24	1	1
1200	user27	25	0	1
1201	user27	26	0	1
1202	user27	28	0	1
1203	user27	29	0	1
1204	user27	30	0	1
1205	user29	1	0	1
1206	user29	2	0	1
1207	user29	3	0	1
1208	user29	4	0	1
1209	user29	5	0	1
1210	user29	6	1	1
1211	user29	7	0	1
1212	user29	8	0	1
1213	user29	9	2	1
1214	user29	10	0	1
1215	user29	11	0	1
1216	user29	12	0	1
1217	user29	13	0	1
1218	user29	14	0	1
1219	user29	15	0	1
1220	user29	16	0	1
1221	user29	17	0	1
1222	user29	27	0	1
1223	user29	18	0	1
1224	user29	19	3	1
1225	user29	20	0	1
1226	user29	21	3	1
1227	user29	22	0	1
1228	user29	23	0	1
1229	user29	24	0	1
1230	user29	25	0	1
1231	user29	26	0	1
1232	user29	28	0	1
1233	user29	29	0	1
1234	user29	30	0	1
1235	user30	1	0	1
1236	user30	2	0	1
1237	user30	3	0	1
1238	user30	4	0	1
1239	user30	5	2	1
1240	user30	6	1	1
1241	user30	7	1	1
1242	user30	8	1	1
1243	user30	9	2	1
1244	user30	10	2	1
1245	user30	11	0	1
1246	user30	12	0	1
1247	user30	13	0	1
1248	user30	14	1	1
1249	user30	15	0	1
1250	user30	16	1	1
1251	user30	17	0	1
1252	user30	27	0	1
1253	user30	18	0	1
1254	user30	19	0	1
1255	user30	20	0	1
1256	user30	21	0	1
1257	user30	22	0	1
1258	user30	23	0	1
1259	user30	24	0	1
1260	user30	25	0	1
1261	user30	26	0	1
1262	user30	28	0	1
1263	user30	29	0	1
1264	user30	30	0	1
1265	user31	1	0	1
1266	user31	2	0	1
1267	user31	3	0	1
1268	user31	4	0	1
1269	user31	5	0	1
1270	user31	6	0	1
1271	user31	7	1	1
1272	user31	8	0	1
1273	user31	9	2	1
1274	user31	10	1	1
1275	user31	11	0	1
1276	user31	12	0	1
1277	user31	13	0	1
1278	user31	14	0	1
1279	user31	15	0	1
1280	user31	16	1	1
1281	user31	17	0	1
1282	user31	27	3	1
1283	user31	18	0	1
1284	user31	19	0	1
1285	user31	20	0	1
1286	user31	21	0	1
1287	user31	22	0	1
1288	user31	23	0	1
1289	user31	24	0	1
1290	user31	25	0	1
1291	user31	26	0	1
1292	user31	28	0	1
1293	user31	29	0	1
1294	user31	30	0	1
1295	CeruDeruc	1	0	1
1296	CeruDeruc	2	0	1
1297	CeruDeruc	3	0	1
1298	CeruDeruc	4	0	1
1299	CeruDeruc	5	0	1
1300	CeruDeruc	6	0	1
1301	CeruDeruc	7	0	1
1302	CeruDeruc	8	0	1
1303	CeruDeruc	9	0	1
1304	CeruDeruc	10	0	1
1305	CeruDeruc	11	0	1
1306	CeruDeruc	12	0	1
1307	CeruDeruc	13	0	1
1308	CeruDeruc	14	2	1
1309	CeruDeruc	15	0	1
1310	CeruDeruc	16	0	1
1311	CeruDeruc	17	0	1
1312	CeruDeruc	27	0	1
1313	CeruDeruc	18	0	1
1314	CeruDeruc	19	0	1
1315	CeruDeruc	20	0	1
1316	CeruDeruc	21	0	1
1317	CeruDeruc	22	0	1
1318	CeruDeruc	23	0	1
1319	CeruDeruc	24	0	1
1320	CeruDeruc	25	0	1
1321	CeruDeruc	26	0	1
1322	CeruDeruc	28	0	1
1323	CeruDeruc	29	0	1
1324	CeruDeruc	30	0	1
1325	tester202	1	0	1
1326	tester202	2	0	1
1327	tester202	3	0	1
1328	tester202	4	0	1
1329	tester202	5	0	1
1330	tester202	6	0	1
1331	tester202	7	0	1
1332	tester202	8	0	1
1333	tester202	9	2	1
1334	tester202	10	0	1
1335	tester202	11	0	1
1336	tester202	12	0	1
1337	tester202	13	0	1
1338	tester202	14	0	1
1339	tester202	15	0	1
1340	tester202	16	0	1
1341	tester202	17	0	1
1342	tester202	27	0	1
1343	tester202	18	0	1
1344	tester202	19	0	1
1345	tester202	20	0	1
1346	tester202	21	0	1
1347	tester202	22	0	1
1348	tester202	23	0	1
1349	tester202	24	0	1
1350	tester202	25	0	1
1351	tester202	26	0	1
1352	tester202	28	0	1
1353	tester202	29	0	1
1354	tester202	30	0	1
1355	user32	1	0	1
1356	user32	2	0	1
1357	user32	3	2	1
1358	user32	4	1	1
1359	user32	5	2	1
1360	user32	6	0	1
1361	user32	7	1	1
1362	user32	8	0	1
1363	user32	9	2	1
1364	user32	10	1	1
1365	user32	11	1	1
1366	user32	12	1	1
1367	user32	13	1	1
1368	user32	14	1	1
1369	user32	15	0	1
1370	user32	16	1	1
1371	user32	17	0	1
1372	user32	27	0	1
1373	user32	18	0	1
1374	user32	19	0	1
1375	user32	20	0	1
1376	user32	21	0	1
1377	user32	22	0	1
1378	user32	23	0	1
1379	user32	24	0	1
1380	user32	25	0	1
1381	user32	26	0	1
1382	user32	28	0	1
1383	user32	29	0	1
1384	user32	30	0	1
1385	user655	1	0	1
1386	user655	2	0	1
1387	user655	3	0	1
1388	user655	4	0	1
1389	user655	5	0	1
1390	user655	6	0	1
1391	user655	7	0	1
1392	user655	8	0	1
1393	user655	9	2	1
1394	user655	10	0	1
1395	user655	11	0	1
1396	user655	12	0	1
1397	user655	13	0	1
1398	user655	14	1	1
1399	user655	15	0	1
1400	user655	16	0	1
1401	user655	17	0	1
1402	user655	27	0	1
1403	user655	18	0	1
1404	user655	19	0	1
1405	user655	20	0	1
1406	user655	21	0	1
1407	user655	22	0	1
1408	user655	23	0	1
1409	user655	24	0	1
1410	user655	25	3	1
1411	user655	26	0	1
1412	user655	28	0	1
1413	user655	29	0	1
1414	user655	30	0	1
1415	user757	1	0	1
1416	user757	2	0	1
1417	user757	3	0	1
1418	user757	4	0	1
1419	user757	5	0	1
1420	user757	6	2	1
1421	user757	7	2	1
1422	user757	8	1	1
1423	user757	9	0	1
1424	user757	10	0	1
1425	user757	11	0	1
1426	user757	12	1	1
1427	user757	13	0	1
1428	user757	14	0	1
1429	user757	15	0	1
1430	user757	16	1	1
1431	user757	17	0	1
1432	user757	27	0	1
1433	user757	18	0	1
1434	user757	19	0	1
1435	user757	20	0	1
1436	user757	21	0	1
1437	user757	22	0	1
1438	user757	23	0	1
1439	user757	24	0	1
1440	user757	25	0	1
1441	user757	26	0	1
1442	user757	28	0	1
1443	user757	29	0	1
1444	user757	30	0	1
1445	user888	1	0	1
1446	user888	2	0	1
1447	user888	3	0	1
1448	user888	4	0	1
1449	user888	5	0	1
1450	user888	6	0	1
1451	user888	7	0	1
1452	user888	8	0	1
1453	user888	9	0	1
1454	user888	10	0	1
1455	user888	11	0	1
1456	user888	12	0	1
1457	user888	13	0	1
1458	user888	14	0	1
1459	user888	15	0	1
1460	user888	16	0	1
1461	user888	17	0	1
1462	user888	27	0	1
1463	user888	18	0	1
1464	user888	19	0	1
1465	user888	20	0	1
1466	user888	21	0	1
1467	user888	22	0	1
1468	user888	23	0	1
1469	user888	24	3	1
1470	user888	25	0	1
1471	user888	26	0	1
1472	user888	28	0	1
1473	user888	29	0	1
1474	user888	30	0	1
1475	tester434	1	0	1
1476	tester434	2	0	1
1477	tester434	3	0	1
1478	tester434	4	0	1
1479	tester434	5	2	1
1480	tester434	6	0	1
1481	tester434	7	1	1
1482	tester434	8	0	1
1483	tester434	9	3	1
1484	tester434	10	1	1
1485	tester434	11	0	1
1486	tester434	12	0	1
1487	tester434	13	0	1
1488	tester434	14	0	1
1489	tester434	15	0	1
1490	tester434	16	0	1
1491	tester434	17	0	1
1492	tester434	27	0	1
1493	tester434	18	0	1
1494	tester434	19	0	1
1495	tester434	20	0	1
1496	tester434	21	0	1
1497	tester434	22	0	1
1498	tester434	23	0	1
1499	tester434	24	0	1
1500	tester434	25	0	1
1501	tester434	26	0	1
1502	tester434	28	0	1
1503	tester434	29	0	1
1504	tester434	30	0	1
1505	5366	1	0	1
1506	5366	2	0	1
1507	5366	3	0	1
1508	5366	4	0	1
1509	5366	5	0	1
1510	5366	6	1	1
1511	5366	7	0	1
1512	5366	8	0	1
1513	5366	9	2	1
1514	5366	10	0	1
1515	5366	11	0	1
1516	5366	12	0	1
1517	5366	13	0	1
1518	5366	14	0	1
1519	5366	15	0	1
1520	5366	16	0	1
1521	5366	17	0	1
1522	5366	27	0	1
1523	5366	18	1	1
1524	5366	19	0	1
1525	5366	20	0	1
1526	5366	21	0	1
1527	5366	22	0	1
1528	5366	23	0	1
1529	5366	24	0	1
1530	5366	25	0	1
1531	5366	26	0	1
1532	5366	28	0	1
1533	5366	29	0	1
1534	5366	30	0	1
1535	RZ2025	1	0	1
1536	RZ2025	2	0	1
1537	RZ2025	3	0	1
1538	RZ2025	4	0	1
1539	RZ2025	5	0	1
1540	RZ2025	6	1	1
1541	RZ2025	7	2	1
1542	RZ2025	8	1	1
1543	RZ2025	9	2	1
1544	RZ2025	10	0	1
1545	RZ2025	11	0	1
1546	RZ2025	12	0	1
1547	RZ2025	13	0	1
1548	RZ2025	14	0	1
1549	RZ2025	15	0	1
1550	RZ2025	16	0	1
1551	RZ2025	17	0	1
1552	RZ2025	27	0	1
1553	RZ2025	18	1	1
1554	RZ2025	19	0	1
1555	RZ2025	20	0	1
1556	RZ2025	21	0	1
1557	RZ2025	22	0	1
1558	RZ2025	23	0	1
1559	RZ2025	24	0	1
1560	RZ2025	25	0	1
1561	RZ2025	26	0	1
1562	RZ2025	28	0	1
1563	RZ2025	29	0	1
1564	RZ2025	30	0	1
1565	tester123456	1	0	1
1566	tester123456	2	0	1
1567	tester123456	3	0	1
1568	tester123456	4	0	1
1569	tester123456	5	0	1
1570	tester123456	6	0	1
1571	tester123456	7	0	1
1572	tester123456	8	0	1
1573	tester123456	9	0	1
1574	tester123456	10	0	1
1575	tester123456	11	0	1
1576	tester123456	12	0	1
1577	tester123456	13	0	1
1578	tester123456	14	0	1
1579	tester123456	15	0	1
1580	tester123456	16	0	1
1581	tester123456	17	0	1
1582	tester123456	27	0	1
1583	tester123456	18	0	1
1584	tester123456	19	0	1
1585	tester123456	20	0	1
1586	tester123456	21	0	1
1587	tester123456	22	0	1
1588	tester123456	23	0	1
1589	tester123456	24	0	1
1590	tester123456	25	0	1
1591	tester123456	26	0	1
1592	tester123456	28	0	1
1593	tester123456	29	1	1
1594	tester123456	30	3	1
1595	hahahauser	1	0	1
1596	hahahauser	2	0	1
1597	hahahauser	3	0	1
1598	hahahauser	4	0	1
1599	hahahauser	5	0	1
1600	hahahauser	6	0	1
1601	hahahauser	7	0	1
1602	hahahauser	8	0	1
1603	hahahauser	9	2	1
1604	hahahauser	10	0	1
1605	hahahauser	11	0	1
1606	hahahauser	12	1	1
1607	hahahauser	13	0	1
1608	hahahauser	14	0	1
1609	hahahauser	15	0	1
1610	hahahauser	16	0	1
1611	hahahauser	17	0	1
1612	hahahauser	27	1	1
1613	hahahauser	18	0	1
1614	hahahauser	19	0	1
1615	hahahauser	20	0	1
1616	hahahauser	21	0	1
1617	hahahauser	22	0	1
1618	hahahauser	23	0	1
1619	hahahauser	24	0	1
1620	hahahauser	25	0	1
1621	hahahauser	26	0	1
1622	hahahauser	28	0	1
1623	hahahauser	29	0	1
1624	hahahauser	30	0	1
1625	hasuser	1	0	1
1626	hasuser	2	0	1
1627	hasuser	3	0	1
1628	hasuser	4	0	1
1629	hasuser	5	0	1
1630	hasuser	6	0	1
1631	hasuser	7	0	1
1632	hasuser	8	0	1
1633	hasuser	9	0	1
1634	hasuser	10	0	1
1635	hasuser	11	0	1
1636	hasuser	12	1	1
1637	hasuser	13	0	1
1638	hasuser	14	0	1
1639	hasuser	15	0	1
1640	hasuser	16	0	1
1641	hasuser	17	0	1
1642	hasuser	27	1	1
1643	hasuser	18	0	1
1644	hasuser	19	2	1
1645	hasuser	20	3	1
1646	hasuser	21	3	1
1647	hasuser	22	0	1
1648	hasuser	23	0	1
1649	hasuser	24	0	1
1650	hasuser	25	0	1
1651	hasuser	26	0	1
1652	hasuser	28	0	1
1653	hasuser	29	0	1
1654	hasuser	30	0	1
1655	tester3111	1	0	1
1656	tester3111	2	0	1
1657	tester3111	3	0	1
1658	tester3111	4	0	1
1659	tester3111	5	0	1
1660	tester3111	6	0	1
1661	tester3111	7	0	1
1662	tester3111	8	0	1
1663	tester3111	9	0	1
1664	tester3111	10	0	1
1665	tester3111	11	0	1
1666	tester3111	12	0	1
1667	tester3111	13	0	1
1668	tester3111	14	0	1
1669	tester3111	15	0	1
1670	tester3111	16	1	1
1671	tester3111	17	0	1
1672	tester3111	27	3	1
1673	tester3111	18	0	1
1674	tester3111	19	0	1
1675	tester3111	20	0	1
1676	tester3111	21	0	1
1677	tester3111	22	0	1
1678	tester3111	23	0	1
1679	tester3111	24	0	1
1680	tester3111	25	1	1
1681	tester3111	26	0	1
1682	tester3111	28	0	1
1683	tester3111	29	0	1
1684	tester3111	30	0	1
1685	sddsss	1	0	1
1686	sddsss	2	0	1
1687	sddsss	3	0	1
1688	sddsss	4	0	1
1689	sddsss	5	0	1
1690	sddsss	6	0	1
1691	sddsss	7	1	1
1692	sddsss	8	0	1
1693	sddsss	9	2	1
1694	sddsss	10	0	1
1695	sddsss	11	0	1
1696	sddsss	12	0	1
1697	sddsss	13	0	1
1698	sddsss	14	0	1
1699	sddsss	15	0	1
1700	sddsss	16	1	1
1701	sddsss	17	0	1
1702	sddsss	27	0	1
1703	sddsss	18	0	1
1704	sddsss	19	0	1
1705	sddsss	20	0	1
1706	sddsss	21	0	1
1707	sddsss	22	0	1
1708	sddsss	23	0	1
1709	sddsss	24	0	1
1710	sddsss	25	0	1
1711	sddsss	26	0	1
1712	sddsss	28	0	1
1713	sddsss	29	0	1
1714	sddsss	30	0	1
1715	se_surver_user_78	1	0	1
1716	se_surver_user_78	2	0	1
1717	se_surver_user_78	3	0	1
1718	se_surver_user_78	4	0	1
1719	se_surver_user_78	5	0	1
1720	se_surver_user_78	6	0	1
1721	se_surver_user_78	7	1	1
1722	se_surver_user_78	8	0	1
1723	se_surver_user_78	9	0	1
1724	se_surver_user_78	10	0	1
1725	se_surver_user_78	11	0	1
1726	se_surver_user_78	12	0	1
1727	se_surver_user_78	13	0	1
1728	se_surver_user_78	14	0	1
1729	se_surver_user_78	15	2	1
1730	se_surver_user_78	16	0	1
1731	se_surver_user_78	17	0	1
1732	se_surver_user_78	27	0	1
1733	se_surver_user_78	18	0	1
1734	se_surver_user_78	19	0	1
1735	se_surver_user_78	20	0	1
1736	se_surver_user_78	21	0	1
1737	se_surver_user_78	22	0	1
1738	se_surver_user_78	23	0	1
1739	se_surver_user_78	24	0	1
1740	se_surver_user_78	25	0	1
1741	se_surver_user_78	26	0	1
1742	se_surver_user_78	28	0	1
1743	se_surver_user_78	29	0	1
1744	se_surver_user_78	30	0	1
1745	se_surver_user_80	1	0	1
1746	se_surver_user_80	2	0	1
1747	se_surver_user_80	3	0	1
1748	se_surver_user_80	4	0	1
1749	se_surver_user_80	5	0	1
1750	se_surver_user_80	6	0	1
1751	se_surver_user_80	7	0	1
1752	se_surver_user_80	8	0	1
1753	se_surver_user_80	9	0	1
1754	se_surver_user_80	10	0	1
1755	se_surver_user_80	11	0	1
1756	se_surver_user_80	12	0	1
1757	se_surver_user_80	13	0	1
1758	se_surver_user_80	14	0	1
1759	se_surver_user_80	15	2	1
1760	se_surver_user_80	16	0	1
1761	se_surver_user_80	17	0	1
1762	se_surver_user_80	27	0	1
1763	se_surver_user_80	18	0	1
1764	se_surver_user_80	19	0	1
1765	se_surver_user_80	20	0	1
1766	se_surver_user_80	21	0	1
1767	se_surver_user_80	22	0	1
1768	se_surver_user_80	23	0	1
1769	se_surver_user_80	24	1	1
1770	se_surver_user_80	25	0	1
1771	se_surver_user_80	26	0	1
1772	se_surver_user_80	28	0	1
1773	se_surver_user_80	29	0	1
1774	se_surver_user_80	30	0	1
1775	se_surver_user_81	1	0	1
1776	se_surver_user_81	2	0	1
1777	se_surver_user_81	3	0	1
1778	se_surver_user_81	4	0	1
1779	se_surver_user_81	5	0	1
1780	se_surver_user_81	6	0	1
1781	se_surver_user_81	7	0	1
1782	se_surver_user_81	8	0	1
1783	se_surver_user_81	9	0	1
1784	se_surver_user_81	10	0	1
1785	se_surver_user_81	11	0	1
1786	se_surver_user_81	12	0	1
1787	se_surver_user_81	13	0	1
1788	se_surver_user_81	14	0	1
1789	se_surver_user_81	15	0	1
1790	se_surver_user_81	16	0	1
1791	se_surver_user_81	17	0	1
1792	se_surver_user_81	27	0	1
1793	se_surver_user_81	18	0	1
1794	se_surver_user_81	19	0	1
1795	se_surver_user_81	20	0	1
1796	se_surver_user_81	21	0	1
1797	se_surver_user_81	22	0	1
1798	se_surver_user_81	23	0	1
1799	se_surver_user_81	24	0	1
1800	se_surver_user_81	25	0	1
1801	se_surver_user_81	26	0	1
1802	se_surver_user_81	28	0	1
1803	se_surver_user_81	29	0	1
1804	se_surver_user_81	30	1	1
1805	se_surver_user_82	1	2	1
1806	se_surver_user_82	2	0	1
1807	se_surver_user_82	3	0	1
1808	se_surver_user_82	4	0	1
1809	se_surver_user_82	5	0	1
1810	se_surver_user_82	6	0	1
1811	se_surver_user_82	7	0	1
1812	se_surver_user_82	8	0	1
1813	se_surver_user_82	9	0	1
1814	se_surver_user_82	10	0	1
1815	se_surver_user_82	11	0	1
1816	se_surver_user_82	12	0	1
1817	se_surver_user_82	13	0	1
1818	se_surver_user_82	14	0	1
1819	se_surver_user_82	15	0	1
1820	se_surver_user_82	16	0	1
1821	se_surver_user_82	17	0	1
1822	se_surver_user_82	27	0	1
1823	se_surver_user_82	18	0	1
1824	se_surver_user_82	19	0	1
1825	se_surver_user_82	20	0	1
1826	se_surver_user_82	21	0	1
1827	se_surver_user_82	22	0	1
1828	se_surver_user_82	23	0	1
1829	se_surver_user_82	24	0	1
1830	se_surver_user_82	25	0	1
1831	se_surver_user_82	26	0	1
1832	se_surver_user_82	28	0	1
1833	se_surver_user_82	29	0	1
1834	se_surver_user_82	30	1	1
\.


--
-- Data for Name: user_competency_survey_feedback; Type: TABLE DATA; Schema: public; Owner: adminderik
--

COPY public.user_competency_survey_feedback (id, user_id, organization_id, feedback, created_at) FROM stdin;
5	23	1	[{"feedbacks": [{"user_strengths": "You possess a solid understanding of how individual components interact within a system. This is a vital skill in systems engineering and should serve as a strong foundation as you continue to grow in this area.", "competency_name": "Systems Thinking", "improvement_areas": "To reach the next level of competency, you should focus on analyzing your current system and deriving continuous improvements from it. This might involve identifying potential inefficiencies or areas of improvement and proposing solutions. Consider seeking additional training or mentorship to strengthen this skill."}, {"user_strengths": "You demonstrate a high level of competency in evaluating concepts related to all lifecycle phases. This is an important skill in ensuring that systems are effectively managed throughout their lifecycle.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Although you exceed the required level of competency, it is always beneficial to continue learning. To further enhance your skills, you could focus on identifying, considering, and assessing all lifecycle phases relevant to your scope. This might involve studying industry best practices or seeking advice from more experienced colleagues."}, {"user_strengths": "As this is an area where you lack knowledge, it represents an opportunity for significant growth.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Since the required level of competency involves developing systems using agile methodologies and focusing on customer benefit, you could consider enrolling in courses on agile methodologies or customer-centric design. Mentorship or practical experience in a project that focuses on these aspects can also be beneficial."}, {"user_strengths": "You have a basic familiarity with modeling and its benefits. This foundational knowledge is crucial as you advance in your understanding of systems modeling and analysis.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To reach the required level, you should aim to define your own system models for the relevant scope independently, as well as differentiate between cross-domain and domain-specific models. Consider seeking additional training in this area, or practice by creating your own system models in a controlled environment."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "Your skills in Decision Management exceed the required level. You have the ability to evaluate decisions, establish decision-making bodies, and define guidelines for making decisions.", "competency_name": "Decision Management", "improvement_areas": "Even though you surpass the requirements, it's always possible to enhance your skills. You might consider exploring additional decision support methods or refine your understanding of which decisions should be made at different levels."}, {"user_strengths": "You meet the required competency level in Project Management. Your ability to define project mandates, establish conditions, create complex project plans, and produce reports is commendable. Your communication skills with stakeholders are also appreciated.", "competency_name": "Project Management", "improvement_areas": "Since you're already meeting the required level, consider honing your skills further. You might want to explore advanced project management methodologies or tools, or work on enhancing your leadership skills within project management."}, {"user_strengths": "Your competency in Information Management exceeds the required level. You are adept at defining storage structures, setting documentation guidelines, and providing relevant information at the right place.", "competency_name": "Information Management", "improvement_areas": "While you exceed the requirements, there's always room for enhancement. You can improve by understanding key platforms for knowledge transfer and ensuring that the right information is shared with the right people."}, {"user_strengths": "You have mastered Configuration Management beyond the required level. Your ability to recognize all relevant configuration items, create comprehensive configurations, and assist others is highly commendable.", "competency_name": "Configuration Management", "improvement_areas": "Even though you exceed the required level, there's always room for further improvement. You might want to deepen your understanding of the process of defining configuration items and using the necessary tools to create configurations for your scopes."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "Your leadership skills are impressive. You are adept at strategically developing team members to enhance their problem-solving capabilities. This is a vital skill in systems engineering, as it allows for a more robust and adaptive team.", "competency_name": "Leadership", "improvement_areas": "Even though you surpass the required level of understanding the relevance of defining objectives, it could be beneficial to not only develop your team's problem-solving skills but also ensure they understand the objectives of the system."}, {"user_strengths": "Your understanding of how self-organization concepts can influence your daily work is commendable. This comprehension is crucial in managing your personal work and tasks.", "competency_name": "Self-Organization", "improvement_areas": "However, it's important to elevate your competency to the 'Anwenden' level, which means being able to independently manage projects, processes, and tasks. Consider seeking more hands-on experience or taking a course focused on project management and self-organization."}, {"user_strengths": "Your ability to communicate constructively, efficiently, and empathetically is a great asset. Such skills are crucial in systems engineering, where clear and effective communication is necessary for success.", "competency_name": "Communication", "improvement_areas": "Although you exceed the required competency level here, always strive to enhance your communication skills, as they are vital in your role. Consider seeking out opportunities to interact with various teams and stakeholders to gain a broader perspective and experience."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have a good understanding of the fundamental concepts of requirements definition, including the ability to distinguish between various types of requirements, understanding the importance of traceability, and familiarity with the basic process of requirement management.", "competency_name": "Requirements Definition", "improvement_areas": "However, you need to advance your skills to the 'anwenden' level, which involves the ability to independently identify sources of requirements, derive, write, and document requirements in documents or models, and being able to create and analyze context descriptions and interface specifications. To achieve this, you could consider enrolling in advanced requirement management courses or seeking mentorship from a senior systems engineer."}, {"user_strengths": "Your skills in system architecting exceed the required level, as you can identify shortcomings in the process, develop suggestions for improvement, and manage highly complex models. Your ability to recognize deficiencies in the method or modeling language also stands out.", "competency_name": "System Architecting", "improvement_areas": "As your skills are already above the required level, I suggest you maintain your skills through continued practice and consider sharing your expertise with others by mentoring less experienced colleagues."}, {"user_strengths": "You have a solid understanding of test plans, test cases, and results, which is a great foundation for this competency.", "competency_name": "Integration, Verification,  Validation", "improvement_areas": "You need to elevate your skills to the 'anwenden' level, which means you need to be able to create test plans and conduct and document tests and simulations. Consider taking specific courses on software testing, or obtaining hands-on experience through projects or simulations."}, {"user_strengths": "This is an area where you currently lack knowledge.", "competency_name": "Operation and Support", "improvement_areas": "To meet the required 'verstehen' level, you will need to understand how the operation, service, and maintenance phases are integrated into the development. Try to find resources that specifically focus on these topics, and consider reaching out to colleagues with experience in this area for guidance and mentorship."}, {"user_strengths": "You have a good understanding of the fundamentals of Agile workflows and their impact on project success.", "competency_name": "Agile Methods", "improvement_areas": "To reach the 'anwenden' level, you need to be able to work effectively in an Agile environment and adapt Agile techniques to various project scenarios. Consider participating in Agile projects and enrolling in advanced Agile methodology courses."}], "competency_area": "Technical"}]	2024-11-14 10:04:17.027817
6	24	1	[{"feedbacks": [{"user_strengths": "You have shown a strong ability to analyze and derive continuous improvements from your present system, highlighting your application of systems thinking.", "competency_name": "Systems Thinking", "improvement_areas": "To reach the required level of 'beherren', you need to be able to carry systemic thinking into your company and inspire others. Consider hosting workshops or sessions to share your knowledge and insights, and focus on leading by example."}, {"user_strengths": "Your ability to identify, consider, and assess all lifecycle phases relevant to your scope is commendable.", "competency_name": "Lifecycle Consideration", "improvement_areas": "To reach the 'beherrschen' level, you need to be able to evaluate concepts regarding the consideration of all lifecycle phases. A deeper understanding and application of lifecycle analysis tools could be beneficial. Consider seeking more training or mentoring in this area."}, {"user_strengths": "You have a good understanding of how to integrate agile thinking into daily work, which is essential for customer and value orientation.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To advance to the 'beherrschen' level, you need to be able to promote agile thinking within your organization and inspire others. Consider taking on a leadership role in agile projects, or participating in more advanced agile training courses."}, {"user_strengths": "As you are currently unaware or lack knowledge in this competency area, there are significant opportunities for growth.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To reach the 'beherrschen' level, you will need to gain knowledge and skills in systems modeling and analysis. Consider professional training courses, self-study of relevant literature, or finding a mentor experienced in this field. With time and practice, you could not only gain proficiency, but also set guidelines for necessary models and write guidelines for good modeling practices."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have mastered the necessary skills for decision management, which includes evaluating decisions, defining and establishing decision-making bodies, and setting good guidelines for decision-making.", "competency_name": "Decision Management", "improvement_areas": "Since you're already at the required level, you could focus on refining these skills further by seeking out more complex situations where these skills can be applied and challenged."}, {"user_strengths": "You have a solid understanding of the project mandate and can contextualize project management within systems engineering. You're also capable of creating relevant project plans and generating corresponding status reports independently.", "competency_name": "Project Management", "improvement_areas": "However, you need to enhance your skills to the level of being able to identify inadequacies in the process and suggest improvements. Further, you must be capable of communicating reports, plans, and mandates to all stakeholders effectively. To achieve this, consider further training or mentoring in project management, and practice these skills in real projects."}, {"user_strengths": "You are proficient in defining storage structures and documentation guidelines for projects, and providing relevant information at the right place.", "competency_name": "Information Management", "improvement_areas": "To reach the required level, you need to define a comprehensive information management process. This could be achieved by taking on greater responsibilities in your current projects, or by seeking out training or resources that can help you understand and implement comprehensive information management processes."}, {"user_strengths": "You have attained mastery in recognizing all relevant configuration items and creating a comprehensive configuration across all items. You're also able to identify improvements, propose solutions, and assist others in configuration management.", "competency_name": "Configuration Management", "improvement_areas": "Since you're already at the required level, you could focus on continuously refining these skills, staying up-to-date with the latest best practices, and mentoring others in your team."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "Currently, your leadership skills are at the unwissend level, indicating a lack of knowledge in this area.", "competency_name": "Leadership", "improvement_areas": "The required level is beherrschen, which involves strategically developing team members to enhance problem-solving capabilities. This gap indicates a significant need for improvement."}, {"user_strengths": "Your self-organization skills are at the anwenden level, showing that you can independently manage projects, processes, and tasks.", "competency_name": "Self-Organization", "improvement_areas": "However, the required level is beherrschen, which involves mastering the management and optimization of complex projects and processes. This indicates a need for further development in your self-organization skills."}, {"user_strengths": "Your current level in communication is kennen, showing an awareness of the importance of these skills.", "competency_name": "Communication", "improvement_areas": "The required level is beherrschen, which involves sustaining and fairly managing relationships with colleagues and supervisors. This suggests that you need to work on improving your communication skills."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have a solid understanding of how to identify sources of requirements, derive and write them, and you are familiar with different types and levels of requirements. This includes the ability to read and understand complex requirement documents and interface specifications.", "competency_name": "Requirements Definition", "improvement_areas": "To reach the required level of competency, you need to develop the ability to recognize deficiencies in the requirements definition process and suggest improvements. You should also work on creating context and interface descriptions and discussing these with stakeholders."}, {"user_strengths": "You have demonstrated the ability to understand the relevant process steps for architectural models, their inputs, and outputs. You can create architectural models of average complexity, ensuring the information is reproducible and aligned with the methodology and modeling language.", "competency_name": "System Architecting", "improvement_areas": "To reach the required level of competency, you need to develop the ability to identify shortcomings in the process and suggest improvements. Additionally, you should be capable of creating and managing highly complex models, recognizing deficiencies in the method or modeling language, and suggesting improvements."}, {"user_strengths": "You have met the required level of competency in this area. You can independently and proactively set up a testing strategy and an experimental plan. Moreover, you can derive necessary test cases based on requirements and verification/validation criteria, orchestrate and document the tests and simulations.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "N/A"}, {"user_strengths": "You have demonstrated the ability to execute the operation, service, and maintenance phases and identify improvements for future projects.", "competency_name": "Operation and Support", "improvement_areas": "To reach the required level of competency, you need to develop the ability to define organizational processes for operation, maintenance, and servicing."}, {"user_strengths": "N/A", "competency_name": "Agile Methods", "improvement_areas": "This is a significant area for improvement as you currently lack knowledge in this competency area. You need to work on understanding, defining, and implementing Agile methods for a project. Additionally, you should be capable of motivating others to adopt Agile methods and leading Agile teams successfully."}], "competency_area": "Technical"}]	2024-11-14 11:26:52.498975
7	25	1	[{"feedbacks": [{"user_strengths": "You have demonstrated a strong ability to analyze your present system and derive continuous improvements from it. This is a critical skill in systems thinking and aligns well with the required competency level.", "competency_name": "Systems Thinking", "improvement_areas": "As your recorded level matches the required level, continue practicing and applying systems thinking in your work to further solidify your skills."}, {"user_strengths": "Your ability to evaluate concepts regarding the consideration of all lifecycle phases exceeds the required competency level. Your comprehensive understanding of lifecycle phases is commendable.", "competency_name": "Lifecycle Consideration", "improvement_areas": "While you're already exceeding the required level, you might want to focus on how you can leverage your proficiency to contribute to your team or organization. Perhaps you can mentor others or lead initiatives to improve lifecycle consideration practices."}, {"user_strengths": "You have a good understanding of how to integrate agile thinking into daily work, which is crucial in maintaining a customer and value-oriented approach.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To reach the required level of competency, you should focus on developing practical skills in using agile methodologies to develop systems. This could involve additional training or hands-on practice in agile development methods, and paying particular attention to how these methods can enhance customer benefit."}, {"user_strengths": "Your ability to set guidelines for necessary models and write guidelines for good modeling practices is exemplary. You have surpassed the required level.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "While you're exceeding the required competency level, you might want to apply your skills to more advanced or complex system modeling challenges. Additionally, sharing your expertise with your team or mentoring junior colleagues could be a way to further develop your skills and contribute to your organization."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You demonstrate a strong ability in decision management, as evidenced by your ability to prepare and make decisions within your scope and document them adequately. Your use of decision support methods, such as utility analysis, is commendable.", "competency_name": "Decision Management", "improvement_areas": "While you already demonstrate a high level of competency, it would be beneficial to deepen your understanding of different decision support methods as well as the distinction between decisions you can make independently and those that require committee approval."}, {"user_strengths": "Your skills in project management, particularly identifying process inefficiencies and proposing improvements, are exceptional. Your ability to effectively communicate reports, plans, and mandates to all stakeholders is a strong asset.", "competency_name": "Project Management", "improvement_areas": "Despite your high level of competency, it's always good to continuously polish your skills. Consider further honing your ability to define project mandates, establish conditions, create complex project plans, and produce meaningful reports."}, {"user_strengths": "Your ability to define storage structures and documentation guidelines for projects is clear. As is your skill in providing relevant information in the right places.", "competency_name": "Information Management", "improvement_areas": "To further enhance your skills, it would be beneficial to deepen your understanding of the key platforms for knowledge transfer and the information that needs to be shared with different stakeholders."}, {"user_strengths": "Your ability to identify all relevant configuration items and create a comprehensive configuration across all items is impressive. Your contribution to identifying improvements and proposing solutions in configuration management is highly valuable.", "competency_name": "Configuration Management", "improvement_areas": "While you are already quite proficient, there is always room for growth. It could be beneficial to further your understanding of the process of defining configuration items and the use of necessary tools for creating configurations for your scopes."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "Currently, there seems to be limited exposure to leadership concepts within the context of systems engineering.", "competency_name": "Leadership", "improvement_areas": "There is a significant gap in understanding the relevance and importance of defining objectives for a system and communicating these to the team. It's crucial to develop this understanding to meet the required competency level."}, {"user_strengths": "You have a clear understanding of self-organization concepts and how they can influence your daily work. This is an excellent foundation.", "competency_name": "Self-Organization", "improvement_areas": "However, there is a need to progress from understanding to application. This means being able to independently manage projects, processes, and tasks using self-organization skills."}, {"user_strengths": "You excel in communication, demonstrating the ability to communicate constructively and empathetically. This competency is at the required level.", "competency_name": "Communication", "improvement_areas": "As you are already meeting the needed competency level, continue to hone your skills, focusing on understanding how they apply to systems engineering."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "Your ability to recognize deficiencies in the process and develop suggestions for improvement is commendable. Your skill in context and interface descriptions and discussing these with stakeholders is on par with the required level.", "competency_name": "Requirements Definition", "improvement_areas": "You could focus on building your skill to independently identify sources of requirements, derive, write, and document requirements in documents or models."}, {"user_strengths": "You meet the required level in understanding the relevant process steps for architectural models and creating architectural models of average complexity. Keep up the good work in ensuring the information is reproducible and aligned with the methodology and modeling language.", "competency_name": "System Architecting", "improvement_areas": "As your competency meets the required level, you can focus on expanding your knowledge and skills in more complex architectural models."}, {"user_strengths": "Your ability to independently and proactively set up a testing strategy and experimental plan is outstanding. You're doing well in deriving necessary test cases and orchestrating and documenting the tests and simulations.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Even though your current level exceeds the requirements, continuous learning in this area will help you stay ahead."}, {"user_strengths": "Your capability to execute the operation, service, and maintenance phases and identify improvements for future projects is admirable.", "competency_name": "Operation and Support", "improvement_areas": "Even though you meet the required competency level, a deeper understanding of how these phases are integrated into the development could enhance your skills further."}, {"user_strengths": "This is an area of opportunity for you.", "competency_name": "Agile Methods", "improvement_areas": "You'll need to build your proficiency in Agile Methods. Consider undertaking training or obtaining a mentor to gain knowledge and experience in applying Agile techniques to various project scenarios."}], "competency_area": "Technical"}]	2024-11-14 11:39:59.262499
8	19	1	[{"feedbacks": [{"user_strengths": "Your ability to analyze your present system and derive continuous improvements from it is commendable. This ability allows you to effectively apply systems thinking in your work, which is exactly what is required at your level.", "competency_name": "Systems Thinking", "improvement_areas": "Since you're already at the required level, you could consider deepening your knowledge and skills further in this area. This could be through exploring additional resources or engaging in more complex projects that challenge your current understanding."}, {"user_strengths": "You have gone beyond the required level in understanding lifecycle considerations. Your ability to evaluate concepts considering all lifecycle phases is an asset.", "competency_name": "Lifecycle Consideration", "improvement_areas": "To leverage your competency in this area, consider sharing your insights and knowledge with your team. You could also explore opportunities to apply your skills in more complex or larger scale projects."}, {"user_strengths": "Your understanding of how to integrate agile thinking into daily work is a good foundation.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To reach the required level, you need to be able to develop a system using agile methodologies and focus on customer benefit. Consider seeking training or mentorship to improve your skills in agile methodologies and customer-centric design."}, {"user_strengths": "This is an area where you need to focus on to bring your proficiency up to the required level.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "You need to develop your skills to be able to define your own system models for the relevant scope independently. Start by familiarizing yourself with the basics of systems modeling and analysis. Consider enrolling in relevant courses, seeking mentorship, or getting hands-on practice through small projects."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "Your ability to evaluate decisions, define and establish overarching decision-making bodies, and set good guidelines for decision making, surpasses the required level. Your strong comprehension of decision-making structures is commendable.", "competency_name": "Decision Management", "improvement_areas": "Given your proficiency in this area, you could consider further enhancing your skills by exploring more advanced decision support methods and frameworks. This could potentially enable you to make even more informed and effective decisions."}, {"user_strengths": "Your capabilities in defining a project mandate, establishing conditions, creating complex project plans, and producing meaningful reports align perfectly with the expected level. Your communication skills with stakeholders are an asset.", "competency_name": "Project Management", "improvement_areas": "As you are already meeting the required level of competency, consider focusing on refining your skills further. This could involve deepening your understanding of project risk management or exploring advanced project management methodologies."}, {"user_strengths": "Given your current recorded level, it appears that this is a new area for you.", "competency_name": "Information Management", "improvement_areas": "There is a significant gap between your current knowledge and the required level of understanding. Consider basic training to familiarize yourself with key platforms for knowledge transfer and to understand which information needs to be shared with whom. This could involve taking online courses, reading relevant literature, or seeking mentorship."}, {"user_strengths": "You meet the required level of understanding in the process of defining configuration items and identifying those relevant to your scopes. Your ability to use the necessary tools to create configurations is also on point.", "competency_name": "Configuration Management", "improvement_areas": "Since you're meeting the required level, you might want to think about expanding your knowledge. This could include exploring more advanced configuration management tools or studying best practices in configuration management from leading organizations."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have acknowledged the importance of leadership skills, which is a critical first step.", "competency_name": "Leadership", "improvement_areas": "To meet the required level, you need to develop a deeper understanding of the importance of clearly defining objectives for a system and effectively communicating them to your team."}, {"user_strengths": "Your understanding of how self-organization concepts can affect your daily work is commendable.", "competency_name": "Self-Organization", "improvement_areas": "However, to reach the required level, you need to be able to independently manage projects, processes, and tasks using your self-organization skills."}, {"user_strengths": "You are already able to communicate effectively and empathetically, which exceeds the required level.", "competency_name": "Communication", "improvement_areas": "Continue refining your communication skills and seek opportunities to demonstrate them in a systems engineering context."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "Your understanding of how to identify sources of requirements, derive and write them, as well as your ability to read and comprehend requirement documents, context descriptions, and interface specifications is a solid foundation in this competency area.", "competency_name": "Requirements Definition", "improvement_areas": "To reach the required level, you need to develop your skill at independently identifying sources of requirements, documenting them in models, linking, deriving, and analyzing them. Consider enrolling in advanced training sessions or seeking mentorship to help improve these skills."}, {"user_strengths": "Your awareness of the purpose of architectural models and their categorization in the development process is a good start.", "competency_name": "System Architecting", "improvement_areas": "To reach the required level, you need to deepen your understanding of why architectural models are relevant and how to extract relevant information from them. Consider participating in workshops or hands-on practice to enhance your understanding of architectural models."}, {"user_strengths": "Your ability to create test plans and conduct and document tests and simulations meets the requirements for this competency. This is a significant strength that can be further leveraged in your role.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "As you are already at the required level, you might want to consider refining and deepening your skills in this area through ongoing practice and potentially aiming for a higher level of competency."}, {"user_strengths": "Your capability to define organizational processes for operation, maintenance, and servicing exceeds the recorded requirement. Your expertise in this area is commendable.", "competency_name": "Operation and Support", "improvement_areas": "With your advanced skills in this area, you might consider sharing your knowledge with others, perhaps through mentoring or teaching, to help elevate the overall team competency."}, {"user_strengths": "This is a new area for you to explore.", "competency_name": "Agile Methods", "improvement_areas": "Given the requirement to be able to effectively work in an Agile environment and apply the necessary methods, consider taking a foundational course in Agile methodologies. Look for opportunities to engage in Agile projects to gain hands-on experience."}], "competency_area": "Technical"}]	2024-11-14 13:34:01.023626
9	26	1	[{"feedbacks": [{"user_strengths": "You have demonstrated a great understanding of Systems Thinking. Your ability to analyze your present system and derive continuous improvements from it aligns well with the required competency. Your analysis skills play a crucial role in identifying potential opportunities for system improvement.", "competency_name": "Systems Thinking", "improvement_areas": "As you are already meeting the required level, you can focus on refining and advancing your skills. You could consider exploring more complex system scenarios or seeking feedback from peers to get new perspectives and innovative approaches in system analysis."}, {"user_strengths": "Your ability to evaluate concepts regarding the consideration of all lifecycle phases is commendable. You are exceeding the required level which shows your proficiency in understanding and applying lifecycle concepts.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Since you are already exceeding the required level, you could look into sharing your knowledge with others. This may involve mentoring less experienced team members, or offering to lead workshops or discussions on lifecycle consideration. This will not only reinforce your current knowledge but also help you learn from others' perspectives."}, {"user_strengths": "You have a solid understanding of how to integrate agile thinking into daily work. This foundational knowledge is vital as it forms the basis for developing systems that are customer-oriented and value-focused.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To elevate your competency to the required level, consider gaining more practical experience in using agile methodologies. You could collaborate with agile teams, participate in agile workshops, or take on projects that require an agile approach. These experiences will help you develop a system using agile methodologies and focus on customer benefit."}, {"user_strengths": "Your competency in setting guidelines for necessary models and writing guidelines for good modeling practices is evident. You are exceeding the required level, which is indicative of your strong expertise in Systems Modeling and Analysis.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "As you already surpass the required level, consider focusing on enhancing the depth and breadth of your skills in system modeling and analysis. You could also contribute your expertise to the wider team, by leading training sessions or providing guidance on system modeling best practices."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You exhibit a strong understanding of decision management, demonstrating the ability to evaluate decisions, establish decision-making bodies, and define effective decision-making guidelines. This shows that you have a high level of competence in this area.", "competency_name": "Decision Management", "improvement_areas": "Even though your recorded level is high, you may further enhance your competency by focusing on preparing and documenting decisions within your scope, and applying decision support methods such as utility analysis."}, {"user_strengths": "Your understanding of project management within the context of systems engineering is commendable. The ability to create relevant project plans and generate corresponding status reports independently aligns with the required competency level.", "competency_name": "Project Management", "improvement_areas": ""}, {"user_strengths": "You have displayed a high level of competency in information management by defining a comprehensive information management process.", "competency_name": "Information Management", "improvement_areas": "Considering that the required competency level is a basic understanding, you are well beyond the expectations. However, you could further grow by understanding key platforms for knowledge transfer and learning about which information needs to be shared with whom."}, {"user_strengths": "", "competency_name": "Configuration Management", "improvement_areas": "In the area of configuration management, there is significant room for growth. To reach the required level of competency, you will need to gain knowledge on defining sensible configuration items, recognizing those relevant to your scope and using tools to define these items and create configurations."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have demonstrated an understanding of the importance of leadership competencies. This is a crucial first step in becoming a leader.", "competency_name": "Leadership", "improvement_areas": "To reach the required level, you need to further develop your understanding of defining clear objectives for a system and articulating these to your team. Consider participating in leadership workshops or finding a mentor to guide you in this area."}, {"user_strengths": "Your awareness of the concept of self-organization is an excellent starting point. This skill is essential for efficient project management.", "competency_name": "Self-Organization", "improvement_areas": "However, to meet the required level, you need to be able to independently manage projects, processes, and tasks. Try using tools like project management software to help you organize your work, and consider taking courses on time management and prioritization."}, {"user_strengths": "", "competency_name": "Communication", "improvement_areas": "Communication is a key area for improvement. It's crucial to be able to communicate constructively and empathetically with your team. Work on enhancing your communication skills by attending workshops, taking courses, or seeking mentorship. Remember, effective communication is a two-way process that involves listening as well as speaking."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "Your understanding of the basic process of requirement management, including identifying, formulating, deriving, and analyzing requirements, is commendable. You have a clear understanding of the importance of traceability and the tools necessary for it.", "competency_name": "Requirements Definition", "improvement_areas": "Your next steps should involve improving your ability to independently identify sources of requirements, derive, write, and document requirements. This can be achieved through hands-on practice, mentorship, or further training. Consider engaging in projects that allow you to apply these skills under guidance."}, {"user_strengths": "Your knowledge and implementation skills in architectural models are in line with the required competency level. Your ability to create architectural models of average complexity that align with the methodology and modeling language is a great strength.", "competency_name": "System Architecting", "improvement_areas": "Maintaining this level of competency requires continuous learning and application. Consider working on more complex models to deepen your understanding and skills. Engaging with senior architects for mentorship could also be beneficial."}, {"user_strengths": "You excel in setting up a testing strategy and an experimental plan. Your ability to independently derive test cases based on requirements and verification/validation criteria is above the required competency level.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Given your proficiency, consider sharing your knowledge with peers or leading group discussions on the topic. This can help you refine your skills and deepen your understanding of the subject."}, {"user_strengths": "Your ability to execute operation, service, and maintenance phases is impressive. Identifying improvements for future projects is a strength that meets the required competency level.", "competency_name": "Operation and Support", "improvement_areas": "Although you're performing well, there's always room for growth. Consider focusing on understanding how these phases are integrated into development and the activities required throughout the lifecycle. This can be achieved through additional reading or seeking mentorship."}, {"user_strengths": "This area is a learning opportunity as it is currently a gap in your competency profile.", "competency_name": "Agile Methods", "improvement_areas": "Given the requirement level, you should focus on gaining a fundamental understanding of Agile methods and how to apply them in different projects. Consider enrolling in Agile training programs or reading resources on Agile methodologies. Joining an Agile team for hands-on experience can also be beneficial."}], "competency_area": "Technical"}]	2024-11-18 12:22:53.04819
10	27	1	[{"feedbacks": [{"user_strengths": "You have demonstrated a strong ability to carry systemic thinking into the company and inspire others. This is an exceptional strength that goes beyond the required level.", "competency_name": "Systems Thinking", "improvement_areas": "While you're doing an excellent job at leading systemic thinking, don't forget to also focus on analyzing your present system to derive continuous improvements from it."}, {"user_strengths": "You're able to identify the lifecycle phases of your system which is a good start.", "competency_name": "Lifecycle Consideration", "improvement_areas": "However, the required level asks for the ability to identify, consider, and assess all lifecycle phases relevant to your scope. To improve in this area, consider training or mentorship programs that focus on lifecycle management in systems engineering."}, {"user_strengths": "Your ability to promote agile thinking within the organization and inspire others is an impressive skill that exceeds the required level. This shows your strong customer/value orientation.", "competency_name": "Customer / Value Orientation", "improvement_areas": "However, it's also important to demonstrate your ability to develop a system using agile methodologies with a focus on customer benefit. You may find it beneficial to practice this aspect in real project scenarios."}, {"user_strengths": "You have an advanced level of proficiency in setting guidelines for necessary models and writing guidelines for good modeling practices, which surpasses the required level.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "Despite your high level of competency, it's still important to ensure you're able to define your own system models for the relevant scope independently and can differentiate between cross-domain and domain-specific models. Consider reinforcing this skill through further practice or study."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have displayed a mastery of decision management. Your ability to evaluate decisions, define and establish overarching decision-making bodies, and define good guidelines for making decisions is commendable and surpasses the required level.", "competency_name": "Decision Management", "improvement_areas": "Considering the recorded level, you are already exceeding expectations. However, remember to consistently apply decision support methods such as utility analysis, and document your decisions accordingly to maintain your high level of competency."}, {"user_strengths": "Your skills in identifying inadequacies in the process, suggesting improvements, and successfully communicating reports, plans, and mandates to all stakeholders are excellent. You have shown a high level of competency in project management, surpassing the required level.", "competency_name": "Project Management", "improvement_areas": "Although you are exceeding the required level, always strive to refine your ability to define project mandates, establish conditions, create complex project plans, and produce meaningful reports. It will help you to maintain your high competency level."}, {"user_strengths": "Your ability to define a comprehensive information management process is exemplary and surpasses the required level of competency.", "competency_name": "Information Management", "improvement_areas": "Considering the recorded level, you have already exceeded the required competency. However, strive to further your skills in defining storage structures and documentation guidelines for projects, and providing relevant information at the right place."}, {"user_strengths": "You have demonstrated a high level of competency in recognizing all relevant configuration items and creating a comprehensive configuration across all items. Your ability to identify improvements, propose solutions, and assist others in configuration management is commendable and surpasses the required level.", "competency_name": "Configuration Management", "improvement_areas": "Considering the recorded level, you are already exceeding expectations. However, keep up with refining your skills in defining sensible configuration items, recognizing those relevant to you, and using tools to define configuration items and create configurations for your scopes."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have demonstrated a strong ability to develop your team members strategically, enhancing their problem-solving capabilities.", "competency_name": "Leadership", "improvement_areas": "While this is commendable, there is room to enhance your ability to negotiate objectives with your team and find efficient paths to achieve them."}, {"user_strengths": "You have shown an impressive ability to manage and optimize complex projects and processes through self-organization.", "competency_name": "Self-Organization", "improvement_areas": "However, you may want to focus more on demonstrating your ability to independently manage projects, processes, and tasks using self-organization skills."}, {"user_strengths": "Your ability to sustain and fairly manage your relationships with colleagues and supervisors is commendable.", "competency_name": "Communication", "improvement_areas": "Despite your strengths, you could improve your skills in communicating constructively and efficiently while being empathetic towards your communication partner."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "Your proficiency at identifying deficiencies in the process and suggesting improvements is commendable. Your ability to create and discuss context and interface descriptions with stakeholders surpasses the required competency level.", "competency_name": "Requirements Definition", "improvement_areas": "You are already performing at a higher level than what is required. To ensure continuous improvement, consider mentoring peers or junior team members to help them understand and apply requirements definition better."}, {"user_strengths": "Your understanding of why architectural models are relevant as inputs and outputs of the development process meets the required competency level. You are also proficient at extracting relevant information from architectural models.", "competency_name": "System Architecting", "improvement_areas": "Since you are meeting the required competency level, it might be beneficial to delve deeper into understanding various architectural models, their applications, and potential impact on different aspects of system engineering. This could open opportunities for further growth."}, {"user_strengths": "Your ability to independently set up a testing strategy and an experimental plan, and to derive necessary test cases based on requirements and verification/validation criteria, is outstanding and above the required competency level. Your ability to orchestrate and document the tests and simulations is also commendable.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Since you are already performing above the required competency level, you may consider sharing your expertise with others in the team. Providing mentoring or leading workshops could be beneficial for the entire team."}, {"user_strengths": "Your ability to define organizational processes for operation, maintenance, and servicing exceeds the required competency level.", "competency_name": "Operation and Support", "improvement_areas": "With your advanced skills, consider taking the lead in implementing and optimizing operational processes. Additionally, mentoring others in this area could further strengthen your expertise and contribute to the team's knowledge."}, {"user_strengths": "Your ability to define and implement the relevant Agile methods for a project is exceptional. Your conviction about the benefits of using Agile methods and your ability to lead Agile teams successfully surpasses the required competency level.", "competency_name": "Agile Methods", "improvement_areas": "Given your high competency in Agile methods, you could consider promoting a culture of Agile within your organization. This might involve leading training sessions, mentoring colleagues, or actively participating in Agile forums and discussions to share your expertise."}], "competency_area": "Technical"}]	2024-11-18 12:30:34.689875
11	28	1	[{"feedbacks": [{"user_strengths": "You have a strong ability to carry systemic thinking into the company and inspire others, indicating a high level of mastery in Systems Thinking.", "competency_name": "Systems Thinking", "improvement_areas": "Since your recorded level exceeds the required level, continue to mentor others in systems thinking and perhaps consider leading training sessions or workshops to share your expertise."}, {"user_strengths": "You excel in evaluating concepts across all lifecycle phases, showcasing a comprehensive understanding and application.", "competency_name": "Lifecycle Consideration", "improvement_areas": "As your recorded level surpasses the required level, you might look into sharing your insights and strategies with your team or through company-wide presentations to enhance organizational capabilities in lifecycle consideration."}, {"user_strengths": "Your ability to promote agile thinking and inspire others within the organization is exceptional.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Leverage your advanced skills to lead initiatives or projects that directly involve applying agile methodologies to develop systems focused on customer benefits. Your experience could be vital in guiding your team towards more effective practices."}, {"user_strengths": "Your expertise in setting guidelines and writing good practices for systems modeling is a significant asset.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "Utilize your advanced skills to further influence the organization by conducting workshops or creating detailed case studies that demonstrate effective model application. This could help others understand the importance of quality in system modeling and analysis."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You excel in evaluating decisions and have the ability to define and establish overarching decision-making bodies and guidelines, which exceeds the required level of simply preparing or making decisions within your scope.", "competency_name": "Decision Management", "improvement_areas": "Since you already surpass the requirements in decision management, continue to refine your skills by mentoring others, sharing your decision-making frameworks, and engaging in higher complexity decision-making scenarios."}, {"user_strengths": "You are at the required level for understanding project management within systems engineering, including creating project plans and generating status reports.", "competency_name": "Project Management", "improvement_areas": "To evolve further, consider gaining practical experience in managing larger or more complex projects, and seek opportunities for leadership roles within project teams."}, {"user_strengths": "You have mastered defining comprehensive information management processes, surpassing the basic understanding of knowledge transfer platforms and information sharing required.", "competency_name": "Information Management", "improvement_areas": "Leverage your advanced skills by leading initiatives to optimize information flow and ensure that your organization benefits from your deep understanding of information management."}, {"user_strengths": "Your ability to recognize all relevant configuration items and manage comprehensive configurations across all items surpasses the basic requirement of defining and using tools for configurations within your scopes.", "competency_name": "Configuration Management", "improvement_areas": "You could provide guidance and training to others in your organization, helping them to recognize and manage their configuration items effectively. Consider also exploring advanced tools and technologies to further enhance the configuration management process."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "Currently, you are at the beginning of your journey in developing leadership skills.", "competency_name": "Leadership", "improvement_areas": "To reach the required understanding of leadership, start by studying leadership theories and models. Engage in workshops or seminars that focus on leadership skills. Seek opportunities to lead small projects or teams to gain practical experience."}, {"user_strengths": "You have a basic awareness of self-organization concepts.", "competency_name": "Self-Organization", "improvement_areas": "To advance to applying these skills independently in managing projects and tasks, consider using tools like time management apps or project management software. Practice setting clear goals and deadlines for yourself, and regularly assess your progress."}, {"user_strengths": "You excel in managing relationships with colleagues and supervisors effectively.", "competency_name": "Communication", "improvement_areas": "To enhance your communication skills further, focus on adding empathy and efficiency to your interactions. Practice active listening and seek feedback on your communication style from peers or mentors."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "Currently, you are at the beginning stage in this competency.", "competency_name": "Requirements Definition", "improvement_areas": "It's crucial to develop your skills to independently identify, document, and analyze requirements. You should start by familiarizing yourself with the basics of requirements engineering. Online courses, workshops, or textbooks on requirements engineering could be very beneficial. Additionally, participating in projects under the guidance of a more experienced engineer will help accelerate your learning."}, {"user_strengths": "You have a good understanding of why architectural models are important and can extract information from them.", "competency_name": "System Architecting", "improvement_areas": "To meet the required level, you need to advance from understanding to applying this knowledge by creating architectural models of average complexity. Consider engaging in hands-on training or projects where you can practice developing these models under supervision. Learning specific tools and methodologies used in system architecting will also be crucial."}, {"user_strengths": "You are well-equipped to create test plans and conduct tests, which is a strength in this competency.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Your current level exceeds the required understanding; however, it's important to maintain and perhaps share your knowledge with peers. Consider mentoring others or creating resources that help explain the integration, verification, and validation processes."}, {"user_strengths": "You excel in defining organizational processes for operation, maintenance, and servicing, surpassing the required understanding.", "competency_name": "Operation and Support", "improvement_areas": "Since you have mastered this competency, you could focus on sharing your expertise through training sessions or developing guidelines for others. This could help in standardizing processes and improving efficiencies within your organization."}, {"user_strengths": "You are starting from the foundational level in this area.", "competency_name": "Agile Methods", "improvement_areas": "To reach the required level, you must learn to effectively work within an Agile environment. Start by learning the core principles of Agile methodologies through online courses or certifications like Scrum or Kanban. Joining Agile project teams and learning through experience will be invaluable."}], "competency_area": "Technical"}]	2024-11-28 17:23:58.373356
12	32	1	[{"feedbacks": [{"user_strengths": "You are effectively applying systems thinking to analyze and improve your current systems, meeting the required level of competency.", "competency_name": "Systems Thinking", "improvement_areas": "Maintain and continue to enhance your application of systems thinking through regular reviews and updates on latest methodologies."}, {"user_strengths": "Your proficiency in evaluating concepts across all lifecycle phases exceeds the required competency level.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Leverage your advanced skills to mentor others or lead initiatives that focus on lifecycle considerations in your projects."}, {"user_strengths": "Currently, you lack the foundational knowledge in this area.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Start by familiarizing yourself with the basic principles of agile thinking and customer value orientation. Attend workshops or seek mentorship to understand how to integrate these concepts into your daily work."}, {"user_strengths": "You independently define and differentiate system models relevant to your scope, aligning with the required competency level.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "Keep up to date with new tools and methodologies in systems modeling to continuously refine your skills and adapt to evolving project needs."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "Your proficiency in Decision Management is commendable. You excel in evaluating decisions and establishing robust decision-making bodies and guidelines.", "competency_name": "Decision Management", "improvement_areas": "Though your current level already surpasses the required competency, continuous refinement in decision-making processes and staying updated with emerging tools and methodologies will enhance your expertise even further."}, {"user_strengths": "You meet the expectations perfectly in Project Management, demonstrating strong capabilities in defining a project mandate, establishing conditions, creating complex project plans, and communicating effectively with stakeholders.", "competency_name": "Project Management", "improvement_areas": "Maintaining this level is crucial; consider engaging in advanced project management training or certifications to deepen your understanding and stay ahead in your field."}, {"user_strengths": "Your mastery in Information Management is evident as you can define comprehensive information management processes.", "competency_name": "Information Management", "improvement_areas": "To further enhance your prowess, you might explore new technologies and trends in information management to ensure your processes remain cutting-edge and efficient."}, {"user_strengths": "Currently, there are significant gaps in your knowledge of Configuration Management.", "competency_name": "Configuration Management", "improvement_areas": "To meet the required competency, start by familiarizing yourself with the basics of configuration management. Online courses, workshops, or mentoring from a colleague can be beneficial. Focus on understanding how to identify and define configuration items relevant to your scopes."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You demonstrate a strong understanding of how to define system objectives and effectively communicate them to your team, which is crucial for guiding team efforts and ensuring alignment with project goals.", "competency_name": "Leadership", "improvement_areas": "Since there is no further required level specified, continue to refine and apply your leadership skills in various project scenarios to further enhance your capability."}, {"user_strengths": "You are familiar with the concepts of self-organization, which is fundamental for managing your tasks and responsibilities efficiently.", "competency_name": "Self-Organization", "improvement_areas": "To build upon your current knowledge, try to implement more structured self-organization techniques into your daily routine. Consider using tools like task management software or methodologies like Kanban to improve your productivity and self-management."}, {"user_strengths": "Your ability to maintain balanced and fair relationships with colleagues and supervisors showcases your advanced communication skills. This competency is essential for fostering a collaborative and respectful work environment.", "competency_name": "Communication", "improvement_areas": "Continue to nurture and develop your communication skills by taking on roles that require negotiation and conflict resolution, as these experiences will provide further growth and refinement in your interpersonal skills."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You possess a strong foundational understanding of requirement management, including the ability to distinguish between different types of requirements and the importance of traceability.", "competency_name": "Requirements Definition", "improvement_areas": "You need to enhance your skills in independently identifying, deriving, writing, and documenting requirements. Focus on gaining practical experience in handling requirement documents and models, and creating detailed context descriptions and interface specifications."}, {"user_strengths": "Your competency in creating architectural models of average complexity and understanding the processes involved aligns perfectly with the requirements for this role.", "competency_name": "System Architecting", "improvement_areas": "Since you meet the required competency level, continue refining your skills and stay updated with the latest methodologies and tools in system architecting to maintain your proficiency."}, {"user_strengths": "You excel in setting up testing strategies and experimental plans, and in conducting comprehensive tests and simulations.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Given your advanced competency in this area, consider mentoring colleagues or leading initiatives to improve testing strategies within your organization."}, {"user_strengths": "You have a good understanding of the integration of operation, service, and maintenance phases into the development lifecycle.", "competency_name": "Operation and Support", "improvement_areas": "To meet the required competency level, aim to get hands-on experience in executing these phases and identifying improvements for future projects. Participate in projects that allow you to engage directly with these aspects."}, {"user_strengths": "You are highly proficient in defining and implementing Agile methods, leading Agile teams, and motivating others to adopt these practices.", "competency_name": "Agile Methods", "improvement_areas": "Since you are already performing above the required level, you might consider sharing your expertise and experiences with others through workshops or training sessions to further enhance the Agile capabilities of your team."}], "competency_area": "Technical"}]	2024-11-28 21:55:05.263031
13	34	1	[{"feedbacks": [{"user_strengths": "Your ability to analyze the current system and continuously drive improvements is commendable. This skill is vital for maintaining the effectiveness and efficiency of systems in a dynamic environment.", "competency_name": "Systems Thinking", "improvement_areas": "As there is no required level specified, continue refining this competency through practical application and staying updated with the latest systems thinking methodologies."}, {"user_strengths": "You have a basic understanding of the lifecycle phases of your system, which is foundational for systems engineering.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Although no specific improvement is required, you could enhance this understanding by engaging with more detailed lifecycle management practices or training."}, {"user_strengths": "You excel in promoting agile thinking and inspiring others within the organization. This leadership and influence are crucial for fostering a customer-centric and value-oriented culture.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Continue to develop and share your insights on agile practices and customer engagement to further strengthen this competency. Participating in or leading workshops on these topics could be beneficial."}, {"user_strengths": "Your ability to independently define system models and differentiate between cross-domain and domain-specific models shows advanced understanding and application.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To further enhance this skill, consider exploring advanced modeling techniques and tools. Participating in specialized training or collaborative projects can provide practical experience and deeper insights."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You display a high level of proficiency in Decision Management, where you can not only evaluate decisions but also establish decision-making bodies and guidelines effectively.", "competency_name": "Decision Management", "improvement_areas": "Since there's no required level specified, continue to refine and share your expertise, possibly mentoring others in decision-making processes."}, {"user_strengths": "You have a solid grasp of Project Management, capable of defining project mandates, creating detailed project plans, and communicating effectively with stakeholders.", "competency_name": "Project Management", "improvement_areas": "As there's no specific required level, consider expanding your knowledge through advanced project management courses or certifications to enhance your skills further."}, {"user_strengths": "Your understanding of key platforms for knowledge transfer and knowing which information to share with whom is commendable.", "competency_name": "Information Management", "improvement_areas": "To further enhance your competency, you could explore more in-depth training or hands-on experiences in using advanced tools and technologies for information management."}, {"user_strengths": "You excel in Configuration Management, able to manage comprehensive configurations and assist others effectively.", "competency_name": "Configuration Management", "improvement_areas": "Although no improvements are required, continuing to stay updated with the latest trends and tools in configuration management will ensure you remain a valuable asset in this field."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "There is no specific level of competency required in Leadership, which offers flexibility in your personal development in this area.", "competency_name": "Leadership", "improvement_areas": "Given that your current level is at the beginning stage of awareness, consider engaging in leadership training or workshops to gain foundational knowledge. Reading leadership books or seeking mentorship from experienced leaders can also be beneficial."}, {"user_strengths": "You are aware of the concepts of self-organization, aligning with the lack of a specific requirement in this area.", "competency_name": "Self-Organization", "improvement_areas": "To further enhance your skills, you might want to implement self-organization techniques in your daily tasks. Tools like to-do lists, digital planners, or project management software could help improve your efficiency and productivity."}, {"user_strengths": "You have a good understanding of communication, particularly its importance in systems engineering, which goes beyond the current requirements.", "competency_name": "Communication", "improvement_areas": "To further enhance your communication skills, practice active listening and clear, concise messaging in your interactions. Engaging in public speaking clubs like Toastmasters, or taking part in communications workshops, can also sharpen your abilities."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "No specific strengths recorded as the knowledge in this area is currently lacking.", "competency_name": "Requirements Definition", "improvement_areas": "As there is no specific requirement level mentioned for this competency, focusing on gaining a basic understanding could be beneficial for personal development. Consider exploring foundational resources or introductory courses in requirements definition to build a basic knowledge base."}, {"user_strengths": "You have a solid understanding of why architectural models are crucial in the development process and are capable of interpreting these models effectively.", "competency_name": "System Architecting", "improvement_areas": "Even though there is no further requirement specified, you might consider advancing your skills by practicing the creation of architectural models or participating in advanced workshops to deepen your understanding."}, {"user_strengths": "You are proficient in creating test plans and conducting tests and simulations, showcasing strong practical application skills in this area.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "To further enhance your capabilities, you could explore more complex testing scenarios or engage in learning about new testing technologies and methodologies that could improve efficiency and outcomes."}, {"user_strengths": "You demonstrate exceptional ability in defining organizational processes for operation, maintenance, and servicing.", "competency_name": "Operation and Support", "improvement_areas": "To keep your skills sharp and current, consider exploring new trends in operational technologies and support methodologies. Participation in industry conferences and seminars may also provide valuable insights and networking opportunities."}, {"user_strengths": "Your expertise in Agile methods is evident as you can effectively define, implement, and lead Agile projects.", "competency_name": "Agile Methods", "improvement_areas": "To continue your growth in this area, you might look into mentoring others or taking on more strategic roles in Agile transformation projects within your organization to broaden your impact and leadership in Agile practices."}], "competency_area": "Technical"}]	2024-11-28 22:51:08.78756
14	35	1	[{"feedbacks": [{"user_strengths": "You have demonstrated exceptional ability in systems thinking, effectively embedding this approach within the organization and inspiring your colleagues. This level of mastery indicates you not only understand systems thinking but are also a proactive leader in this domain.", "competency_name": "Systems Thinking", "improvement_areas": "Since no further competency level is required, continue to refine and share your expertise. Consider mentoring others or leading workshops to spread your knowledge more broadly."}, {"user_strengths": "Your ability to evaluate concepts across all lifecycle phases shows a deep understanding and proficiency in considering the full spectrum of system development and operation. This competency is crucial for ensuring sustainable and efficient system performance.", "competency_name": "Lifecycle Consideration", "improvement_areas": "As with systems thinking, no additional competency level is required here. However, you could expand your impact by documenting case studies or developing best practice guides based on your experiences."}, {"user_strengths": "You have a good grasp of integrating agile thinking into daily work, which is vital for maintaining customer and value orientation in rapidly changing environments.", "competency_name": "Customer / Value Orientation", "improvement_areas": "While there is no required level to reach, you could enhance your understanding by applying agile principles more broadly in project management and customer interactions. Engaging in additional training or practical experiences could further deepen your competency."}, {"user_strengths": "You excel in setting standards and writing guidelines for systems modeling and analysis, ensuring consistency and quality in modeling practices across projects.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "Since no further competency is required, it could be beneficial to continue leading by example. Consider sharing your methodologies through seminars or writing articles to help others in the field adopt these practices."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "No specific strengths recorded as the user is at the base level in this competency.", "competency_name": "Decision Management", "improvement_areas": "Although no specific required level is indicated, understanding basic decision-making processes could enhance your overall management skills. Consider exploring foundational courses in decision-making to gain a basic understanding of this area."}, {"user_strengths": "You excel in defining project mandates, creating complex project plans, and producing meaningful reports. Your communication with stakeholders is also a strong point.", "competency_name": "Project Management", "improvement_areas": "No improvement is necessary in this area as per the current requirements."}, {"user_strengths": "You have a good grasp of key platforms for knowledge transfer and understand which information needs to be shared with whom.", "competency_name": "Information Management", "improvement_areas": "No improvement is necessary in this area as per the current requirements."}, {"user_strengths": "You demonstrate strong abilities in defining sensible configuration items and using tools to create configurations effectively.", "competency_name": "Configuration Management", "improvement_areas": "No improvement is necessary in this area as per the current requirements."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have a solid understanding of the importance of setting clear objectives for a system and can effectively communicate these objectives to your team.", "competency_name": "Leadership", "improvement_areas": "Since there is no required level specified for leadership, continue to refine and practice your skills, perhaps by taking on more leadership roles in diverse projects to enhance your capability to lead in various scenarios."}, {"user_strengths": "You excel in managing and optimizing complex projects and processes through self-organization, demonstrating a high level of proficiency.", "competency_name": "Self-Organization", "improvement_areas": "Given that there is no required level specified for self-organization, you might consider sharing your expertise with others through mentoring or conducting workshops to help peers improve their self-organization skills."}, {"user_strengths": "Your ability to communicate constructively and empathetically is a valuable asset in your professional interactions.", "competency_name": "Communication", "improvement_areas": "With no specific required level for communication, you could still benefit from exploring advanced communication techniques or participating in communication training programs to further enhance your skills."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "Your strong proficiency in requirements definition, with an ability to recognize deficiencies and develop improvements, is a significant strength. This capability ensures that you can effectively create context and interface descriptions and engage stakeholders in meaningful discussions.", "competency_name": "Requirements Definition", "improvement_areas": "As there is no required level set for this competency, continue to refine and apply your skills, possibly helping others to improve in this area as well."}, {"user_strengths": "You have a good understanding of why architectural models are crucial in the development process and are able to read and interpret these models.", "competency_name": "System Architecting", "improvement_areas": "To enhance your skill in system architecting, consider practicing the creation and manipulation of architectural models yourself. Participating in projects with a strong emphasis on architecture could provide practical experience."}, {"user_strengths": "Currently, there is no recorded proficiency in this area.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Start with basic training or introductory courses on integration, verification, and validation processes. Engaging in projects where you can observe and participate in these activities could greatly enhance your understanding."}, {"user_strengths": "You have a solid understanding of how operation, service, and maintenance phases integrate with development and can outline the required activities.", "competency_name": "Operation and Support", "improvement_areas": "To advance further, consider gaining hands-on experience in the operation and support phases of projects. This could involve shadowing experienced colleagues or taking on roles that involve these phases directly."}, {"user_strengths": "You excel in applying Agile methods, motivating others to adopt them, and leading Agile teams. This is a strong asset in any project environment.", "competency_name": "Agile Methods", "improvement_areas": "As a leader in Agile practices, you could consider sharing your expertise through workshops or mentoring. This not only reinforces your own knowledge but also helps in cultivating an Agile mindset within your team or organization."}], "competency_area": "Technical"}]	2024-11-28 23:03:13.401978
15	36	1	[{"feedbacks": [{"user_strengths": "You have mastered the ability to carry systemic thinking throughout the company and inspire others, which is a significant strength as it goes beyond the required ability to analyze and derive improvements.", "competency_name": "Systems Thinking", "improvement_areas": "Since your recorded level surpasses the required level, there's no need for improvement in this area. Focus on maintaining and sharing this skill within your team to enhance systemic capabilities across your organization."}, {"user_strengths": "You meet the required level of being able to identify, consider, and assess all lifecycle phases relevant to your scope.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Since your recorded level matches the required level, continue practicing and applying this competency to ensure consistent performance and understanding of lifecycle phases in projects."}, {"user_strengths": "You excel in promoting agile thinking and inspiring others within the organization, which exceeds the requirement to develop systems with a focus on customer benefit using agile methodologies.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Focus on applying your ability to inspire others by guiding them in agile practices and ensuring that systems are developed with a strong customer benefit focus. This will bridge the gap between inspirational leadership and practical application."}, {"user_strengths": "Currently, there's a need to develop skills in this area as you are unaware or lack knowledge.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "Engage in training or courses that cover systems modeling and analysis to improve your understanding and ability to define system models independently. Practical hands-on projects or mentorship programs in this area will be very beneficial to build this competency."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have a solid understanding of decision support methods and can distinguish between decisions you can make yourself and those that require committee involvement.", "competency_name": "Decision Management", "improvement_areas": "To meet the required level, focus on enhancing your ability to prepare and make decisions within your scope, and document them effectively. Practice applying decision support methods such as utility analysis by participating in decision-making processes or through simulations in training sessions."}, {"user_strengths": "Currently, knowledge in this area is minimal.", "competency_name": "Project Management", "improvement_areas": "You need to develop basic to advanced project management skills. Start with foundational training in project management principles and methodologies. Engage in projects as an observer or a junior team member to gain hands-on experience. Learning to define project mandates, create project plans, and communicate effectively with stakeholders will be crucial."}, {"user_strengths": "You proficiently define storage structures, set documentation guidelines, and ensure information is accessible where needed.", "competency_name": "Information Management", "improvement_areas": "Since your recorded level matches the required level, continue to enhance your skills by staying updated with the latest practices in information management and exploring advanced tools and techniques to improve efficiency and accuracy."}, {"user_strengths": "You excel in recognizing all relevant configuration items and managing comprehensive configurations across them. You also contribute by identifying improvements and assisting others.", "competency_name": "Configuration Management", "improvement_areas": "Although you are performing above the required level, maintain this competency by staying informed about new tools and practices in configuration management. Share your knowledge with team members and lead initiatives to further improve configuration processes in your organization."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have demonstrated a significant strength in leadership, with a recorded level indicating your ability to strategically develop team members. This ability is advanced and surpasses the required level of merely negotiating objectives.", "competency_name": "Leadership", "improvement_areas": "While you excel in leadership, it would be beneficial to continue applying your skills to new challenges and scenarios to maintain and even enhance your proficiency."}, {"user_strengths": "You have a good understanding of how self-organization concepts can influence your daily work.", "competency_name": "Self-Organization", "improvement_areas": "To meet the required level, focus on applying these concepts to manage projects and tasks more independently. Consider adopting specific tools or methodologies like Kanban or Scrum to enhance your self-organization skills."}, {"user_strengths": "You have a solid understanding of the importance of communication, especially in its application in systems engineering.", "competency_name": "Communication", "improvement_areas": "To elevate your competency to the required level, practice applying these concepts in real-world scenarios. Engage in workshops or training sessions that emphasize practical communication skills, such as active listening and empathetic dialogue."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You meet the required level in Requirements Definition, demonstrating strong ability to independently manage and analyze requirement documents, which is crucial for effective systems engineering.", "competency_name": "Requirements Definition", "improvement_areas": "Continue to refine and update your skills by staying abreast of the latest tools and methodologies in requirements management to maintain your competency at this level."}, {"user_strengths": "You exceed the required competency level in System Architecting, showing advanced capability in managing complex models and identifying improvements in the process.", "competency_name": "System Architecting", "improvement_areas": "Leverage your advanced skills by mentoring others or leading initiatives to improve architectural practices within your organization."}, {"user_strengths": "You meet the required level, showing a good understanding of how to read and interpret test plans and results.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Seek opportunities to enhance your skills beyond understanding to applying these competencies in real-world scenarios, which could involve participating in more hands-on integration or verification activities."}, {"user_strengths": "You understand the fundamental aspects of operation and support phases.", "competency_name": "Operation and Support", "improvement_areas": "Focus on gaining practical experience in executing these phases to meet the required level. You can achieve this by actively participating in these phases in current or future projects, or through workshops and training."}, {"user_strengths": "Currently, you do not have knowledge in this area.", "competency_name": "Agile Methods", "improvement_areas": "Start with foundational training in Agile methodologies. Engage in projects that use Agile methods to gain hands-on experience and gradually build your competency to the required level."}], "competency_area": "Technical"}]	2024-11-28 23:05:37.885676
16	37	1	[{"feedbacks": [{"user_strengths": "You excel in Systems Thinking, demonstrating a mastery level where you inspire others with your systemic thinking capabilities.", "competency_name": "Systems Thinking", "improvement_areas": "Given your current level exceeds the required level, focus on maintaining this competency and possibly mentoring others in your team to elevate their understanding."}, {"user_strengths": "You have a solid understanding of the importance of considering all lifecycle phases during development.", "competency_name": "Lifecycle Consideration", "improvement_areas": "To meet the required level, you should aim to more actively identify, consider, and assess all lifecycle phases relevant to your scope. Engage in practical exercises or projects that require lifecycle analysis and decision-making."}, {"user_strengths": "You are proficient in developing systems with a focus on customer benefit using agile methodologies.", "competency_name": "Customer / Value Orientation", "improvement_areas": "As your current level already exceeds the needed understanding, continue applying this knowledge effectively and keep integrating agile principles into your work."}, {"user_strengths": "Currently, you need to develop your knowledge and skills in this area.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To reach the required level, start by familiarizing yourself with basic system modeling concepts. Participate in relevant training, workshops, or online courses. Engage with peers or mentors who can provide practical insights and guidance in systems modeling and analysis."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have a good understanding of decision support methods and can identify which decisions you can make independently and which require committee involvement.", "competency_name": "Decision Management", "improvement_areas": "To meet the required level, focus on enhancing your ability to prepare and document decisions within your scope. Practice applying decision support methods such as utility analysis in real scenarios."}, {"user_strengths": "You excel in identifying process inadequacies and communicating effectively with stakeholders, which are crucial skills in project management.", "competency_name": "Project Management", "improvement_areas": "Your current competency already meets and exceeds the required level in project management. Continue to refine these skills and possibly mentor others in this area."}, {"user_strengths": "Currently, there is a significant gap in your familiarity with information management.", "competency_name": "Information Management", "improvement_areas": "To reach the required proficiency, start with foundational knowledge in information management. Engage in training sessions, workshops, or online courses to understand and define comprehensive information management processes."}, {"user_strengths": "You are aware of the importance of configuration management and familiar with the tools used.", "competency_name": "Configuration Management", "improvement_areas": "To advance to the required level, focus on learning how to define and recognize sensible configuration items. Gain practical experience in using tools to create and manage configurations effectively for your projects."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have a strong understanding of the importance of defining clear objectives for a system, which is crucial for effective leadership. Your ability to articulate these objectives clearly to the team is a key strength.", "competency_name": "Leadership", "improvement_areas": "As there is no higher required level specified, continue to refine and practice your leadership skills by seeking opportunities to lead diverse projects and mentor junior team members."}, {"user_strengths": "Your competency in managing projects, processes, and tasks independently is commendable. This ability to self-organize is essential in a systems engineering environment.", "competency_name": "Self-Organization", "improvement_areas": "With no further requirements specified, you might consider enhancing these skills by exploring advanced project management tools and techniques to increase efficiency and effectiveness."}, {"user_strengths": "You are aware of the importance of good communication skills in systems engineering.", "competency_name": "Communication", "improvement_areas": "To further develop this competency, actively engage in workshops or training focused on effective communication strategies. Practice these skills in meetings and presentations to enhance your ability to convey complex information clearly and persuasively."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You meet the required competency level for defining, documenting, and analyzing requirements. Your ability to independently handle requirements documentation and analysis is commendable.", "competency_name": "Requirements Definition", "improvement_areas": "Since you are already at the required level, focus on refining your skills further by staying updated with the latest tools and methodologies in requirements management."}, {"user_strengths": "You surpass the required competency level in system architecting, demonstrating advanced capabilities in managing complex models and improving methodologies.", "competency_name": "System Architecting", "improvement_areas": "Leverage your advanced skills by mentoring others or leading projects that require high-level architectural expertise."}, {"user_strengths": "You meet the required competency level for creating and executing test plans, as well as conducting tests and simulations.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "To enhance your skills, consider exploring more sophisticated testing techniques and tools, and participate in advanced training or workshops on integration and verification."}, {"user_strengths": "You exceed the required competency level for managing operational processes, showcasing your ability to define and oversee complex organizational processes.", "competency_name": "Operation and Support", "improvement_areas": "Use your expertise to develop new strategies for optimizing operation and support phases, and share your knowledge through training sessions or guidelines for your colleagues."}, {"user_strengths": "Currently, this is an area where you do not meet the required competency level.", "competency_name": "Agile Methods", "improvement_areas": "Begin by familiarizing yourself with the basics of Agile methodologies. Attend workshops or online courses to understand Agile principles and practices, and try to participate in projects that use Agile methods to gain practical experience."}], "competency_area": "Technical"}]	2024-11-29 10:52:05.078957
17	38	1	[{"feedbacks": [{"user_strengths": "Your ability to analyze your present system and derive continuous improvements shows an advanced application of systems thinking, which surpasses the basic understanding level required.", "competency_name": "Systems Thinking", "improvement_areas": "Although your recorded level surpasses the required level, continuing to deepen your understanding of how individual components interact will further enhance your systems thinking skills."}, {"user_strengths": "Your mastery in evaluating concepts across all lifecycle phases demonstrates a profound understanding and capability that exceeds the basic understanding required.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Since you already exceed the required level, you might consider mentoring others or taking on projects that challenge this competency further to maintain and expand your expertise."}, {"user_strengths": "Currently, there are no recorded strengths in this area as your knowledge does not meet the basic level required.", "competency_name": "Customer / Value Orientation", "improvement_areas": "You need to build a foundation in understanding the fundamental principles of agile thinking. Consider starting with introductory courses in agile methodologies and customer value principles. Engaging in projects with a strong customer focus can also provide practical experience and insights."}, {"user_strengths": "Your understanding of how models support your work aligns perfectly with the required level. Your ability to read simple models is on target.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To further enhance your competency, consider advancing to more complex model analysis and creation. Participating in workshops or courses on advanced systems modeling could be beneficial."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "", "competency_name": "Decision Management", "improvement_areas": "The user currently lacks knowledge in Decision Management, where understanding decision support methods is crucial. This includes knowing the scope of decisions that can be autonomously made and those that require committee involvement."}, {"user_strengths": "The user excels in Project Management, able to identify process inadequacies and effectively communicate with stakeholders, surpassing the required competency level.", "competency_name": "Project Management", "improvement_areas": ""}, {"user_strengths": "The user meets the required level for Information Management, understanding essential knowledge transfer platforms and information sharing protocols.", "competency_name": "Information Management", "improvement_areas": ""}, {"user_strengths": "The user meets the required level for Configuration Management, understanding the importance and tools necessary for effective configuration management.", "competency_name": "Configuration Management", "improvement_areas": ""}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have excelled in the area of leadership, demonstrating a strong capability to develop team members strategically, enhancing their problem-solving skills. This is a higher level than required, which is commendable.", "competency_name": "Leadership", "improvement_areas": "While you have surpassed the required competency level in this area, it could be beneficial to continue refining your ability to articulate system objectives clearly to all team members, ensuring alignment and understanding across your team."}, {"user_strengths": "You meet the required level of understanding in self-organization. Your awareness of how self-organization concepts influence your daily work aligns with what is expected.", "competency_name": "Self-Organization", "improvement_areas": "To further enhance your competence, consider implementing specific self-organization techniques in your daily routines. Experiment with different tools or methodologies to find what works best for enhancing your productivity and efficiency."}, {"user_strengths": "Your awareness of the necessity of communication skills is a good starting point.", "competency_name": "Communication", "improvement_areas": "To meet the required level, you need to deepen your understanding of communication, particularly how it applies in systems engineering. Engage in activities that require you to practice clear and effective communication, such as presenting at meetings or leading group discussions. Additionally, you might consider training or workshops focused on communication skills within a technical context."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You are fully meeting the expectations for the competency in Requirements Definition, demonstrating the ability to independently handle requirements documentation, analysis, and derivation.", "competency_name": "Requirements Definition", "improvement_areas": "There are no gaps in this area as your recorded level aligns perfectly with the required level."}, {"user_strengths": "Your expertise in System Architecting exceeds the required level, showing advanced capabilities in managing complex models and identifying methodological improvements.", "competency_name": "System Architecting", "improvement_areas": "No improvement necessary in terms of competency level, but consider focusing your advanced skills towards mentoring others or leading projects that require high-level architectural expertise."}, {"user_strengths": "You have a basic understanding of the objectives and types of verification and validation.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Enhance your competency by engaging more deeply with test plans, test cases, and results to elevate your understanding from basic knowledge to a more comprehensive understanding."}, {"user_strengths": "You excel in defining organizational processes for operation, maintenance, and servicing, surpassing the basic familiarity required.", "competency_name": "Operation and Support", "improvement_areas": "Leverage your advanced knowledge by contributing to strategic discussions or training colleagues to enhance organizational capabilities in operation and support."}, {"user_strengths": "You meet the required understanding of Agile Methods, knowing how to integrate Agile practices into development processes effectively.", "competency_name": "Agile Methods", "improvement_areas": "Continue to apply and perhaps share your knowledge on Agile practices both within and potentially beyond your current projects to enhance collective performance."}], "competency_area": "Technical"}]	2024-12-01 15:54:18.758365
18	39	1	[{"feedbacks": [{"user_strengths": "You have successfully achieved the required understanding of how individual components interact within a system, which is a fundamental aspect of systems engineering.", "competency_name": "Systems Thinking", "improvement_areas": ""}, {"user_strengths": "You are already applying your knowledge to identify, consider, and assess all lifecycle phases, which goes beyond the required level of simply understanding these phases.", "competency_name": "Lifecycle Consideration", "improvement_areas": "To align with the required competency level, focus on deepening your understanding of why and how all lifecycle phases must be considered during development. This could involve studying case studies that demonstrate the impact of lifecycle considerations on system outcomes."}, {"user_strengths": "You meet the required understanding of how to integrate agile thinking into your daily work. This is crucial in aligning system engineering processes with customer value.", "competency_name": "Customer / Value Orientation", "improvement_areas": ""}, {"user_strengths": "You excel in systems modeling and analysis, demonstrating a mastery level where you can set guidelines and write good modeling practices. This skill is highly valuable and surpasses the basic requirement of understanding how models support work.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "Since your competency exceeds the required level, you might consider sharing your expertise with peers or leading initiatives to improve modeling practices within your organization."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "", "competency_name": "Decision Management", "improvement_areas": "You are currently at the beginning stage of understanding decision management. To meet the required level, you need to become aware of the main decision-making bodies and understand how decisions are made."}, {"user_strengths": "You are already familiar with common project management methods and can identify your activities within a project plan.", "competency_name": "Project Management", "improvement_areas": "Since there is no higher required level specified, continue to refine and apply your knowledge in real-world scenarios to deepen your understanding and proficiency."}, {"user_strengths": "You are able to define storage structures and documentation guidelines for projects, and adept at providing relevant information at the right place.", "competency_name": "Information Management", "improvement_areas": "You currently exceed the requirement for this competency. However, continue to stay updated with the latest platforms for knowledge transfer to enhance your expertise."}, {"user_strengths": "You have a comprehensive understanding of configuration management, able to recognize all relevant configuration items, propose improvements, and assist others.", "competency_name": "Configuration Management", "improvement_areas": "You currently exceed the requirement for this competency. Keep leveraging your advanced skills to lead and innovate within your team."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You are aware of the necessity of leadership competencies, which aligns perfectly with the required level for this competency.", "competency_name": "Leadership", "improvement_areas": "No further improvement is needed in this area as your recorded level meets the required benchmark."}, {"user_strengths": "You understand how self-organization concepts can influence your daily work, which matches the required competency level.", "competency_name": "Self-Organization", "improvement_areas": "No additional improvement necessary as your understanding meets the required expectations."}, {"user_strengths": "You recognize and understand the importance of communication, especially in systems engineering.", "competency_name": "Communication", "improvement_areas": "To meet the required level, focus on applying your communication skills more effectively. Practice being both constructive and empathetic in your interactions. Consider role-playing exercises or communication workshops to enhance your skills."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "Your understanding of how to identify, derive, and write requirements is on par with the required level. Your ability to comprehend different types and levels of requirements, along with reading requirement documents and interface specifications, is commendable.", "competency_name": "Requirements Definition", "improvement_areas": "Since you meet the required level in this competency, continue to deepen your understanding and stay updated with best practices in requirements management."}, {"user_strengths": "Currently, this competency is not required for your role.", "competency_name": "System Architecting", "improvement_areas": "Although not required, gaining a basic understanding of system architecting could enhance your overall systems engineering skills and prepare you for future responsibilities."}, {"user_strengths": "You exceed the required level by being able to create and conduct test plans and simulations.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Leverage your advanced skills by mentoring others or taking on more complex testing projects to further enhance your expertise."}, {"user_strengths": "You possess a mastery level in defining organizational processes for operation, maintenance, and servicing, which is above the required level.", "competency_name": "Operation and Support", "improvement_areas": "Utilize your advanced knowledge to lead initiatives for process improvements and share best practices with your team."}, {"user_strengths": "Your ability to work effectively in an Agile environment and adapt Agile techniques surpasses the basic understanding that is required.", "competency_name": "Agile Methods", "improvement_areas": "Consider taking a role as an Agile coach or mentor to help others understand and apply Agile methods more effectively in your organization."}], "competency_area": "Technical"}]	2024-12-01 16:29:56.729388
19	40	1	[{"feedbacks": [{"user_strengths": "You have a good understanding of how individual components interact within a system.", "competency_name": "Systems Thinking", "improvement_areas": "You need to advance your skills to analyze your present system comprehensively and derive continuous improvements from it. Engage in practical exercises or projects that focus on system analysis and improvement."}, {"user_strengths": "You excel in evaluating concepts regarding the consideration of all lifecycle phases, meeting and exceeding the required level.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Continue to refine and apply your skills to ensure comprehensive lifecycle management in all your projects."}, {"user_strengths": "You understand the integration of agile thinking into daily work.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Develop your ability to implement agile methodologies in system development projects, focusing on maximizing customer benefit. Participate in hands-on agile workshops or work closely with a mentor experienced in agile systems engineering."}, {"user_strengths": "You meet the required level by being able to define your own system models independently for the relevant scope, differentiating between cross-domain and domain-specific models.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "Continue to enhance your modeling skills, possibly exploring more complex or diverse system modeling scenarios to deepen your expertise."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have a strong grasp on evaluating decisions and establishing decision-making guidelines and bodies, which exceeds the basic application required.", "competency_name": "Decision Management", "improvement_areas": "No specific improvements needed in this area as your competency level surpasses the required level."}, {"user_strengths": "Your understanding and ability to manage projects within the context of systems engineering aligns perfectly with the required competency level.", "competency_name": "Project Management", "improvement_areas": "Continue to enhance your skills by applying your knowledge in diverse project scenarios to gain more practical experience."}, {"user_strengths": "Your understanding of key platforms for knowledge transfer and appropriate information sharing meets the required competency level.", "competency_name": "Information Management", "improvement_areas": "Expand your expertise by engaging more actively in using these platforms in different contexts or projects to deepen your practical understanding."}, {"user_strengths": "You are able to apply your knowledge in defining and using tools for configuration items which is beyond the required understanding level.", "competency_name": "Configuration Management", "improvement_areas": "Consider focusing on deepening your understanding of the theoretical principles behind configuration management to complement your application skills."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You are aware of the necessity of leadership competencies, which is a good starting point.", "competency_name": "Leadership", "improvement_areas": "To meet the required level, focus on understanding the relevance of defining objectives clearly and how to articulate these objectives to your team."}, {"user_strengths": "Currently, there is a significant opportunity for development in this area.", "competency_name": "Self-Organization", "improvement_areas": "Start by gaining a basic understanding of self-organization techniques. Progress to managing projects and tasks independently, which is necessary for the required level."}, {"user_strengths": "You excel in managing relationships with colleagues and supervisors, and you meet the required competency level.", "competency_name": "Communication", "improvement_areas": "Continue to enhance your communication skills by focusing on empathy and efficiency in all interactions."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You excel in recognizing deficiencies in the requirements definition process and proposing improvements, creating detailed context and interface descriptions, and engaging with stakeholders effectively.", "competency_name": "Requirements Definition", "improvement_areas": "Your recorded level already surpasses the required level, which means you are well-positioned to continue refining your skills and even mentor others in this competency."}, {"user_strengths": "You have a solid understanding of the importance of architectural models in the development process and are able to extract the necessary information from these models.", "competency_name": "System Architecting", "improvement_areas": "As your recorded level matches the required level, continue practicing this skill by participating in projects that allow you to interact directly with architectural models, deepening your understanding and ability to contribute actively."}, {"user_strengths": "You demonstrate a strong capability in setting up testing strategies, planning experiments, deriving test cases based on requirements, and orchestrating and documenting tests and simulations.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Since your recorded level exceeds the required level, you might consider sharing your expertise and experience in this area with colleagues or seeking more advanced challenges that leverage your high competency."}, {"user_strengths": "You have a good foundational understanding of the operation, service, and maintenance phases and recognize their importance during the development phase.", "competency_name": "Operation and Support", "improvement_areas": "As your recorded level matches the required level, maintaining this knowledge and seeking opportunities to apply it in real-world scenarios will help solidify and expand your understanding."}, {"user_strengths": "You are familiar with Agile values and methodologies, understanding the basic principles involved.", "competency_name": "Agile Methods", "improvement_areas": "To meet the required level of effectively working within an Agile environment, consider engaging in more hands-on Agile projects, seeking mentorship from experienced Agile practitioners, or undertaking targeted training in Agile application techniques."}], "competency_area": "Technical"}]	2024-12-01 16:57:01.301965
20	41	1	[{"feedbacks": [{"user_strengths": "You meet the required level of understanding the interaction of individual components within a system. This indicates a solid grasp of how elements within the system function and relate to each other.", "competency_name": "Systems Thinking", "improvement_areas": "Maintain your current understanding and perhaps expand your knowledge to more complex systems or different types of systems to deepen your expertise."}, {"user_strengths": "You can identify the lifecycle phases of your system, which is foundational.", "competency_name": "Lifecycle Consideration", "improvement_areas": "To meet the required level, you need to advance from recognizing lifecycle phases to understanding their importance and integration during development. Consider studying case studies or participating in projects that focus on the lifecycle from inception to retirement."}, {"user_strengths": "You are already applying agile methodologies which focus on customer benefit. This practical application is commendable and aligns closely with modern engineering practices.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To reach the required understanding of integrating agile thinking into daily work, you might want to explore further training in agile practices or engage more with your agile team to gain deeper insights into the strategic aspects of agile systems engineering."}, {"user_strengths": "Your ability to understand how models support your work and to read simple models aligns with the required level. This competency is crucial for effective systems engineering.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "Since you have achieved the required level, consider advancing your skills to include creating or manipulating complex models, or learning additional modeling tools and techniques."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You are already applying decision support methods and documenting decisions effectively, showing a higher competency level than required.", "competency_name": "Decision Management", "improvement_areas": "To match the required understanding, deepen your knowledge about which decisions need committee involvement and further explore various decision support methods."}, {"user_strengths": "Your ability to create project plans and status reports independently exceeds the required level, which is primarily about identifying activities within a project plan.", "competency_name": "Project Management", "improvement_areas": "Continue to leverage your advanced skills in project management, and consider mentoring others or contributing to organizational best practices in project management."}, {"user_strengths": "You are aware of the benefits of information and knowledge management.", "competency_name": "Information Management", "improvement_areas": "To elevate your understanding, focus on learning the key platforms for knowledge transfer and develop a clear strategy on information sharing within your team or organization."}, {"user_strengths": "Your practical skills in defining and using tools for configuration items are well-developed.", "competency_name": "Configuration Management", "improvement_areas": "To reach the required understanding level, enhance your theoretical knowledge of the configuration process and the criteria for identifying relevant configuration items."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You are able to negotiate objectives with your team and find an efficient path to achieve them, which is a key strength in leadership. This ability indicates that you can effectively manage and guide your team towards common goals.", "competency_name": "Leadership", "improvement_areas": "To meet the required understanding of leadership, focus on articulating these objectives more clearly to your entire team. This could involve refining your communication skills and ensuring that all team members are aligned with the team's goals and objectives."}, {"user_strengths": "Currently, your familiarity with self-organization is limited.", "competency_name": "Self-Organization", "improvement_areas": "To enhance your understanding, start by exploring basic concepts of self-organization and how it can impact your daily work. Consider setting small, personal goals to practice organizing your tasks and responsibilities more effectively. Engage in learning resources or workshops that focus on self-management and organization skills."}, {"user_strengths": "You have a basic awareness of the importance of communication skills.", "competency_name": "Communication", "improvement_areas": "To advance to applying these skills more effectively, practice active listening, and aim to be more empathetic in your interactions. Participating in advanced communication skills workshops or seeking feedback from peers after conversations can help you develop a more constructive and efficient communication style."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You meet the required level in Requirements Definition, displaying a strong understanding of identifying, deriving, and writing requirements as well as comprehension of various requirement types and levels.", "competency_name": "Requirements Definition", "improvement_areas": "As you already meet the required competency level, focus on deepening your expertise through practical application and staying updated with the latest trends and tools in requirements management."}, {"user_strengths": "Your competency in creating architectural models of average complexity exceeds the required understanding level, showcasing your ability to not only understand but also apply architectural concepts in practice.", "competency_name": "System Architecting", "improvement_areas": "Leverage your advanced skills by mentoring others and engaging in more complex projects to further refine your application skills in system architecting."}, {"user_strengths": "You have a basic awareness of the objectives of verification and validation.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Enhance your understanding by engaging with test plans, test cases, and results to move from basic knowledge to a more comprehensive understanding. Consider training sessions or workshops focused on V&V techniques."}, {"user_strengths": "You demonstrate a deeper understanding of the operation, service, and maintenance phases than what is required, indicating a strong grasp of how these integrate into the overall development.", "competency_name": "Operation and Support", "improvement_areas": "While you exceed the requirements, it would be beneficial to share your knowledge with peers or seek opportunities to apply your understanding in practical scenarios to reinforce and expand your skills."}, {"user_strengths": "You are proficient in applying Agile methods in various project scenarios, which is beyond the required level of just understanding the fundamentals.", "competency_name": "Agile Methods", "improvement_areas": "Continue to hone your Agile skills by taking on leadership roles in Agile projects or exploring advanced Agile practices and strategies to maintain your competitive edge."}], "competency_area": "Technical"}]	2024-12-01 16:59:09.712397
21	42	1	[{"feedbacks": [{"user_strengths": "You are proficient at analyzing your current system and identifying areas for continuous improvement, which aligns perfectly with the required level.", "competency_name": "Systems Thinking", "improvement_areas": "None, as your current capabilities meet the required standard."}, {"user_strengths": "You exhibit a higher capability in evaluating lifecycle concepts than is currently required, demonstrating advanced understanding and application.", "competency_name": "Lifecycle Consideration", "improvement_areas": "None, as you exceed the required proficiency level."}, {"user_strengths": "You have a basic understanding of the fundamental principles of agile thinking.", "competency_name": "Customer / Value Orientation", "improvement_areas": "You need to develop the ability to apply agile methodologies effectively and focus more on customer benefits to meet the required level."}, {"user_strengths": "You understand the importance of models in your work and are capable of reading simple models.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "You need to enhance your skills to independently define your own system models and distinguish between cross-domain and domain-specific models to meet the required level."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "Currently, you are at the beginning of your learning journey in Decision Management.", "competency_name": "Decision Management", "improvement_areas": "You need to enhance your ability to prepare and document decisions and apply decision support methods such as utility analysis. Consider enrolling in training programs that focus on decision-making processes and tools."}, {"user_strengths": "You have a good understanding of project management within the context of systems engineering. You can independently create project plans and generate status reports.", "competency_name": "Project Management", "improvement_areas": "Since you are already at the required level in this competency, focus on deepening your knowledge and experience. Look for opportunities to manage more complex projects or take project management certification courses to solidify your expertise."}, {"user_strengths": "You are just starting to develop your knowledge in Information Management.", "competency_name": "Information Management", "improvement_areas": "You need to develop an understanding of key platforms for knowledge transfer and identify relevant information sharing protocols. Engage in training or mentorship to learn about effective information management systems and practices within your organization."}, {"user_strengths": "You understand the process of defining configuration items and are capable of using the necessary tools for creating configurations within your scope.", "competency_name": "Configuration Management", "improvement_areas": "To meet the required competency level, you need to advance your skills to be able to define sensible configuration items more autonomously. Consider participating in advanced training or workshops that focus on best practices in configuration management."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You exhibit a high level of proficiency in leadership, demonstrating the ability to strategically develop team members to enhance their problem-solving skills.", "competency_name": "Leadership", "improvement_areas": "Since your recorded level surpasses the required level, continue honing your strategic leadership skills and start focusing on articulating system objectives clearly to the team to ensure all members are aligned with the project goals."}, {"user_strengths": "You have a foundational understanding of self-organization concepts.", "competency_name": "Self-Organization", "improvement_areas": "To meet the required level, focus on applying your knowledge to manage projects, processes, and tasks independently. Consider practical exercises like leading a small project or task to strengthen your application of self-organization skills."}, {"user_strengths": "Your ability to communicate constructively, efficiently, and empathetically aligns well with what is required.", "competency_name": "Communication", "improvement_areas": "Maintain your current competency level by continuing to engage in active communication practices and seek feedback from peers to refine your approach further."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You are fully meeting the expectations for defining and handling requirements. Your ability to independently identify, derive, document, and analyze requirements is in line with the required competency.", "competency_name": "Requirements Definition", "improvement_areas": "No improvement needed in this area as your recorded level matches the required level."}, {"user_strengths": "You exceed the required level in system architecting. Your ability to manage highly complex models and suggest improvements demonstrates a higher competency than what is required.", "competency_name": "System Architecting", "improvement_areas": "While you are already above the required level, consider leveraging your skills to mentor others or take leadership roles in projects that involve complex system architecting."}, {"user_strengths": "You have a basic understanding of the objectives of verification and validation.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "To reach the required level, focus on deepening your understanding by engaging in training or workshops that cover how to read and interpret test plans, test cases, and results. Practical experience with actual testing scenarios could also be beneficial."}, {"user_strengths": "You are capable of executing operation, service, and maintenance phases effectively.", "competency_name": "Operation and Support", "improvement_areas": "To meet the required understanding of how these phases integrate into the development lifecycle, it would be helpful to study case studies or participate in training that focuses on the lifecycle integration of these phases."}, {"user_strengths": "You possess advanced skills in Agile methodologies, capable of leading teams and motivating others to adopt Agile methods.", "competency_name": "Agile Methods", "improvement_areas": "While you exceed the required competency level, you could use your expertise to facilitate the adoption of Agile practices more widely within your organization or in mentoring roles."}], "competency_area": "Technical"}]	2024-12-01 17:05:31.667967
22	43	1	[{"feedbacks": [{"user_strengths": "You have achieved the required understanding of how individual components interact within a system.", "competency_name": "Systems Thinking", "improvement_areas": "As you already meet the required level, focus on deepening this knowledge through real-world applications and case studies to further enhance your systems thinking skills."}, {"user_strengths": "You effectively identify, consider, and assess all lifecycle phases relevant to your scope, meeting the required competency level.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Continue to apply this knowledge in diverse projects to solidify your understanding and adaptability across different system lifecycles."}, {"user_strengths": "Your ability to promote agile thinking and inspire others in the organization is exceptional and surpasses the required level of simply applying agile methodologies.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Leverage your advanced skills to mentor others in the organization on customer and value orientation, enhancing the overall agility of the team."}, {"user_strengths": "Currently, there is a significant knowledge gap in this area.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "You need to start with foundational training in systems modeling and analysis. Participate in workshops, online courses, or seek mentorship to build your competency to the required level of independently defining and differentiating system models."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have a solid understanding of decision support methods and effectively discern between decisions you can make independently and those that require committee input.", "competency_name": "Decision Management", "improvement_areas": "There is no gap in this competency as you meet the required level of understanding. Continue to apply and deepen your knowledge in real-world decision-making situations to maintain and enhance your skills."}, {"user_strengths": "You are familiar with identifying your activities within a project and understand common project management methods.", "competency_name": "Project Management", "improvement_areas": "To meet the required level, focus on understanding the project mandate in the context of systems engineering. Work on creating project plans and generating status reports independently. Consider undertaking advanced project management training or seeking mentorship from experienced project managers to gain practical insights and hands-on experience."}, {"user_strengths": "You excel in defining comprehensive information management processes, which is beyond the basic understanding required.", "competency_name": "Information Management", "improvement_areas": "Since you already surpass the required level, continue to leverage your expertise to optimize information flow and knowledge transfer within your organization. Stay updated with new tools and platforms to further enhance your proficiency."}, {"user_strengths": "Currently you lack knowledge in configuration management.", "competency_name": "Configuration Management", "improvement_areas": "Begin by gaining a basic understanding of defining configuration items and identifying relevant tools for creating configurations. Start with foundational training in configuration management and seek opportunities to apply these concepts in your projects. Engaging with more experienced colleagues and participating in relevant workshops can also accelerate your learning curve."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have demonstrated the ability to negotiate objectives with your team and efficiently lead them towards these goals.", "competency_name": "Leadership", "improvement_areas": "Focus on deepening your understanding of defining clear and articulate objectives for system development, ensuring that all team members have a shared vision."}, {"user_strengths": "You excel in managing and optimizing complex projects through superior self-organization skills.", "competency_name": "Self-Organization", "improvement_areas": "Continue leveraging your advanced self-organization skills to mentor others and enhance team productivity."}, {"user_strengths": "You are aware of the importance of communication skills in your field.", "competency_name": "Communication", "improvement_areas": "Work on enhancing your understanding of the practical applications of communication in systems engineering, perhaps by engaging in workshops or mentorship programs focused on effective communication."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You meet the expected level of competency for defining and understanding requirements, demonstrating a solid understanding of how to derive and document them effectively.", "competency_name": "Requirements Definition", "improvement_areas": "As you are already at the required level for this competency, focus on maintaining and updating your knowledge as methodologies evolve."}, {"user_strengths": "You meet the required level for creating architectural models and understanding their role within the development process.", "competency_name": "System Architecting", "improvement_areas": "Continue practicing architectural modeling and consider exploring more complex models or new modeling languages to enhance your skills."}, {"user_strengths": "You exceed the required level for this competency, showcasing your ability to set up testing strategies and handle verification and validation processes proficiently.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "You might consider sharing your knowledge with peers or mentoring others who are less experienced in this area, enhancing team capabilities."}, {"user_strengths": "Your understanding of operation, service, and maintenance phases aligns with the required level.", "competency_name": "Operation and Support", "improvement_areas": "To further enhance your competency, you could explore deeper into specific tools or techniques that optimize these phases."}, {"user_strengths": "You exceed the required competency level for Agile Methods, demonstrating strong leadership and ability to implement and motivate others in Agile environments.", "competency_name": "Agile Methods", "improvement_areas": "Consider opportunities to apply your Agile expertise in new or more challenging projects, possibly taking on more strategic roles in Agile transformations."}], "competency_area": "Technical"}]	2024-12-04 22:23:49.924308
23	44	1	[{"feedbacks": [{"user_strengths": "You have mastered systems thinking to the extent of being able to inspire others within your company. Your ability to lead and influence in this area is highly commendable.", "competency_name": "Systems Thinking", "improvement_areas": "As your recorded level surpasses the required level, continue to nurture and spread this competency throughout your organization, potentially by leading workshops or mentoring sessions."}, {"user_strengths": "You meet the required level of competency in considering and assessing all lifecycle phases relevant to your scope.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Since you are already performing at the required level, look for opportunities to deepen your understanding or efficiency in managing lifecycle phases, possibly through specific case studies or advanced training."}, {"user_strengths": "Your ability to promote agile thinking and inspire others in the organization is a significant strength.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Although you exceed the required level in promoting and inspiring agile thinking, focus on further enhancing your skills in developing systems using agile methodologies that emphasize customer benefit. Practical application through projects or additional agile training could be beneficial."}, {"user_strengths": "You are proficient in defining your own system models and differentiating between cross-domain and domain-specific models.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "Since you are meeting the required competency level, consider expanding your expertise by exploring more complex or innovative modeling techniques, or by sharing your knowledge through peer training sessions."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have a good understanding of decision support methods and can identify which decisions are within your responsibility versus those made by committees.", "competency_name": "Decision Management", "improvement_areas": "To meet the required level, focus on enhancing your ability to prepare and make decisions within your scopes, and document them effectively. Practice using decision support tools like utility analysis to become more proficient."}, {"user_strengths": "You comprehend the project mandate well and can independently create project plans and status reports.", "competency_name": "Project Management", "improvement_areas": "Advance to the next level by learning to define project mandates more clearly, create more complex project plans, and improve your reporting skills. Enhancing your communication with stakeholders will also be crucial."}, {"user_strengths": "You excel in defining storage structures and documentation guidelines, and in distributing information effectively.", "competency_name": "Information Management", "improvement_areas": "Although your recorded level is higher than required, ensure you maintain a comprehensive understanding of key platforms for knowledge transfer and continue to assess which information needs to be shared with whom."}, {"user_strengths": "You have a solid understanding of how to define configuration items relevant to your projects and can use necessary tools.", "competency_name": "Configuration Management", "improvement_areas": "To reach the required level, work on enhancing your ability to define sensible configuration items more independently and utilize tools to create these configurations more effectively."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You are actively applying leadership skills in negotiating objectives with your team and efficiently guiding them towards achievement.", "competency_name": "Leadership", "improvement_areas": "To meet the required understanding level, focus on articulating the relevance of these objectives more clearly to your entire team."}, {"user_strengths": "You have a solid understanding of how self-organization can impact your work.", "competency_name": "Self-Organization", "improvement_areas": "To elevate your competency to the required application level, practice using self-organization skills to manage projects and tasks more independently."}, {"user_strengths": "You excel in maintaining and managing relationships with colleagues and supervisors, a level above the required competency.", "competency_name": "Communication", "improvement_areas": "Continue to harness your advanced communication skills to foster constructive and empathetic interactions in your professional environment."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You excel in recognizing deficiencies in the requirements definition process and developing improvement suggestions. Your ability to create and discuss context and interface descriptions with stakeholders is a strong asset.", "competency_name": "Requirements Definition", "improvement_areas": "Focus on further developing your skills in independently identifying sources of requirements, and in the detailed documentation and analysis of these requirements to fully meet and exceed the required competency level."}, {"user_strengths": "You meet the required competency level for creating architectural models of average complexity that are reproducible and aligned with the methodology and modeling language.", "competency_name": "System Architecting", "improvement_areas": "Continue refining your skills in creating architectural models, perhaps by taking on more complex projects or by learning advanced modeling techniques to enhance your proficiency and adaptability in this area."}, {"user_strengths": "Your ability to independently set up testing strategies and experimental plans is exemplary. You also demonstrate strong capabilities in deriving test cases and orchestrating and documenting tests and simulations.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Since your recorded level surpasses the required level, you could focus on sharing your knowledge and expertise with colleagues or seeking opportunities to lead initiatives that enhance testing strategies within your organization."}, {"user_strengths": "You are able to execute operation, service, and maintenance phases effectively, identifying improvements for future projects, which is beyond the required understanding of these phases.", "competency_name": "Operation and Support", "improvement_areas": "Leverage your ability to apply operational knowledge by mentoring others or by documenting best practices in operation and support to contribute to organizational knowledge."}, {"user_strengths": "You effectively work in an Agile environment and are adept at adapting Agile techniques to various project scenarios, fully meeting the competency requirements.", "competency_name": "Agile Methods", "improvement_areas": "Continue to stay updated with the latest trends and advancements in Agile methodologies to maintain your competency and adaptability in various project environments."}], "competency_area": "Technical"}]	2024-12-04 22:37:42.183072
24	45	1	[{"feedbacks": [{"user_strengths": "You already have a practical application level in Systems Thinking, which allows you to analyze and improve current systems effectively.", "competency_name": "Systems Thinking", "improvement_areas": "To meet the required understanding of how individual components interact within a system, consider engaging in cross-functional team projects or undertaking system design courses that emphasize holistic thinking."}, {"user_strengths": "Your understanding of the importance of considering all lifecycle phases during development aligns perfectly with the required level.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Continue to apply this understanding in practical situations and consider sharing your insights with peers or through professional forums to refine your expertise."}, {"user_strengths": "Currently, this is an area needing significant improvement as you are starting from a basic awareness level.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To bridge the gap to the required level of identifying fundamental principles of agile thinking, you might start with introductory courses on agile methodologies and customer-focused design principles. Engaging with customer feedback and incorporating it into your system designs could also be very beneficial."}, {"user_strengths": "You have a basic familiarity with systems modeling and its benefits.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To deepen your understanding to the level where you can effectively utilize models in your work, consider advanced training in systems modeling. Practical application through projects or simulations can significantly enhance your ability to read and interpret complex models."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have a good awareness of the main decision-making bodies and understand how decisions are made, which is crucial in navigating organizational structures.", "competency_name": "Decision Management", "improvement_areas": "To reach the required understanding of decision support methods, consider studying different decision-making models and tools. Engage with mentors or senior colleagues to observe how they handle decision-making processes, and seek opportunities to participate in committees to gain firsthand experience."}, {"user_strengths": "Currently, you are starting from a fundamental level, which provides a unique opportunity to build strong foundational knowledge in project management from the ground up.", "competency_name": "Project Management", "improvement_areas": "To bridge the gap in project management, start with introductory courses on project management principles. Practical experience can be gained through shadowing experienced project managers or volunteering to assist in project tasks within your organization. Regular participation in project meetings can also provide valuable insights and exposure."}, {"user_strengths": "You excel in defining storage structures and documentation guidelines, ensuring that relevant information is efficiently managed and accessible.", "competency_name": "Information Management", "improvement_areas": "Since your recorded level meets the required level, focus on maintaining and enhancing your skills in information management. Consider exploring advanced tools or software that could further streamline information processes and keep abreast of best practices in the field."}, {"user_strengths": "You demonstrate advanced proficiency in recognizing all relevant configuration items and managing comprehensive configurations. Your ability to identify improvements and assist others is particularly commendable.", "competency_name": "Configuration Management", "improvement_areas": "Although your recorded level exceeds the required level, continue to enhance your expertise in configuration management. Stay updated with the latest tools and trends in the field, and consider sharing your knowledge through workshops or training sessions for colleagues."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have demonstrated a strong ability to negotiate and achieve objectives with your team, indicating a practical application of leadership skills.", "competency_name": "Leadership", "improvement_areas": "To align better with the required level, focus on enhancing your ability to articulate objectives clearly to the entire team, ensuring everyone understands and is on the same page."}, {"user_strengths": "You excel in managing and optimizing complex projects through self-organization, indicating a high level of competency.", "competency_name": "Self-Organization", "improvement_areas": "Although your recorded level is beyond the required level, continue to explore how these self-organization skills can be consciously applied to daily work routines to maintain your proficiency."}, {"user_strengths": "Your understanding of the importance of communication in systems engineering aligns well with the expected requirements.", "competency_name": "Communication", "improvement_areas": "Since you meet the required level, continue to practice and refine your communication skills, especially in practical applications within your projects to further enhance your effectiveness."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have a strong ability to independently identify, derive, write, and document requirements, which exceeds the basic understanding required.", "competency_name": "Requirements Definition", "improvement_areas": "You are already performing above the required level, so continue to refine these skills and possibly mentor others or take on more complex projects involving requirements definition."}, {"user_strengths": "Your understanding of why architectural models are relevant aligns perfectly with the expectations.", "competency_name": "System Architecting", "improvement_areas": "No improvements are needed in this area as your competency level matches the required level. Consider deepening your knowledge further or sharing your insights with peers."}, {"user_strengths": "You are aware of the objectives and types of verification and validation.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "To meet the required level, focus on gaining a deeper understanding of how to read and interpret test plans, test cases, and results. Engage in training or practical exercises that involve these aspects."}, {"user_strengths": "You have a strong capability in defining organizational processes for operation, maintenance, and servicing, which exceeds the required understanding.", "competency_name": "Operation and Support", "improvement_areas": "You are already performing above the required level. Continue to apply your advanced knowledge and consider sharing best practices or leading initiatives that enhance operation and support phases."}, {"user_strengths": "Currently, you do not have recorded knowledge in this area.", "competency_name": "Agile Methods", "improvement_areas": "To meet the required level of understanding the fundamentals of Agile workflows and their application, start with introductory courses on Agile methodologies. Engage in team projects that utilize Agile to gain practical experience and understanding."}], "competency_area": "Technical"}]	2024-12-04 22:58:03.568747
25	1	12	[]	2024-12-05 11:05:43.593816
26	46	3	[{"feedbacks": [{"user_strengths": "You meet the required level of understanding the interaction of individual components within a system.", "competency_name": "Systems Thinking", "improvement_areas": "Since you are meeting expectations, focus on maintaining this competency and possibly exploring deeper applications of systems thinking in practice."}, {"user_strengths": "Currently, there is a significant gap in this competency.", "competency_name": "Lifecycle Consideration", "improvement_areas": "You need to develop an understanding and ability to identify, consider, and assess all lifecycle phases relevant to your scope. Start with basic training on lifecycle models and gradually apply this knowledge to real projects to move towards the application level."}, {"user_strengths": "You exceed the required understanding by being able to apply agile methodologies focusing on customer benefit.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Continue applying agile principles and integrate this competency into broader areas of your work to maintain and enhance your effectiveness."}, {"user_strengths": "You have mastered the ability to set guidelines and write good modeling practices, exceeding the requirement to just understand model support.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "Continue to lead in this area by mentoring others and sharing your extensive knowledge in systems modeling and analysis."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You already have a good understanding of decision support methods and can identify which decisions you can make independently.", "competency_name": "Decision Management", "improvement_areas": "To elevate your skills to the required level, focus on applying these methods more independently in your projects and documenting the decisions you make. Consider practicing utility analysis or similar techniques in real scenarios."}, {"user_strengths": "You exhibit excellent command in project management, being able to suggest process improvements and communicate effectively with stakeholders.", "competency_name": "Project Management", "improvement_areas": "As your recorded level surpasses the required level, continue refining your skills and possibly mentor others in your team to enhance their understanding of project management."}, {"user_strengths": "You meet the required awareness level for the benefits of established information and knowledge management.", "competency_name": "Information Management", "improvement_areas": "To further strengthen this area, consider exploring deeper into practical applications of information management systems and how they can be leveraged in your current projects."}, {"user_strengths": "You have a solid understanding of defining configuration items and using necessary tools, which is more advanced than the required awareness level.", "competency_name": "Configuration Management", "improvement_areas": "You might explore further into the strategic impacts of configuration management in systems engineering to enhance your expertise, even though your current understanding already exceeds the required level."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have a foundational awareness of the importance of leadership skills in systems engineering.", "competency_name": "Leadership", "improvement_areas": "You need to deepen your understanding of how to define and articulate system objectives clearly to a team. This involves learning more about strategic communication and goal-setting within the context of leading a team."}, {"user_strengths": "You demonstrate a strong ability to manage projects, processes, and tasks independently, which is a significant strength in systems engineering.", "competency_name": "Self-Organization", "improvement_areas": "To meet the required level, focus on understanding how self-organization impacts your daily work and overall project outcomes. This could involve studying case studies or engaging in discussions that highlight the benefits of effective self-organization in engineering projects."}, {"user_strengths": "Currently, this is an area that needs significant development, as you are starting from an initial level of awareness.", "competency_name": "Communication", "improvement_areas": "It is crucial that you focus on building your knowledge in communication skills, specifically understanding its importance and application within systems engineering. Consider enrolling in workshops, participating in team meetings as an observer to learn communication dynamics, or seeking mentorship from a skilled communicator within your organization."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You excel in Requirements Definition, with the ability to recognize deficiencies and develop improvements, as well as create and discuss context and interface descriptions with stakeholders.", "competency_name": "Requirements Definition", "improvement_areas": "Since your recorded level surpasses the required level, focus on leveraging this strength to mentor others or take on leadership roles in projects that heavily rely on strong requirements definition skills."}, {"user_strengths": "You understand the relevance of architectural models in the development process and can effectively extract information from these models.", "competency_name": "System Architecting", "improvement_areas": "To enhance your skills, aim to deepen your understanding of architectural methodologies and modeling languages. Engage in training or workshops that focus on architectural modeling to elevate your competency to a more advanced level."}, {"user_strengths": "Currently, this is an area that needs significant attention as you are unfamiliar with it.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "To meet the required level, begin by understanding the objectives of verification and validation, and familiarize yourself with various types and approaches. Consider enrolling in introductory courses or seeking mentorship in this area to build a foundational knowledge."}, {"user_strengths": "You have a good understanding of how operation, service, and maintenance phases integrate into development, and you know the activities involved throughout the lifecycle.", "competency_name": "Operation and Support", "improvement_areas": "To bridge the gap to the required familiarity with the stages of operation, service, and maintenance, consider engaging more with practical aspects or case studies that focus on these phases in real-world scenarios."}, {"user_strengths": "You are highly proficient in Agile Methods, effectively working in Agile environments and adapting techniques to various projects.", "competency_name": "Agile Methods", "improvement_areas": "Since you exceed the required understanding of Agile fundamentals, you might explore advanced Agile strategies or take on a coaching role to help team members understand and implement Agile methods more effectively."}], "competency_area": "Technical"}]	2024-12-05 11:18:18.912072
27	47	3	[{"feedbacks": [{"user_strengths": "You are proficient in analyzing your current system and deriving continuous improvements from it, which aligns perfectly with the required competency level.", "competency_name": "Systems Thinking", "improvement_areas": "Since you are already performing at the required level, focus on maintaining this competency through regular practice and staying updated with new systems thinking methodologies."}, {"user_strengths": "You have a strong grasp of evaluating concepts regarding all lifecycle phases, which exceeds the current requirement.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Leverage your advanced skills to mentor others or to take on more complex projects that require a deep understanding of lifecycle phases."}, {"user_strengths": "You understand the fundamental principles of agile thinking.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To meet the required level, you need to develop practical skills in applying agile methodologies to system development focusing on customer benefits. Consider enrolling in an advanced agile development course or participating in agile project teams to enhance your application skills."}, {"user_strengths": "Currently, you lack knowledge in this area.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To reach the required level, begin with foundational courses or workshops in systems modeling and analysis. Engage in projects that allow you to practice building system models, perhaps under the guidance of a mentor."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You are fully meeting the required level in Decision Management. Your ability to prepare and document decisions effectively, as well as apply decision support methods like utility analysis, is a significant strength.", "competency_name": "Decision Management", "improvement_areas": "As you continue to maintain your competency, consider expanding your decision-making techniques and exploring more advanced decision support tools to further enhance your skill set."}, {"user_strengths": "You have a basic understanding of your role within project management and are familiar with common project management methods.", "competency_name": "Project Management", "improvement_areas": "To meet the required competency level, you should focus on gaining skills in defining project mandates, creating complex project plans, and producing meaningful reports. Enhancing your communication with project stakeholders will also be crucial. Consider enrolling in advanced project management courses or seek mentorship from experienced project managers to build these skills."}, {"user_strengths": "You have exceeded the required competency level in Information Management by being able to define a comprehensive information management process.", "competency_name": "Information Management", "improvement_areas": "Leverage your advanced understanding to mentor others or to take on more strategic roles in information management within your projects. You can also explore the latest trends and technologies in this field to ensure your skills remain cutting-edge."}, {"user_strengths": "You understand the fundamentals of defining configuration items and using necessary tools.", "competency_name": "Configuration Management", "improvement_areas": "To reach the required level, focus on enhancing your ability to define sensible configuration items and use tools more effectively to create configurations. Practical experience through hands-on projects or workshops can be very beneficial. Additionally, collaborating with experienced peers or seeking feedback on your configuration management tasks can provide valuable insights and growth."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You excel in strategic development of team members, helping them enhance their problem-solving skills.", "competency_name": "Leadership", "improvement_areas": "Your current level exceeds the required competency, so continue to leverage and possibly share your expertise with others who may benefit from your leadership skills."}, {"user_strengths": "You meet the required competency level in managing projects, processes, and tasks independently.", "competency_name": "Self-Organization", "improvement_areas": "Maintain your current level of self-organization and seek continuous improvement by exploring new tools and methodologies to enhance efficiency."}, {"user_strengths": "You understand the importance and relevance of communication in systems engineering.", "competency_name": "Communication", "improvement_areas": "To meet the required level, focus on applying your communication skills more constructively and efficiently in work scenarios. Engage in activities that require team collaboration, seek feedback, and participate in workshops or training focused on effective communication techniques."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You meet the required level of understanding in identifying, deriving, and writing requirements, as well as in reading and understanding requirement documents and interface specifications.", "competency_name": "Requirements Definition", "improvement_areas": "While you meet the required level, continuous improvement and staying updated with the latest best practices in requirements management can enhance your proficiency."}, {"user_strengths": "You exceed the required level with a deep capability in creating and managing complex models, identifying deficiencies, and suggesting improvements.", "competency_name": "System Architecting", "improvement_areas": "Given your advanced skills, consider mentoring others or leading workshops to share your knowledge and methods in system architecting."}, {"user_strengths": "Your ability to create and conduct tests goes beyond the basic understanding required.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Focus on deepening your understanding of why specific tests are chosen and their impact on the overall system to align your practical skills with a comprehensive theoretical understanding."}, {"user_strengths": "Your understanding of how operation, service, and maintenance phases are integrated matches the required level.", "competency_name": "Operation and Support", "improvement_areas": "Explore advanced topics like predictive maintenance or AI-driven support systems to expand your expertise beyond the foundational level."}, {"user_strengths": "You possess a higher mastery in Agile methods than required, capable of leading teams and motivating the adoption of Agile practices.", "competency_name": "Agile Methods", "improvement_areas": "Since you have a high proficiency, you might explore how to further innovate or refine Agile practices specifically tailored to systems engineering or complex multi-disciplinary projects."}], "competency_area": "Technical"}]	2024-12-05 11:34:50.763131
28	48	12	[{"feedbacks": [{"user_strengths": "You have demonstrated the ability to analyze and improve existing systems effectively.", "competency_name": "Systems Thinking", "improvement_areas": "To meet the required understanding of how components interact within a system, engage in training or projects that focus on system dynamics and interactions. Collaborate with experienced colleagues to see practical examples of system interactions."}, {"user_strengths": "Your competency in evaluating lifecycle concepts is above the required level, showcasing your deep understanding and application in this area.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Continue to apply your knowledge in evaluating lifecycle concepts to maintain your advanced skills and consider sharing your insights with team members."}, {"user_strengths": "Your understanding of integrating agile thinking aligns perfectly with the required level.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Maintain your current understanding and stay updated with the latest trends in agile methodologies to keep your skills relevant."}, {"user_strengths": "You have a basic familiarity with modeling and its benefits.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To elevate your understanding, participate in workshops or online courses focusing on systems modeling. Practical application through projects will also help you better understand how models can be read and utilized effectively."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "Your ability to evaluate decisions, define decision-making bodies, and create guidelines for decision-making is notably strong, which exceeds the required level of competency.", "competency_name": "Decision Management", "improvement_areas": "Focus on utilizing your advanced skills to mentor others or lead initiatives that further streamline decision-making processes across the organization."}, {"user_strengths": "You have demonstrated strong capabilities in defining project mandates, managing complex projects, and engaging with stakeholders effectively. Your competency goes beyond the basic understanding required.", "competency_name": "Project Management", "improvement_areas": "Leverage your skills to help standardize project management practices or train other team members to elevate the overall project management quality within your team."}, {"user_strengths": "You have a solid understanding of key platforms for knowledge transfer and appropriate information sharing.", "competency_name": "Information Management", "improvement_areas": "Further enhance your knowledge by focusing on the strategic benefits and broader impacts of effective information management on organizational success."}, {"user_strengths": "Your practical ability in defining and managing configuration items, and using tools for creating configurations is excellent.", "competency_name": "Configuration Management", "improvement_areas": "You could enhance your foundational knowledge about the principles of configuration management to strengthen your practical applications and share this knowledge with peers."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have demonstrated an advanced level of leadership, being able to strategically develop team members and enhance their problem-solving capabilities. This goes beyond the basic understanding of setting and communicating objectives, showcasing your ability to lead effectively in dynamic environments.", "competency_name": "Leadership", "improvement_areas": "While your leadership skills are highly developed, consider focusing on refining the clarity with which you define and communicate system objectives to ensure all team members are aligned and motivated."}, {"user_strengths": "Your understanding of how self-organization concepts can influence your daily work aligns perfectly with the required level.", "competency_name": "Self-Organization", "improvement_areas": "To further enhance your skills, you might explore deeper applications of self-organization in your work environment, seeking to implement practices that improve productivity and personal management."}, {"user_strengths": "You excel in communication, applying empathy and efficiency in your interactions, which surpasses the basic understanding required.", "competency_name": "Communication", "improvement_areas": "To leverage your communication skills further, consider mentoring others in communication strategies or exploring advanced communication techniques that can be beneficial in complex systems engineering projects."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have mastered the ability to recognize deficiencies in the requirements definition process and can effectively create and discuss context and interface descriptions with stakeholders, which is beyond the required understanding of identifying and writing requirements.", "competency_name": "Requirements Definition", "improvement_areas": "Your current skill set already surpasses the required level, ensuring that you maintain this competency. Consider sharing your expertise with peers or engaging in mentoring to help others improve their skills in this area."}, {"user_strengths": "You possess practical skills in creating architectural models of average complexity and ensuring that these models are reproducible and aligned with methodology and language, which is above the basic awareness required.", "competency_name": "System Architecting", "improvement_areas": "Continue refining your skills and possibly explore more complex architectural modeling to extend your expertise further. Engaging in advanced workshops or specialist training could also enhance your capabilities in this domain."}, {"user_strengths": "You are capable of creating test plans and conducting and documenting tests and simulations, which exceeds the basic awareness of the objectives of verification and validation that is required.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Since you already surpass the required level in this competency, maintaining your current skill set and staying updated with new testing technologies and methodologies will be beneficial. You could also consider contributing to knowledge sharing sessions or workshops on V&V within your organization."}, {"user_strengths": "You are proficient in defining organizational processes for operation, maintenance, and servicing, which is above the basic familiarity with operation and support phases required.", "competency_name": "Operation and Support", "improvement_areas": "To leverage your advanced skills, consider taking a leadership role in operations and support processes or contributing to strategic planning in these areas within your organization."}, {"user_strengths": "You are able to effectively work in an Agile environment and adapt Agile techniques to various project scenarios, which surpasses the required level of understanding Agile fundamentals and application within a development process.", "competency_name": "Agile Methods", "improvement_areas": "Continue honing your Agile skills by staying engaged with the latest Agile practices and potentially leading Agile transformation initiatives within your organization. Participating in advanced Agile training or obtaining certifications could also further your expertise."}], "competency_area": "Technical"}]	2024-12-05 11:39:07.894173
29	49	1	[{"feedbacks": [{"user_strengths": "You have developed a robust capability in Systems Thinking, allowing you to analyze and improve current systems effectively.", "competency_name": "Systems Thinking", "improvement_areas": "No improvement needed as your recorded level meets the required level."}, {"user_strengths": "You have a good understanding of the importance of considering all lifecycle phases during development.", "competency_name": "Lifecycle Consideration", "improvement_areas": "To elevate your competency, focus on applying this understanding in practical scenarios. Engage in projects that allow you to plan and assess lifecycle phases, perhaps through a mentorship program or targeted training sessions."}, {"user_strengths": "You excel in promoting agile thinking and inspiring others within your organization.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Despite your high competency in agile thinking, the focus now should be on using agile methodologies specifically for system development and enhancing customer benefit. Consider undertaking projects that require agile development practices, and seek feedback from customers to fine-tune this approach."}, {"user_strengths": "You understand the support that models provide and are capable of reading simple models.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To reach the required level, begin practicing the creation of your own system models. Start with small, manageable projects and use resources like workshops or online courses to learn about different modeling techniques and tools. Collaborate with experienced modelers to gain insights and practical experience."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have a solid understanding of decision-making bodies and the processes involved in making decisions.", "competency_name": "Decision Management", "improvement_areas": "To reach the required level, focus on developing your ability to prepare and make decisions independently. Practice applying decision support methods like utility analysis to enhance your decision-making skills."}, {"user_strengths": "You have a good grasp of the project mandate and the ability to create project plans and status reports.", "competency_name": "Project Management", "improvement_areas": "You need to enhance your skills in defining project mandates and creating complex project plans. Additionally, work on improving your stakeholder communication skills to effectively manage and report on projects."}, {"user_strengths": "You meet the required level by effectively defining storage structures, setting documentation guidelines, and managing information flow within projects.", "competency_name": "Information Management", "improvement_areas": "Continue to refine and update your knowledge and practices in information management to maintain your competency, especially with the evolving technologies and methodologies."}, {"user_strengths": "You exceed the required level, demonstrating expertise in identifying relevant configuration items and managing comprehensive configurations.", "competency_name": "Configuration Management", "improvement_areas": "Leverage your advanced skills by mentoring others in configuration management and proposing improvements to existing processes within your organization."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "Your leadership skills are exemplary, showcasing a high level of mastery in developing strategic capabilities within your team.", "competency_name": "Leadership", "improvement_areas": "Despite meeting and exceeding the required level, continue to sharpen your negotiation skills to ensure objectives are clearly communicated and efficiently achieved."}, {"user_strengths": "Currently, there is a significant opportunity for growth in this area.", "competency_name": "Self-Organization", "improvement_areas": "It's crucial to develop foundational skills in managing projects and tasks independently. Consider enrolling in time management and project management workshops or courses to build these skills."}, {"user_strengths": "You have a basic awareness of the importance of effective communication.", "competency_name": "Communication", "improvement_areas": "To meet the required level, focus on enhancing your ability to communicate constructively and empathetically. Practice active listening, ask for feedback on your communication style, and possibly engage in communication skills training."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You fully meet the expected standard for defining and understanding requirements. Your knowledge in identifying sources, deriving, writing, and understanding different types and levels of requirements is commendable.", "competency_name": "Requirements Definition", "improvement_areas": "No improvement needed as your recorded level matches the required level."}, {"user_strengths": "You exceed the required competency level in system architecting. Your ability to create architectural models of average complexity and ensure that the information aligns with methodology and modeling language is a strong asset.", "competency_name": "System Architecting", "improvement_areas": "While you already exceed the required level, consider enhancing your understanding of the strategic importance of these models in the overall development process for even broader impact."}, {"user_strengths": "You are highly skilled in setting up testing strategies, experimental plans, and orchestrating documentation processes. Your competency surpasses the required level, showcasing your expertise in handling complex testing scenarios.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Continue to refine your skills and perhaps consider sharing your knowledge through mentorship or leading advanced workshops to benefit others in your team."}, {"user_strengths": "You meet the required competency level for understanding and integrating operation, service, and maintenance phases into development. Your ability to outline necessary lifecycle activities is on point.", "competency_name": "Operation and Support", "improvement_areas": "No improvement needed as your recorded level matches the required level."}, {"user_strengths": "You have a basic understanding of Agile values and methods, which is foundational.", "competency_name": "Agile Methods", "improvement_areas": "To reach the required level, focus on gaining practical experience in Agile environments. Participate in projects that use Agile methodologies and seek training or mentorship to apply Agile techniques effectively in various scenarios."}], "competency_area": "Technical"}]	2024-12-05 11:40:45.889468
30	50	1	[{"feedbacks": [{"user_strengths": "You have achieved the required level in Systems Thinking, which enables you to continuously improve the systems you work with.", "competency_name": "Systems Thinking", "improvement_areas": "Since you have met the required level, focus on maintaining and enhancing this skill through ongoing practice and staying updated with new systems thinking methodologies."}, {"user_strengths": "You exceed the required level in Lifecycle Consideration, demonstrating an ability to evaluate concepts encompassing all lifecycle phases comprehensively.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Leverage your advanced skills to mentor others or lead projects that require a deep understanding of lifecycle phases. This could help in spreading best practices within your team or organization."}, {"user_strengths": "You have a good understanding of integrating agile thinking into daily work.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To meet the required level, focus on practicing the development of systems using agile methodologies. Engage in projects that allow you to apply agile practices extensively, and consider training or workshops that emphasize agile development and customer focus."}, {"user_strengths": "You demonstrate a strong command in Systems Modeling and Analysis, capable of setting guidelines and writing good modeling practices.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "Utilize your expertise to guide your colleagues or contribute to organizational standards on modeling. Although you are above the required level, continuous learning about emerging modeling techniques and tools can further enhance your competency."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "Your ability to evaluate decisions and establish decision-making bodies is a significant strength. You also excel in defining good guidelines for decision-making processes.", "competency_name": "Decision Management", "improvement_areas": "Since your recorded level exceeds the required level in decision management, continue to refine and apply your skills in new and more complex scenarios, ensuring your decision-making strategies remain effective and adaptable."}, {"user_strengths": "You have a good understanding of the project mandate and the ability to create relevant project plans and status reports.", "competency_name": "Project Management", "improvement_areas": "To meet the required level, focus on enhancing your skills in defining project mandates and establishing conditions. Aim to create more complex project plans and improve your communication with stakeholders. Engaging in advanced project management training programs or workshops can be beneficial."}, {"user_strengths": "You are aware of the benefits of established information and knowledge management.", "competency_name": "Information Management", "improvement_areas": "To elevate your competency to the required level, focus on learning how to define storage structures and documentation guidelines. Practical experience or targeted training in information management systems will be crucial. Consider seeking mentorship from experienced information managers in your organization."}, {"user_strengths": "Currently, there is a need to develop foundational knowledge in this area.", "competency_name": "Configuration Management", "improvement_areas": "Start by familiarizing yourself with the basics of configuration management. Engage in introductory courses or training sessions and seek guidance from experts within your organization. Practical hands-on experience, such as small projects involving configuration management, will also be invaluable in building your skills to meet the required level."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have mastered the strategic development of team members, enhancing their problem-solving capabilities.", "competency_name": "Leadership", "improvement_areas": "Although you surpass the required level, consider focusing on applying these leadership skills more directly to negotiating and achieving team objectives efficiently."}, {"user_strengths": "Your self-organization skills are at the required level, enabling you to manage projects, processes, and tasks independently.", "competency_name": "Self-Organization", "improvement_areas": "To further enhance your skills, consider exploring advanced tools and methodologies for project management to stay ahead in managing complex systems engineering tasks."}, {"user_strengths": "You have a good understanding of the importance of communication within systems engineering.", "competency_name": "Communication", "improvement_areas": "To meet the required level, focus on enhancing your ability to communicate constructively and empathetically. Practice active listening, engage in role-playing exercises, and seek feedback to improve your communication effectiveness."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have a solid understanding of how to identify sources of requirements and the ability to read and understand requirement documents or models.", "competency_name": "Requirements Definition", "improvement_areas": "To advance, focus on enhancing your skills in independently deriving, writing, and documenting requirements. Practice linking and analyzing requirements to move from understanding to application level."}, {"user_strengths": "You are familiar with the purpose of architectural models and know about the dedicated methodology for architectural modeling.", "competency_name": "System Architecting", "improvement_areas": "Develop your ability to read and extract information from architectural models to achieve a deeper understanding of their relevance in the development process."}, {"user_strengths": "You are proficient in creating test plans and conducting and documenting tests and simulations, meeting the required competency level.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Continue practicing and perhaps expand your expertise into more complex testing scenarios or different types of systems to remain sharp and possibly exceed the current requirements."}, {"user_strengths": "You excel in defining organizational processes for operation, maintenance, and servicing, surpassing the required understanding level.", "competency_name": "Operation and Support", "improvement_areas": "Leverage your advanced skills to mentor others or to innovate processes within your organization, even though no further improvement is needed for meeting the required level."}, {"user_strengths": "You have a good grasp of Agile fundamentals and the impact of Agile practices on project success.", "competency_name": "Agile Methods", "improvement_areas": "Focus on applying Agile methods more effectively within various project scenarios. Engage in hands-on Agile projects to transition from understanding to application of Agile techniques."}], "competency_area": "Technical"}]	2024-12-05 15:09:47.441329
31	51	1	[{"feedbacks": [{"user_strengths": "You have achieved the required level in Systems Thinking, demonstrating the ability to analyze your present system and derive continuous improvements effectively.", "competency_name": "Systems Thinking", "improvement_areas": "Since you are already at the required level, focus on refining this skill by applying it in new, varied contexts to gain a broader perspective and deeper understanding."}, {"user_strengths": "You exceed the required level in Lifecycle Consideration, showcasing advanced capability in evaluating concepts across all lifecycle phases.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Leverage your advanced knowledge to mentor others or lead projects that require comprehensive lifecycle evaluations. This will not only reinforce your skills but also benefit your team."}, {"user_strengths": "You understand the importance of integrating agile thinking into your daily work.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To meet the required level, practice applying agile methodologies in system development projects. Engage in training or workshops to enhance your ability to focus on customer benefit and develop agile skills practically."}, {"user_strengths": "Currently, there's a significant gap in your understanding of Systems Modeling and Analysis.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To reach the required level, start with foundational courses or training in systems modeling. Engage in projects under the guidance of a mentor to build practical experience in defining system models and differentiating between cross-domain and domain-specific models."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You demonstrate a strong capability in decision management at the required level, showing proficiency in preparing and documenting decisions within your scope.", "competency_name": "Decision Management", "improvement_areas": "No further action needed as you meet the required competency level."}, {"user_strengths": "You exceed the required competency level in project management, showcasing an ability to not only manage but also improve project processes and effectively communicate with all stakeholders.", "competency_name": "Project Management", "improvement_areas": "Continue to share your project management insights and improvements with your team to enhance overall project execution."}, {"user_strengths": "You meet the required competency level in information management, with a good understanding of key platforms for knowledge transfer.", "competency_name": "Information Management", "improvement_areas": "No further action needed as you meet the required competency level."}, {"user_strengths": "Currently, you have not demonstrated knowledge in this area.", "competency_name": "Configuration Management", "improvement_areas": "To meet the required competency level, start by familiarizing yourself with the basics of configuration management. Understand the process of defining configuration items and learn to use the necessary tools for creating configurations relevant to your scopes. Consider enrolling in a training course or seeking mentorship within your organization to help you gain these skills."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You currently demonstrate the ability to negotiate objectives with your team and efficiently direct them towards achieving these goals, which is a practical application of leadership skills.", "competency_name": "Leadership", "improvement_areas": "To enhance your leadership competency, focus on developing a deeper understanding of how to define and articulate system objectives clearly to your entire team. This can be achieved through workshops on strategic communication and leadership training programs that emphasize clarity in setting and communicating goals."}, {"user_strengths": "You exhibit a mastery in managing and optimizing complex projects and processes, which is above the required level of being able to independently manage projects using self-organization skills.", "competency_name": "Self-Organization", "improvement_areas": "Since you exceed the requirements in this area, consider mentoring others in self-organization techniques or leading initiatives that showcase best practices in project management. This will not only reinforce your skills but also help elevate the capabilities of your team."}, {"user_strengths": "You have a good understanding of the importance of communication in systems engineering.", "competency_name": "Communication", "improvement_areas": "To meet the required competency level, you need to practice applying your communication skills more constructively and efficiently, with a focus on empathy. Engage in role-playing exercises, seek feedback from peers on your communication style, and possibly attend advanced communication skills workshops that focus on empathetic and effective dialogue."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have already mastered the required competency level for identifying, documenting, and analyzing requirements, which is crucial for the successful development of systems engineering projects.", "competency_name": "Requirements Definition", "improvement_areas": "Since you meet the required competency level, focus on maintaining your skills through continuous practice and staying updated with the latest trends and tools in requirements management."}, {"user_strengths": "You meet the required understanding of the relevance of architectural models in the system development process and can effectively interpret these models.", "competency_name": "System Architecting", "improvement_areas": "Continue to deepen your understanding by engaging with more complex architectural scenarios and participating in workshops or training sessions that focus on advanced system architecture concepts."}, {"user_strengths": "You are familiar with the objectives of verification and validation.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "To meet the required level, enhance your understanding by learning to read and interpret test plans, test cases, and results. Consider enrolling in courses or seeking mentorship that focuses on practical aspects of V&V processes."}, {"user_strengths": "You proficiently manage the operation, service, and maintenance phases of projects, and are capable of identifying improvements for future initiatives.", "competency_name": "Operation and Support", "improvement_areas": "Since you already meet the required level, continue to refine these skills and consider sharing your knowledge through mentoring others or leading team training sessions."}, {"user_strengths": "You excel in applying Agile methods, well beyond the required competency level, and are capable of leading Agile teams successfully.", "competency_name": "Agile Methods", "improvement_areas": "Leverage your advanced skills by continuing to lead by example and possibly taking on roles that allow you to spread Agile practices more broadly within your organization or in new projects."}], "competency_area": "Technical"}]	2024-12-12 10:12:56.507844
32	52	1	[{"feedbacks": [{"user_strengths": "You have a solid understanding of the interactions within systems.", "competency_name": "Systems Thinking", "improvement_areas": "To meet the required level, focus on applying your understanding to analyze and improve the systems you work with. Engage in projects that allow you to practice this, or seek mentorship from a colleague who excels in system analysis and improvement."}, {"user_strengths": "You are proficient in identifying and assessing all lifecycle phases relevant to your scope, which matches the required level.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Continue to apply and possibly share your knowledge with peers through workshops or team meetings to maintain and enhance this skill."}, {"user_strengths": "You excel in promoting agile thinking and inspiring others, surpassing the required level.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Leverage your advanced skills to further enhance agile practices in your team and contribute to organizational learning."}, {"user_strengths": "Your ability to set guidelines and write good modeling practices exceeds the required level.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "You could use your expertise to lead initiatives for improving modeling practices across your organization or mentor others in model development."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You excel in decision management, showing the ability to evaluate decisions comprehensively and establish decision-making bodies effectively. You also demonstrate a strong capability in defining guidelines for decision-making, which is above the required level.", "competency_name": "Decision Management", "improvement_areas": "Given your advanced skills, consider mentoring others in your organization on effective decision-making strategies and perhaps lead workshops or training sessions to disseminate your expertise."}, {"user_strengths": "You meet the required competency level in project management, with robust skills in defining project mandates, establishing conditions, creating complex plans, and producing meaningful reports. Your communication with stakeholders is also commendable.", "competency_name": "Project Management", "improvement_areas": "To further enhance your project management skills, you might explore advanced project management methodologies or certification programs. Engaging in larger, more complex projects could also provide valuable hands-on experience."}, {"user_strengths": "You understand the essential platforms for knowledge transfer and are aware of the importance of targeting the right audience with the appropriate information.", "competency_name": "Information Management", "improvement_areas": "To reach the required level, focus on developing your ability to define storage structures and documentation guidelines. Practical application through taking on roles that involve setting up or managing information systems could be beneficial."}, {"user_strengths": "Your proficiency in configuration management is notable, with an ability to recognize all relevant configuration items and create comprehensive configurations. You also excel in identifying improvements and proposing solutions.", "competency_name": "Configuration Management", "improvement_areas": "Leverage your advanced skills by taking a leadership role in configuration management projects or initiatives within your organization. Sharing your knowledge through training or mentoring could also help others improve their competencies."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You are highly skilled in developing team members strategically, enhancing their problem-solving capabilities, which is beyond the current requirement.", "competency_name": "Leadership", "improvement_areas": "There is no specific need for improvement as you have already surpassed the required level. Maintain and continue to apply your advanced skills effectively."}, {"user_strengths": "Currently, there are no recorded strengths in this area.", "competency_name": "Self-Organization", "improvement_areas": "You need to develop basic knowledge and skills in self-organization to manage projects and tasks independently. Consider starting with time management and prioritization techniques. Online courses or workshops on project management could also be beneficial."}, {"user_strengths": "Your ability to communicate constructively and empathetically meets the required level.", "competency_name": "Communication", "improvement_areas": "Continue to hone your communication skills by seeking feedback from peers, engaging in diverse communication scenarios, and possibly exploring advanced communication strategies in professional workshops."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You exceed the required level in understanding and applying knowledge in Requirements Definition. Your ability to recognize deficiencies and develop improvement suggestions, along with creating and discussing context and interface descriptions, demonstrates a mastery level.", "competency_name": "Requirements Definition", "improvement_areas": "Since you already exceed the required proficiency, you might consider mentoring others or leading workshops to share your expertise and insights in this area."}, {"user_strengths": "You meet the required level for System Architecting, showing a good understanding of why architectural models are significant and how to extract relevant information from them.", "competency_name": "System Architecting", "improvement_areas": "To further enhance your skills, try engaging more actively in creating or modifying architectural models or participating in advanced courses or seminars focused on system architecture."}, {"user_strengths": "You are performing above the required level, with the ability to create and conduct tests and simulations effectively.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Consider exploring deeper aspects like advanced testing methodologies or automated testing tools to further enhance your competency and contribute to more complex testing scenarios."}, {"user_strengths": "You demonstrate a superior level of competency in defining organizational processes for operation, maintenance, and servicing, which is beyond the required understanding.", "competency_name": "Operation and Support", "improvement_areas": "You could focus on sharing your knowledge through training sessions or developing a comprehensive guide on best practices for operation and support phases."}, {"user_strengths": "Currently, there is a significant knowledge gap in Agile Methods as you are not familiar with this competency.", "competency_name": "Agile Methods", "improvement_areas": "To meet the required level, start with foundational Agile training courses, attend Agile workshops, and try to participate in projects using Agile methodologies to gain practical experience."}], "competency_area": "Technical"}]	2024-12-30 17:41:25.565676
33	53	1	[{"feedbacks": [{"user_strengths": "You have achieved the required level of understanding in Systems Thinking, indicating a solid grasp of how individual components interact within a system.", "competency_name": "Systems Thinking", "improvement_areas": "There is no immediate need for improvement in this area as your recorded level matches the required level."}, {"user_strengths": "You have demonstrated the ability to apply lifecycle considerations practically, which goes beyond the basic understanding.", "competency_name": "Lifecycle Consideration", "improvement_areas": "To align with the required level, focus on deepening your understanding of the theoretical aspects of lifecycle phases and their importance during development."}, {"user_strengths": "You excel in promoting agile thinking and inspiring others, which is above the required level of merely identifying the principles of agile thinking.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Continue to leverage this strength by further enhancing your leadership in promoting agile principles within your team or organization."}, {"user_strengths": "You are familiar with the basics of modeling, which is a good starting point.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To meet the required level, focus on deepening your understanding of how models support your work, and practice reading and interpreting simple models. Consider engaging in hands-on modeling projects or seeking mentorship from experienced modelers within your organization."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have a strong practical application in decision management, able to prepare and document decisions effectively using decision support methods like utility analysis.", "competency_name": "Decision Management", "improvement_areas": "To align with the required understanding level, focus on deepening your knowledge of decision support methods and clarify your role in decision-making processes, distinguishing between decisions you should make and those made by committees."}, {"user_strengths": "You excel in project management, capable of identifying process inadequacies and suggesting improvements, along with successful communication with all stakeholders.", "competency_name": "Project Management", "improvement_areas": "Your current competency level surpasses the required level, indicating strong proficiency. Continue to refine these skills and consider mentoring others in project management techniques."}, {"user_strengths": "You meet the required level of understanding in information management, knowing the key platforms for knowledge transfer and the appropriate dissemination of information.", "competency_name": "Information Management", "improvement_areas": "Maintain your current knowledge and stay updated with any advancements in information management platforms to ensure continuous competency."}, {"user_strengths": "You are at the required level of understanding for configuration management, recognizing its necessity and the tools used.", "competency_name": "Configuration Management", "improvement_areas": "To continue meeting the required level, deepen your understanding of how these tools are implemented in real-world scenarios and consider hands-on practice with these tools if possible."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have achieved the required level in Leadership by understanding and clearly articulating system objectives to the team.", "competency_name": "Leadership", "improvement_areas": "Continue to apply and possibly share your understanding of setting clear objectives with peers to further strengthen this competency."}, {"user_strengths": "You are familiar with the basic concepts of self-organization.", "competency_name": "Self-Organization", "improvement_areas": "To meet the required level, deepen your understanding of how self-organization can influence your daily work. Consider engaging in practical activities or scenarios where you can observe and implement self-organizing principles. This might include participating in workshops or seeking mentorship from someone proficient in this area."}, {"user_strengths": "Currently, there is a significant gap in your understanding of this crucial competency.", "competency_name": "Communication", "improvement_areas": "To elevate your competency to the required level, start by learning the basic principles of effective communication. This could involve attending training sessions, reading books on communication skills, or participating in group discussions that encourage active communication. Gradually, aim to understand the specific applications of communication in systems engineering by seeking examples or case studies."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have a solid understanding of the basic process of requirement management, including identifying, formulating, deriving, and analyzing requirements, as well as the importance of traceability.", "competency_name": "Requirements Definition", "improvement_areas": "To advance to an independent handling of requirements, focus on practicing the derivation, documentation, and linking of requirements in real projects. Engage in workshops or training that emphasize hands-on exercises in writing and documenting complex requirements. Seek mentorship from experienced colleagues to guide you through the practical aspects of requirement management."}, {"user_strengths": "You excel in creating and managing highly complex models and identifying areas for improvement in the process.", "competency_name": "System Architecting", "improvement_areas": "While your competency level surpasses the required level, continue to refine your skills by staying updated with latest methodologies and tools in system architecting. Share your expertise with peers through training sessions or workshops."}, {"user_strengths": "Currently, there is a significant gap in your knowledge in this area.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Begin with foundational training or courses in integration, verification, and validation to build your understanding. Engage in projects under supervision to gain practical experience in reading and understanding test plans, cases, and results."}, {"user_strengths": "This is another area where you need to develop foundational knowledge.", "competency_name": "Operation and Support", "improvement_areas": "Start by familiarizing yourself with the stages of operation, service, and maintenance. Consider attending seminars or undergoing training focused on these aspects. Involvement in projects that allow you to observe or participate in these phases can be beneficial."}, {"user_strengths": "You recognize Agile values and are aware of basic principles of Agile methodologies.", "competency_name": "Agile Methods", "improvement_areas": "To deepen your understanding, actively participate in Agile projects and observe how Agile methods are applied within a development process. Attend advanced Agile training that emphasizes practical application and understanding the impact of Agile practices on project success."}], "competency_area": "Technical"}]	2024-12-30 17:59:38.976414
34	54	1	[{"feedbacks": [{"user_strengths": "You effectively understand the interaction of the individual components within a system, aligning perfectly with the required level.", "competency_name": "Systems Thinking", "improvement_areas": "Since you are meeting the required level, focus on maintaining this understanding and possibly explore deeper insights into complex system interactions to enhance your expertise."}, {"user_strengths": "You have a practical application understanding of lifecycle phases, which exceeds the basic understanding required.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Although you are performing above the required level, you could benefit from deepening your understanding of the theoretical aspects behind lifecycle considerations to complement your practical skills."}, {"user_strengths": "You excel in promoting agile thinking and inspiring others, surpassing the basic identification of agile principles that is required.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Continue to leverage your advanced skills to foster an agile mindset in your team and organization, potentially sharing your insights and strategies with peers to elevate the overall team competency."}, {"user_strengths": "You are familiar with the basics of modeling and its benefits.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To meet the required level, focus on enhancing your understanding of how models support your work and practice reading and interpreting simple models. Engage in training or workshops that offer practical modeling exercises."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You are proficient in preparing and documenting decisions, and able to apply decision support methods effectively, such as utility analysis.", "competency_name": "Decision Management", "improvement_areas": "To meet the required level, you should deepen your understanding of decision support methods and enhance your knowledge of the decision-making process, especially regarding which decisions require committee involvement."}, {"user_strengths": "You excel in project management, capable of identifying process inadequacies and communicating effectively with all stakeholders.", "competency_name": "Project Management", "improvement_areas": "No further improvement is needed in this area, as your recorded level surpasses the required competency level."}, {"user_strengths": "Your understanding of key platforms for knowledge transfer and knowledge about information distribution is on par with the required level.", "competency_name": "Information Management", "improvement_areas": "No further improvement is needed in this area, as your recorded level matches the required competency level."}, {"user_strengths": "You have a basic understanding of the necessity and tools used in configuration management.", "competency_name": "Configuration Management", "improvement_areas": "No further improvement is needed in this area, as your recorded level matches the required competency level."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have a strong understanding of the importance of defining clear objectives for a system and effectively communicating these to your team.", "competency_name": "Leadership", "improvement_areas": "You have fully met the required level in this competency, so continue to apply and refine these skills in your daily work to maintain your proficiency."}, {"user_strengths": "You are aware of the basic concepts of self-organization.", "competency_name": "Self-Organization", "improvement_areas": "To meet the required level, you need to deepen your understanding of how these concepts can be applied in your daily work. Consider seeking resources such as books, online courses, or workshops focused on self-organization techniques. Practicing these concepts in real-life scenarios can also help solidify your understanding."}, {"user_strengths": "Currently, there is a significant opportunity for growth in this area.", "competency_name": "Communication", "improvement_areas": "To reach the required level, you need to develop a basic understanding of communication skills, particularly their importance in systems engineering. Start with introductory resources on effective communication, participate in communication skills workshops, and seek opportunities for practical application, such as presenting at team meetings or leading discussions."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have a good foundational understanding of requirement management, including the ability to distinguish between different types of requirements and the importance of traceability.", "competency_name": "Requirements Definition", "improvement_areas": "To meet the required level, focus on enhancing your ability to independently derive, write, and document requirements. Consider engaging in practical exercises or projects where you can practice these skills in real scenarios. Training sessions or workshops on advanced requirements management could also be beneficial."}, {"user_strengths": "You excel in creating and managing complex models and identifying methodological improvements, which is beyond the required competency level.", "competency_name": "System Architecting", "improvement_areas": "Since you already exceed the required level, continue to refine your skills and possibly mentor others in system architecting. Keep abreast of new methodologies or modeling languages to further enhance your expertise."}, {"user_strengths": "Currently, this is an area where you lack knowledge.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Begin with foundational training or courses that explain the basics of integration, verification, and validation. Understanding test plans, cases, and results are essential, so consider participating in projects with a quality assurance component to gain practical exposure."}, {"user_strengths": "This is another area where foundational knowledge is currently lacking.", "competency_name": "Operation and Support", "improvement_areas": "Start by learning the basics of operation, service, and maintenance phases. Online courses or internal training sessions might be available to help you understand these concepts. Engaging with teams that handle these phases could also provide valuable hands-on experience."}, {"user_strengths": "You have a basic understanding of Agile values and methodologies.", "competency_name": "Agile Methods", "improvement_areas": "To advance to the required level, deepen your understanding of how Agile workflows are applied within development processes. Participate in Agile projects, attend advanced Agile workshops, and learn from experienced Agile practitioners to see how these methodologies impact project success."}], "competency_area": "Technical"}]	2024-12-30 18:11:46.995707
35	55	1	[{"feedbacks": [{"user_strengths": "You are well-equipped in understanding the interaction of individual components within a system, which is exactly aligned with the required level.", "competency_name": "Systems Thinking", "improvement_areas": "Since you are already at the required level for Systems Thinking, continue to apply this competency in your projects to deepen your practical understanding and keep abreast of new methodologies in systems thinking."}, {"user_strengths": "You possess a higher level of competency in identifying, considering, and assessing all lifecycle phases relevant to your scope, which exceeds the basic understanding that is required.", "competency_name": "Lifecycle Consideration", "improvement_areas": "You could leverage your advanced understanding to mentor others or contribute to organizational knowledge sharing. Continue to explore deeper implications of lifecycle phases in system development to enhance your strategic thinking."}, {"user_strengths": "You excel in this area by promoting agile thinking and inspiring others, which goes well beyond the basic identification of fundamental principles of agile thinking required.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Consider taking a leadership role in initiatives that focus on customer value orientation. Your advanced skills can significantly contribute to shaping the agile practices within your organization. Also, consider sharing your insights through workshops or seminars."}, {"user_strengths": "You have a foundational understanding of systems modeling and its benefits.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To meet the required level, focus on deepening your understanding of how models support your work. Engage in training or projects that allow you to practice reading and creating models. Collaborating with experienced peers or seeking mentorship can also accelerate your learning."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You are capable of preparing and making decisions within your scope and effectively documenting them. You also proficiently apply decision support methods like utility analysis.", "competency_name": "Decision Management", "improvement_areas": "To meet the required understanding level, focus on deepening your knowledge of decision-making processes, especially in recognizing decisions that require committee involvement versus those you can handle independently."}, {"user_strengths": "You excel in identifying process inadequacies and suggesting improvements, and you are adept at communicating effectively with stakeholders.", "competency_name": "Project Management", "improvement_areas": "Since your current proficiency surpasses the required level, continue refining your project management skills, potentially sharing your knowledge or mentoring others to enhance team capabilities."}, {"user_strengths": "Your understanding of key platforms for knowledge transfer and the appropriate distribution of information aligns perfectly with the required level.", "competency_name": "Information Management", "improvement_areas": "Maintain your current understanding and perhaps explore new technologies or methods to enhance information sharing and management within your team."}, {"user_strengths": "You are aware of the importance of configuration management and familiar with the tools used in this process, which matches the required level.", "competency_name": "Configuration Management", "improvement_areas": "Since you meet the required level, consider exploring deeper aspects of configuration management or related tools to enhance efficiency and accuracy in your work."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have a firm understanding of the importance of defining objectives for a system and the ability to communicate these effectively to your team. This is a crucial skill for any leader and aligns perfectly with the expected level.", "competency_name": "Leadership", "improvement_areas": "There is no specific improvement needed in this area as your recorded level meets the required standard."}, {"user_strengths": "You are aware of the concepts of self-organization, which is a positive starting point.", "competency_name": "Self-Organization", "improvement_areas": "To move from a basic awareness to a deeper understanding, consider exploring how self-organization principles can be applied in your daily work. This could involve setting personal goals to improve your efficiency or seeking out case studies or resources that demonstrate successful self-organization in a professional setting."}, {"user_strengths": "Currently, there is a significant opportunity for development in this area.", "competency_name": "Communication", "improvement_areas": "To enhance your competency in communication, start by familiarizing yourself with the basics of effective communication strategies. Engage in training sessions or workshops that focus on communication skills. Practicing these skills in daily interactions will also be beneficial. Understanding the impact of good communication in systems engineering will further reinforce the importance of this skill."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have a solid understanding of the basic process of requirement management, including identifying, formulating, deriving, and analyzing requirements.", "competency_name": "Requirements Definition", "improvement_areas": "To meet the required level, focus on practicing the independent derivation, writing, and documentation of requirements. Engage in projects where you can handle requirement documents or models, and seek mentorship or workshops that emphasize practical application of requirements management."}, {"user_strengths": "You excel in creating and managing highly complex models and identifying improvements in the process.", "competency_name": "System Architecting", "improvement_areas": "While your skills surpass the required level for creating complex architectural models, ensure that the models you create are reproducible and aligned with the methodology. This may involve refining your approach to align more closely with standard practices and inputs."}, {"user_strengths": "Currently, there is a significant gap in this area, as it is a new field for you.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Begin with foundational knowledge such as understanding test plans, cases, and results. Consider enrolling in introductory courses on testing and validation, and participate in projects under the guidance of a mentor in this field."}, {"user_strengths": "This is another area where foundational knowledge is needed.", "competency_name": "Operation and Support", "improvement_areas": "Start with familiarizing yourself with the stages of operation, service, and maintenance, and understanding how they integrate into the development process. Seek resources and training focused on these phases to build a baseline understanding."}, {"user_strengths": "You recognize Agile values and are aware of the basic principles of Agile methodologies.", "competency_name": "Agile Methods", "improvement_areas": "To advance to the required level, deepen your understanding of Agile workflows and their application in development processes. Participate in Agile projects, attend seminars or workshops, and study successful Agile implementations to grasp their impact on project success."}], "competency_area": "Technical"}]	2024-12-30 18:43:13.197888
36	56	1	[{"feedbacks": [{"user_strengths": "You have a solid understanding of how the individual components of a system interact, which is exactly what is required for your role.", "competency_name": "Systems Thinking", "improvement_areas": "No further action is needed as you meet the required competency level."}, {"user_strengths": "You demonstrate a practical ability to identify, consider, and assess all lifecycle phases relevant to your scope, which surpasses the basic understanding required.", "competency_name": "Lifecycle Consideration", "improvement_areas": "To align better with expected competencies, focus on deepening your understanding of why all lifecycle phases are crucial during development. You might benefit from theoretical training or case studies showcasing lifecycle impacts in different projects."}, {"user_strengths": "You excel in promoting agile thinking and inspiring others within the organization, going beyond the basic requirement to identify agile principles.", "competency_name": "Customer / Value Orientation", "improvement_areas": "No further improvement is needed in this area as you exceed the required competency level."}, {"user_strengths": "You are familiar with the basics of modeling and its benefits.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To meet the required competency level, enhance your understanding of how models support your work and improve your ability to read simple models. Consider engaging in hands-on model analysis exercises or attending workshops focused on systems modeling."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have a practical level of competency in Decision Management, able to prepare and document decisions effectively using decision support methods like utility analysis.", "competency_name": "Decision Management", "improvement_areas": "To meet the required understanding level, focus on deepening your knowledge of decision support methods and clarifying the decision-making process, particularly which decisions are made by committees versus individually."}, {"user_strengths": "You excel in Project Management, surpassing the required level. Your skills in identifying process inadequacies, suggesting improvements, and effectively communicating with stakeholders are notable strengths.", "competency_name": "Project Management", "improvement_areas": "While you are already performing above the required level, continuing to refine these skills will ensure you maintain a high standard and adapt to evolving project management practices."}, {"user_strengths": "Your understanding of Information Management aligns perfectly with the required level. You are proficient in identifying appropriate knowledge transfer platforms and understanding information dissemination among stakeholders.", "competency_name": "Information Management", "improvement_areas": "Maintain this level of understanding by staying updated with new platforms and evolving information management strategies to enhance efficiency and effectiveness."}, {"user_strengths": "Your awareness of the importance of Configuration Management and familiarity with the necessary tools matches the required level.", "competency_name": "Configuration Management", "improvement_areas": "To further enhance your competency, consider gaining hands-on experience with different configuration management tools and engaging in training or workshops to deepen your technical understanding."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have demonstrated a clear understanding of defining objectives for a system and possess the ability to articulate these objectives effectively to your team, which is exactly what is required at your current level.", "competency_name": "Leadership", "improvement_areas": "Since you are meeting the required level, continue to refine and apply your leadership skills in various situations to remain adept and perhaps aim for higher leadership roles in the future."}, {"user_strengths": "You are aware of the basic concepts of self-organization, which is a good starting point.", "competency_name": "Self-Organization", "improvement_areas": "To meet the required competency level, you need to develop a deeper understanding of how these concepts can be applied to your daily work. Consider engaging in projects that require self-organization, seek mentorship from colleagues who excel in this area, or participate in workshops and training focused on effective self-organization techniques."}, {"user_strengths": "Currently, you have room to develop in this area.", "competency_name": "Communication", "improvement_areas": "To bridge the gap to the required level, you should focus on understanding the importance of communication in systems engineering. Start by engaging more actively in team meetings, asking for feedback on your communication style, and attending training sessions or workshops on effective communication skills. Practicing these skills in everyday scenarios will also be beneficial."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have a solid understanding of the different types of requirements and the basic process of requirement management.", "competency_name": "Requirements Definition", "improvement_areas": "Focus on gaining practical experience in independently identifying, deriving, and documenting requirements. Practicing writing and linking requirements in real-world scenarios will help you reach the required level."}, {"user_strengths": "You excel in creating and managing complex models and identifying process or methodological deficiencies.", "competency_name": "System Architecting", "improvement_areas": "Since your recorded level exceeds the required level, continue to apply your skills in real-world projects and perhaps mentor others in this competency."}, {"user_strengths": "Currently, you have no recorded knowledge in this area.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Start with the basics by familiarizing yourself with test plans, cases, and results. Online courses or workshops on testing methodologies could be beneficial."}, {"user_strengths": "Currently, you have no recorded knowledge in this area.", "competency_name": "Operation and Support", "improvement_areas": "Begin by understanding the stages of operation, service, and maintenance. Attend training sessions or seek mentorship to learn about these phases and their importance in development."}, {"user_strengths": "You recognize agile values and are aware of basic agile principles.", "competency_name": "Agile Methods", "improvement_areas": "Enhance your understanding by studying how Agile methods are applied in development processes and their impact on project success. Participating in Agile projects or attending advanced Agile training can offer practical insights."}], "competency_area": "Technical"}]	2024-12-30 19:01:22.140563
37	57	1	[{"feedbacks": [{"user_strengths": "Your understanding of the interaction between individual system components aligns perfectly with the expectations for this competency. This foundational knowledge is crucial for effective systems engineering.", "competency_name": "Systems Thinking", "improvement_areas": "Since you are meeting the required level, continue to apply this knowledge in practical scenarios to maintain and deepen your understanding."}, {"user_strengths": "You have exceeded the required level by demonstrating the ability to actively consider and assess all lifecycle phases, which shows a practical application of your knowledge.", "competency_name": "Lifecycle Consideration", "improvement_areas": "While you are already performing above the required level, you could enhance your understanding by exploring more about the theoretical aspects of why all lifecycle phases are essential during development."}, {"user_strengths": "You excel in promoting agile thinking and inspiring others, which is well above the basic knowledge required. Your ability to lead and influence in this area is a significant strength.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Continue to leverage and share this expertise within your organization to foster a culture of agility and customer focus."}, {"user_strengths": "You have a basic familiarity with modeling and its benefits, which is a good starting point.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To meet the required level, focus on deepening your understanding of how models can support your work. Engage in training or projects that allow you to read and interpret more complex models, and consider seeking mentorship from a more experienced colleague in this area."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have progressed to a level where you can prepare, make, and document decisions within your scope, applying decision support methods effectively.", "competency_name": "Decision Management", "improvement_areas": "Your recorded level is higher than the required. However, focus on refining your understanding of decision-making boundaries within organizational structures, ensuring clear knowledge of when and where committees are needed."}, {"user_strengths": "You excel in project management, identifying process inadequacies and communicating effectively with all stakeholders.", "competency_name": "Project Management", "improvement_areas": "You have already surpassed the required level. Continue to refine and share your expertise, possibly mentoring others or leading workshops to help peers reach a similar level of competency."}, {"user_strengths": "Your understanding of key platforms for knowledge transfer and information sharing aligns well with the expectations for your role.", "competency_name": "Information Management", "improvement_areas": "Maintain this level of understanding and continue to stay updated with new technologies and practices in information management to ensure ongoing effectiveness."}, {"user_strengths": "You are aware of the importance of configuration management and know the necessary tools.", "competency_name": "Configuration Management", "improvement_areas": "As your recorded and required levels match, aim to deepen your practical experience with these tools. Engage in hands-on projects or training sessions to enhance your skills."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have a solid understanding of the importance of defining objectives for a system and are capable of clearly communicating these objectives to your team.", "competency_name": "Leadership", "improvement_areas": "There are no specific areas of improvement needed for this competency as your current level meets the required level."}, {"user_strengths": "You are familiar with the basic concepts of self-organization.", "competency_name": "Self-Organization", "improvement_areas": "To elevate your competency to the required level, strive to understand how these concepts can be practically applied in your daily work. Consider seeking resources or training that focus on practical applications of self-organization in systems engineering."}, {"user_strengths": "Currently, this is an area that needs substantial improvement.", "competency_name": "Communication", "improvement_areas": "Since this competency is critical, especially in systems engineering, it's important to begin by familiarizing yourself with the basics of effective communication. Engage in training sessions, workshops, or even online courses that emphasize communication skills within a team and project management context."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have a solid understanding of the basic process of requirement management, including identifying, formulating, deriving, and analyzing requirements. Your knowledge about the importance of traceability and the use of tools in requirement management is commendable.", "competency_name": "Requirements Definition", "improvement_areas": "To elevate your skills to the required level, focus on gaining practical experience in independently identifying sources of requirements, and in deriving, writing, and documenting requirements. Engage in projects that allow you to practice documenting, linking, and analyzing requirements in real-world scenarios."}, {"user_strengths": "You excel in creating and managing highly complex models and can identify shortcomings in the process to suggest improvements. Your ability to recognize deficiencies in methods or modeling languages is a significant strength.", "competency_name": "System Architecting", "improvement_areas": "Maintain your high level of competency by continuing to apply your skills in diverse projects, ensuring that your architectural models are reproducible and aligned with the methodology and modeling language."}, {"user_strengths": "Currently, there is a significant gap in your knowledge in this area.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Begin by familiarizing yourself with the basics of integration, verification, and validation processes. Reading relevant literature, attending workshops, and engaging in entry-level projects under guidance can help you understand test plans, test cases, and results."}, {"user_strengths": "You are starting from a base level of knowledge in operation and support.", "competency_name": "Operation and Support", "improvement_areas": "To meet the required level, it's crucial to deepen your understanding of the stages of operation, service, and maintenance phases. Participate in related projects and seek mentorship to observe and learn how these phases are considered during development and involve activities in each phase."}, {"user_strengths": "Your familiarity with Agile values and basic principles of Agile methodologies is a good starting point.", "competency_name": "Agile Methods", "improvement_areas": "To enhance your understanding, actively participate in Agile projects. This hands-on experience will help you understand the fundamentals of Agile workflows and how to apply Agile methods effectively within a development process."}], "competency_area": "Technical"}]	2024-12-30 19:08:19.943113
38	58	1	[{"feedbacks": [{"user_strengths": "You fully meet the required level in Systems Thinking, demonstrating a solid understanding of how the individual components of a system interact.", "competency_name": "Systems Thinking", "improvement_areas": "Continue to apply this understanding in practical scenarios to further deepen your insights and maintain this competency."}, {"user_strengths": "You exceed the required level for Lifecycle Consideration, as you are able to identify, consider, and assess all lifecycle phases relevant to your scope.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Leverage your capability to apply lifecycle considerations by helping others understand its importance and how to integrate these considerations into their projects."}, {"user_strengths": "You surpass the required level for Customer / Value Orientation, with a strong ability to promote and inspire agile thinking within the organization.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Continue to inspire others and consider sharing your methods and insights in workshops or trainings to foster a culture of agile thinking across your team or organization."}, {"user_strengths": "You have a basic familiarity with systems modeling.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To meet the required level, strive to deepen your understanding of how models support your work. Engage in hands-on practice with modeling tools, attend workshops, or seek mentorship to improve your ability to read and utilize models effectively."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have a strong practical application in decision management, capable of preparing, making, and documenting decisions within your scope. Your ability to apply decision support methods like utility analysis is commendable.", "competency_name": "Decision Management", "improvement_areas": "To align with the required understanding of this competency, focus on enhancing your knowledge of which decisions to escalate to committees and deepen your understanding of various decision support methods contextually."}, {"user_strengths": "Your proficiency in project management exceeds the required level, demonstrating strong capabilities in identifying process inadequacies and suggesting improvements. Your communication and reporting skills to stakeholders are notable.", "competency_name": "Project Management", "improvement_areas": "While you are already performing above the required competency level, continue to refine these skills and perhaps mentor others in project management techniques to further solidify your expertise."}, {"user_strengths": "You meet the required understanding of information management, recognizing key platforms for knowledge transfer and the appropriate dissemination of information.", "competency_name": "Information Management", "improvement_areas": "To enhance your competency, consider exploring advanced techniques in managing and safeguarding information, focusing on how to leverage these platforms for optimal knowledge sharing and security."}, {"user_strengths": "You meet the necessary awareness level for configuration management, understanding the tools used for creating configurations.", "competency_name": "Configuration Management", "improvement_areas": "Although your current understanding meets the requirement, you could explore deeper practical applications of these tools. Consider hands-on projects or training to enhance your ability to actively manage and implement configuration changes."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You meet the required understanding for leadership, showing a good grasp of defining and articulating objectives to the team.", "competency_name": "Leadership", "improvement_areas": "Maintain your current level of competency and continue to apply these skills effectively in your projects."}, {"user_strengths": "You are aware of self-organization concepts, which is a good starting point.", "competency_name": "Self-Organization", "improvement_areas": "Advance from basic awareness to a deeper understanding of how self-organization can be applied in your daily work. Consider seeking resources or training that provide practical examples and strategies for self-organization in the workplace."}, {"user_strengths": "Currently, you are at the beginning stage in this competency.", "competency_name": "Communication", "improvement_areas": "It's crucial to improve your understanding of communication in systems engineering. Engage in training or workshops that focus on effective communication skills, including clear articulation of ideas and active listening. Practicing these skills in team settings can also be beneficial."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have a solid understanding of the basic process of requirement management, including identifying, formulating, deriving, and analyzing requirements. This foundational knowledge is an excellent basis for advancing your skills.", "competency_name": "Requirements Definition", "improvement_areas": "To bridge the gap to the required level, focus on gaining practical experience in independently identifying sources of requirements, and writing and documenting them in a clear and structured manner. Engage in projects that allow you to work on linking and analyzing requirement documents or models. Additionally, consider participating in workshops or training sessions that focus on advanced requirement management techniques."}, {"user_strengths": "Your ability to manage highly complex models and recognize deficiencies demonstrates a high level of proficiency in system architecting.", "competency_name": "System Architecting", "improvement_areas": "Although your current level exceeds the requirements, maintaining this competency through continuous learning and application in varied projects will ensure you stay adept and can adapt to new methodologies or tools as they arise."}, {"user_strengths": "Currently, your knowledge in this area is minimal.", "competency_name": "Integration, Verification,  Validation", "improvement_areas": "To meet the required level, start by familiarizing yourself with the basics of integration, verification, and validation. You can do this by reading relevant materials, attending training or workshops, and working closely with more experienced colleagues on related projects to understand test plans, test cases, and results."}, {"user_strengths": "You are currently not familiar with the operation and support phases.", "competency_name": "Operation and Support", "improvement_areas": "To reach the required level of understanding, begin by learning about the stages of operation, service, and maintenance phases. This can be achieved through on-the-job training, participating in related projects, or attending courses that cover these aspects in detail. Understanding how these phases are considered during development is crucial."}, {"user_strengths": "You already recognize and can list Agile values and relevant methods, which is a good starting point.", "competency_name": "Agile Methods", "improvement_areas": "To deepen your understanding, focus on learning the fundamentals of Agile workflows and how to effectively apply Agile methods within a development process. Engaging in projects that use Agile methodologies and attending specialized Agile training sessions will help you better understand and explain the impact of Agile practices on project success."}], "competency_area": "Technical"}]	2024-12-30 23:22:30.048044
39	59	1	[{"feedbacks": [{"user_strengths": "You are on track with the required level for understanding the interactions of system components.", "competency_name": "Systems Thinking", "improvement_areas": "Continue practicing and exploring various systems to deepen your understanding and application."}, {"user_strengths": "Your ability to identify and assess lifecycle phases is advanced.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Focus on deepening your understanding of why and how all lifecycle phases need to be considered during development."}, {"user_strengths": "You exceed the required level, showing strong capability in promoting agile thinking and inspiring others.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Leverage your advanced skills to further enhance understanding and application of customer/value orientation practices within your team."}, {"user_strengths": "You have a basic understanding of modeling and its benefits.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "Work on understanding how models support your work and strive to read and possibly create simple models to enhance your proficiency."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have demonstrated the capability to prepare, make, and document decisions within your scope using decision support methods like utility analysis.", "competency_name": "Decision Management", "improvement_areas": "To meet the required understanding of when decisions should be made by you or by committees, consider engaging in scenarios where decision-making processes involve different levels of authority. Participate in committee meetings or shadow decision-makers to gain insights."}, {"user_strengths": "You excel in identifying process inadequacies and suggesting improvements, and you are highly effective in communicating with stakeholders.", "competency_name": "Project Management", "improvement_areas": "Since you already exceed the required competency level, continue to enhance your skills by taking on more complex projects or leading multi-disciplinary teams to further refine your project management capabilities."}, {"user_strengths": "Your understanding of key platforms for knowledge transfer and appropriate dissemination of information aligns with the required level.", "competency_name": "Information Management", "improvement_areas": "Maintain this level of competency by staying updated on new technologies and methodologies in information management. Consider engaging in training that deepens your strategic thinking about information flow within projects."}, {"user_strengths": "You are aware of the necessity of configuration management and familiar with the tools used.", "competency_name": "Configuration Management", "improvement_areas": "Since your recorded level matches the required level, focus on deepening your practical experience with these tools. Engage in hands-on projects to understand the nuances of applying configuration management tools effectively."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You meet the required level for Leadership as you are able to understand and articulate objectives clearly to your team.", "competency_name": "Leadership", "improvement_areas": "Continue to refine and practice your leadership skills to maintain this competency level, perhaps by taking on more leadership roles in diverse projects."}, {"user_strengths": "You are aware of the concepts of self-organization.", "competency_name": "Self-Organization", "improvement_areas": "To meet the required level, you need to deepen your understanding of how self-organization can influence your daily work. Consider engaging in workshops or training that focus on practical applications of self-organization in the workplace."}, {"user_strengths": "Currently, there is a significant opportunity for growth in this area.", "competency_name": "Communication", "improvement_areas": "You need to develop a foundational understanding of communication skills, particularly in their application to systems engineering. Start with basic communication training courses and seek opportunities to practice these skills in team meetings and presentations."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have a good foundational understanding of requirements definition, including the ability to distinguish between different types of requirements and the basic process of requirement management.", "competency_name": "Requirements Definition", "improvement_areas": "To meet the required level, focus on gaining skills in independently identifying, deriving, writing, and documenting requirements. Practice linking, deriving, and analyzing requirements to enhance your capability in managing complex requirement scenarios."}, {"user_strengths": "You excel in system architecting, with the ability to identify process shortcomings and develop improvement suggestions. Your skills in creating and managing complex models are exceptional.", "competency_name": "System Architecting", "improvement_areas": "Although you exceed the required competency level in this area, continue to refine and share your expertise, possibly by mentoring others or leading workshops to enhance team capabilities."}, {"user_strengths": "Currently, this is an area where you lack knowledge.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Begin by understanding the basics of integration, verification, and validation processes. Study test plans, test cases, and results to build a foundational knowledge that aligns with the required level."}, {"user_strengths": "This is another area where you currently lack knowledge.", "competency_name": "Operation and Support", "improvement_areas": "Start by familiarizing yourself with the stages of operation, service, and maintenance phases. Understand how these phases are considered during development and what activities are involved in each phase."}, {"user_strengths": "You have a basic understanding of Agile values and methodologies.", "competency_name": "Agile Methods", "improvement_areas": "To advance to the required level, deepen your understanding of Agile workflows and how to apply Agile methods within a development process. Focus on explaining the impact of Agile practices on project success."}], "competency_area": "Technical"}]	2024-12-30 23:36:56.143481
40	60	1	[{"feedbacks": [{"user_strengths": "You have a good foundational understanding of recognizing interrelationships within your system and its boundaries.", "competency_name": "Systems Thinking", "improvement_areas": "To meet the required level, focus on analyzing your current system to identify and implement continuous improvements. Engage in more practical exercises or case studies that require analysis and improvement suggestions."}, {"user_strengths": "You understand the significance of considering all lifecycle phases during development, which is crucial.", "competency_name": "Lifecycle Consideration", "improvement_areas": "To advance to applying this understanding, start identifying, considering, and assessing all lifecycle phases relevant to your projects. Practical experience and focused training on lifecycle management could be beneficial."}, {"user_strengths": "You excellently meet the requirement to develop systems focusing on agile methodologies and customer benefit.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Since you are already at the required level, consider deepening your knowledge or mentoring others in this area to refine your skills further."}, {"user_strengths": "You surpass the required competency level by being able to set guidelines and write good modeling practices.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "As you are already above the required level, you might explore advanced modeling techniques or take on leadership roles in modeling projects to leverage your expertise."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have a solid understanding of decision support methods and can distinguish between decisions you can make independently and those that require committee approval.", "competency_name": "Decision Management", "improvement_areas": "To reach the required level, you need to enhance your skills in preparing and documenting decisions effectively. Focus on applying decision support methods like utility analysis in real scenarios. Consider engaging in workshops or training sessions that focus on decision-making processes and documentation practices."}, {"user_strengths": "You excel in defining project mandates, creating complex project plans, engaging with stakeholders, and producing meaningful reports.", "competency_name": "Project Management", "improvement_areas": "Your recorded level exceeds the required level, indicating strong competency in project management. Continue to refine these skills and possibly share your expertise with peers or consider taking on more complex projects to further develop."}, {"user_strengths": "You recognize the importance of information and knowledge management.", "competency_name": "Information Management", "improvement_areas": "Your next step is to deepen your understanding of key platforms for knowledge transfer and enhance your knowledge of information sharing processes. Focus on learning which information is crucial to be shared and with whom it should be shared. Engage in training or seek mentorship to better understand these platforms and processes."}, {"user_strengths": "You are proficient in defining sensible configuration items, recognizing relevant ones, and using tools to create configurations effectively.", "competency_name": "Configuration Management", "improvement_areas": "Your recorded level matches the required level, showing you are on track. Continue to apply your skills and stay updated with the latest tools and practices in configuration management to maintain your competency."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "Currently, there is a need to establish a foundational understanding of leadership.", "competency_name": "Leadership", "improvement_areas": "To enhance your leadership skills, consider engaging in leadership training programs or workshops. Additionally, seek opportunities to observe and collaborate with experienced leaders within your organization. Reading books on leadership and participating in discussions can also provide valuable insights and practices."}, {"user_strengths": "You excel in self-organization, demonstrating a mastery level that surpasses the required level.", "competency_name": "Self-Organization", "improvement_areas": "Continue to refine and share your knowledge on self-organization with peers. Challenge yourself by taking on more complex projects if possible, to leverage and further develop your advanced skills."}, {"user_strengths": "Currently, there is a need to establish a foundational understanding of effective communication.", "competency_name": "Communication", "improvement_areas": "To advance your communication skills, consider participating in communication skills workshops or seminars. Actively seek feedback on your communication style from colleagues and mentors. Practice active listening and engage in diverse communication settings to gain more experience and confidence."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have a good understanding of identifying, deriving, and interpreting requirements from various sources. Your ability to read and comprehend requirement documents and interface specifications is strong.", "competency_name": "Requirements Definition", "improvement_areas": "To meet the required level, focus on independently documenting, linking, and analyzing requirements. Consider engaging in projects that allow you to practice these skills, or seek mentorship to guide you in advanced techniques of requirement management."}, {"user_strengths": "You excel in creating and managing highly complex models and have the ability to recognize and address deficiencies in methodologies or modeling languages.", "competency_name": "System Architecting", "improvement_areas": "Given that your recorded level exceeds the required level, continue to refine and share your expertise with peers or through leading workshops to maintain your proficiency and leadership in this area."}, {"user_strengths": "Currently, this area is new to you, providing a fresh learning opportunity.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "To reach the required understanding level, start by familiarizing yourself with basic concepts of testing including test plans, cases, and results. Consider online courses or workshops focused on these topics and engage in practical projects where you can apply what you learn."}, {"user_strengths": "You have a solid understanding of how operation, service, and maintenance phases integrate with development, matching the required level.", "competency_name": "Operation and Support", "improvement_areas": "Since you meet the required competency level, continue to deepen your knowledge through practical experiences and staying updated with industry best practices in operation and support."}, {"user_strengths": "Your expertise in defining, implementing, and leading Agile methods is evident and surpasses the required competency level.", "competency_name": "Agile Methods", "improvement_areas": "Leverage your advanced skills in Agile methods by mentoring others or leading advanced Agile workshops. This will not only solidify your knowledge but also help in spreading Agile culture within your organization."}], "competency_area": "Technical"}]	2024-12-30 23:43:04.055551
41	61	1	[{"feedbacks": [{"user_strengths": "You can recognize the interrelationships of your system and its boundaries, which is a critical foundational skill in systems engineering.", "competency_name": "Systems Thinking", "improvement_areas": "To reach the required level, focus on analyzing your current system to derive continuous improvements. Practical exercises that involve problem-solving and system optimization can help you enhance this skill."}, {"user_strengths": "You understand the importance of considering all lifecycle phases during development.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Advance to applying this understanding by identifying, considering, and assessing all lifecycle phases relevant to your scope. Engage in projects that offer hands-on experience with lifecycle management to achieve this competency level."}, {"user_strengths": "You excel in developing systems using agile methodologies with a focus on customer benefit, meeting the required competency level.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Maintain this strength by continuing to engage in projects that prioritize customer value and agile practices. Consider mentoring others in this area to further refine and share your expertise."}, {"user_strengths": "You are highly skilled in setting guidelines for models and writing best practices for modeling, which exceeds the required competency level.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "Leverage your expertise by taking on leadership roles in modeling projects or creating training materials to guide less experienced engineers in modeling practices."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have a good understanding of decision support methods and are aware of decision-making responsibilities.", "competency_name": "Decision Management", "improvement_areas": "To meet the required level, focus on enhancing your ability to prepare and document decisions independently, and apply decision support methods like utility analysis in practice."}, {"user_strengths": "You excel in defining project mandates, establishing conditions, and creating complex project plans, along with effective stakeholder communication.", "competency_name": "Project Management", "improvement_areas": "Although your recorded level is higher than required, ensuring a solid understanding of how these skills integrate within systems engineering will enhance your project management effectiveness."}, {"user_strengths": "You are aware of the importance of information and knowledge management.", "competency_name": "Information Management", "improvement_areas": "To elevate your understanding, engage with key platforms for knowledge transfer and learn to identify critical information sharing protocols within and outside your team."}, {"user_strengths": "You are proficient in defining and managing configuration items relevant to your scopes and adept at using configuration management tools.", "competency_name": "Configuration Management", "improvement_areas": "Your current competency fully meets the required level. Continue to refine these skills and stay updated with new tools and methods in configuration management to maintain your proficiency."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "", "competency_name": "Leadership", "improvement_areas": "Your current level indicates a lack of awareness or knowledge in leadership skills. To meet the required level, you need to understand the relevance of defining objectives for a system and be able to articulate these objectives clearly to the entire team."}, {"user_strengths": "You have demonstrated mastery in managing and optimizing complex projects and processes, which exceeds the required level where you just need to independently manage projects using self-organization skills.", "competency_name": "Self-Organization", "improvement_areas": ""}, {"user_strengths": "", "competency_name": "Communication", "improvement_areas": "Your current level shows a lack of awareness or knowledge in effective communication skills. To meet the required level, you need to develop the ability to communicate constructively and efficiently while being empathetic towards your communication partner."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have a solid understanding of how to identify sources of requirements, derive, and write them. Your ability to read and comprehend requirement documents and interface specifications is commendable.", "competency_name": "Requirements Definition", "improvement_areas": "To meet the required level, focus on enhancing your skills in independently documenting, linking, and analyzing requirements. Practice creating and analyzing context descriptions and interface specifications on your own to gain independence in handling requirements."}, {"user_strengths": "You excel in creating and managing highly complex models and identifying areas for improvement within them. Your capability to recognize deficiencies and suggest improvements is a key strength.", "competency_name": "System Architecting", "improvement_areas": "Currently, your competency level exceeds the required level. Continue to apply your advanced skills effectively and consider mentoring others to help them reach a higher competency level."}, {"user_strengths": "Currently, you are at the beginning of your journey in this competency area.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Focus on gaining a basic understanding of test plans, test cases, and results. Start by reading relevant materials, attending workshops, and engaging in discussions with more experienced colleagues to build your knowledge base."}, {"user_strengths": "You understand the integration of operation, service, and maintenance phases into the development and can list the required activities throughout the lifecycle. This aligns perfectly with the required competency level.", "competency_name": "Operation and Support", "improvement_areas": "Since you meet the required competency level, consider deepening your understanding or exploring more advanced aspects of operation and support to enhance your expertise further."}, {"user_strengths": "Your ability to define, implement, and lead Agile methods is outstanding. You effectively motivate others to adopt Agile methods and successfully lead Agile teams.", "competency_name": "Agile Methods", "improvement_areas": "Your current competency level exceeds the required level, which is a significant advantage. Continue leveraging your expertise to drive Agile adoption and effectiveness in your projects."}], "competency_area": "Technical"}]	2024-12-30 23:55:41.499544
42	62	1	[{"feedbacks": [{"user_strengths": "You are able to recognize the interrelationships of your system and its boundaries, which is a fundamental skill in systems engineering.", "competency_name": "Systems Thinking", "improvement_areas": "To advance to the required level, you need to deepen your understanding of how individual components within the system interact. Consider engaging in more detailed system analysis projects or simulations, and seek feedback from more experienced engineers to enhance your comprehension."}, {"user_strengths": "You already have a good understanding of why and how all lifecycle phases need to be considered during development.", "competency_name": "Lifecycle Consideration", "improvement_areas": "To elevate your competency to being able to identify, consider, and assess all lifecycle phases relevant to your scope, actively participate in or lead lifecycle assessments in your projects. This hands-on experience will help you apply your theoretical knowledge practically."}, {"user_strengths": "You excel in developing systems using agile methodologies and focusing on customer benefit, perfectly meeting the required competency level.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Since you already meet the required competency level, continue to hone this skill by staying updated with the latest agile practices and customer feedback tools. You might also consider mentoring others in this area."}, {"user_strengths": "You have mastered setting guidelines for necessary models and writing guidelines for good modeling practices, which exceeds the required competency level.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "Leverage your advanced skills in systems modeling and analysis to take on more leadership roles in your projects. You could also share your knowledge by creating training materials or leading workshops to help others improve their modeling skills."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You are well-aligned with the required level for decision management, demonstrating a strong understanding of decision support methods and proper decision-making processes.", "competency_name": "Decision Management", "improvement_areas": "As you have already achieved the required level, focus on maintaining and continually enhancing your decision-making skills through practice and exposure to diverse scenarios."}, {"user_strengths": "You exceed the required level by being able to not only understand but also apply complex project management skills, including defining project mandates and producing meaningful reports.", "competency_name": "Project Management", "improvement_areas": "Leverage your advanced skills by mentoring others or taking on more challenging projects to refine and expand your project management capabilities."}, {"user_strengths": "You recognize the importance of information and knowledge management.", "competency_name": "Information Management", "improvement_areas": "To meet the required level, strive to deepen your understanding of key platforms for knowledge transfer and learn to determine the appropriate distribution of information."}, {"user_strengths": "You exceed the required understanding by being able to apply configuration management tools and define relevant items effectively.", "competency_name": "Configuration Management", "improvement_areas": "Continue applying your skills in practical settings and consider sharing your knowledge with peers to further solidify your competency."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "", "competency_name": "Leadership", "improvement_areas": "Your current level indicates a lack of awareness or knowledge in the area of Leadership. To meet the required understanding, it's essential to develop a grasp of how to define objectives clearly and lead a team effectively."}, {"user_strengths": "You excel in managing and optimizing complex projects and processes through self-organization. Your ability to master this skill is commendable and exceeds the required level.", "competency_name": "Self-Organization", "improvement_areas": ""}, {"user_strengths": "", "competency_name": "Communication", "improvement_areas": "Currently, there is a substantial gap in your knowledge concerning Communication. To elevate your understanding, focus on recognizing the importance of effective communication and its application in systems engineering."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You meet the required level for understanding, identifying, deriving, and documenting requirements. Your familiarity with different types and levels of requirements, as well as your ability to comprehend requirement documents and interface specifications, are in line with the expectations.", "competency_name": "Requirements Definition", "improvement_areas": ""}, {"user_strengths": "Your expertise in system architecting surpasses the required level. You possess the ability to manage highly complex models and improve architectural processes, which exceeds the basic expectation of creating models of average complexity.", "competency_name": "System Architecting", "improvement_areas": ""}, {"user_strengths": "", "competency_name": "Integration, Verification, Validation", "improvement_areas": "You currently lack the knowledge in this competency area. It is essential to gain an understanding of how to read and interpret test plans, test cases, and results to meet the required level."}, {"user_strengths": "You have a good understanding of the operation, service, and maintenance phases, which aligns well with the required basic familiarity and consideration of these phases in development.", "competency_name": "Operation and Support", "improvement_areas": ""}, {"user_strengths": "You excel in implementing and leading Agile methods, which is beyond the expectation of merely working effectively within an Agile environment. Your ability to define, implement, and promote Agile practices is a significant strength.", "competency_name": "Agile Methods", "improvement_areas": ""}], "competency_area": "Technical"}]	2024-12-31 00:01:00.071165
43	63	1	[{"feedbacks": [{"user_strengths": "You have a solid understanding of how individual components interact within a system.", "competency_name": "Systems Thinking", "improvement_areas": "However, to meet the required level, you need to enhance your ability to disseminate systemic thinking throughout your organization and inspire your colleagues."}, {"user_strengths": "You are capable of identifying and assessing all relevant lifecycle phases within your scope.", "competency_name": "Lifecycle Consideration", "improvement_areas": "To reach the required level, focus on developing your skills in evaluating concepts that consider all lifecycle phases comprehensively."}, {"user_strengths": "You excel in promoting agile thinking and inspiring others within the organization.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Since you are already at the required level in this competency, continue to develop and refine these skills to maintain your leadership and influence."}, {"user_strengths": "You are acquainted with the basics of modeling and understand its benefits.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To meet the required level, you should aim to master the ability to set modeling guidelines and develop best practices for systems modeling."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have a good understanding of decision support methods and are aware of the decisions you can make independently.", "competency_name": "Decision Management", "improvement_areas": "Focus on developing skills to evaluate decisions more critically and gain experience in establishing and defining decision-making bodies and guidelines."}, {"user_strengths": "You have a foundational grasp of your role within a project plan and are familiar with common project management methods.", "competency_name": "Project Management", "improvement_areas": "Work towards enhancing your ability to identify process inadequacies and improve communication skills for conveying project reports, plans, and mandates effectively to stakeholders."}, {"user_strengths": "You effectively define storage structures and documentation guidelines, ensuring relevant information is accessible.", "competency_name": "Information Management", "improvement_areas": "Aim to broaden your expertise to encompass a comprehensive information management process that integrates all aspects of information flow and storage."}, {"user_strengths": "You excel in identifying relevant configuration items and creating comprehensive configurations. Your ability to propose improvements and assist others is a strong asset.", "competency_name": "Configuration Management", "improvement_areas": "Continue refining your skills and sharing your expertise in this area, as you already meet the required competency level."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "Currently, you are at the beginning of your journey in developing leadership skills.", "competency_name": "Leadership", "improvement_areas": "To progress, consider seeking mentorship from experienced leaders, attending leadership workshops, and actively taking on small leadership roles to practice and build your skills."}, {"user_strengths": "You are just starting to explore self-organization techniques.", "competency_name": "Self-Organization", "improvement_areas": "You can enhance this skill by using tools like time management apps, learning from organizational books or courses, and applying these principles in your daily work to gradually improve your ability to manage projects."}, {"user_strengths": "You are beginning to understand the importance of communication in a professional setting.", "competency_name": "Communication", "improvement_areas": "To advance, participate in communication skills workshops, practice active listening, and engage in discussions with peers to develop a more effective communication style."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You possess a solid understanding of identifying, deriving, writing, and documenting requirements, as well as creating context descriptions and interface specifications.", "competency_name": "Requirements Definition", "improvement_areas": "Develop skills to recognize deficiencies in the process and improve suggestions for enhancement. Engage more with stakeholders to discuss context and interface descriptions."}, {"user_strengths": "You are capable of creating architectural models of average complexity, ensuring they are reproducible and aligned with the methodology.", "competency_name": "System Architecting", "improvement_areas": "Advance your skills to handle highly complex models, identify shortcomings in the methodology, and suggest process improvements."}, {"user_strengths": "You excel in setting up testing strategies and experimental plans, and in orchestrating and documenting tests and simulations.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Continue to enhance your proactive approach and keep abreast of the latest methodologies in testing and validation."}, {"user_strengths": "You understand the integration of operation, service, and maintenance phases into development.", "competency_name": "Operation and Support", "improvement_areas": "Aim to master defining organizational processes for operation, maintenance, and servicing. Consider seeking mentorship or additional training in this area."}, {"user_strengths": "Currently, there is a significant knowledge gap in this area.", "competency_name": "Agile Methods", "improvement_areas": "Begin by understanding the fundamentals of Agile methodologies. Use resources like online courses, workshops, and real-world practice to gradually build your competency to a level where you can implement and lead Agile methods effectively."}], "competency_area": "Technical"}]	2024-12-31 12:07:33.996857
44	64	1	[{"feedbacks": [{"user_strengths": "You are performing well in systems thinking, as your recorded level matches the required level. Your ability to analyze the current system and derive improvements is a strong asset.", "competency_name": "Systems Thinking", "improvement_areas": "Since you already meet the required competency level, you can focus on deepening your knowledge and application in systems thinking, possibly moving towards teaching others this skill or leading projects that require complex systems analysis."}, {"user_strengths": "You exceed the required level in lifecycle consideration, showcasing a strong ability to evaluate concepts regarding all lifecycle phases, which is more advanced than just understanding their importance.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Leverage your advanced knowledge in lifecycle consideration to mentor others or to take on more responsibility in projects that span multiple lifecycle phases. This can help in applying your skills more broadly and deepening your expertise."}, {"user_strengths": "Currently, there is a notable gap in this area as your knowledge does not meet the required level.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To improve in customer and value orientation, start by familiarizing yourself with the basics of agile thinking. Engage in trainings or workshops on customer-centric approaches and how to integrate these into daily work. Seek mentorship or join a team where this skill is critical to accelerate learning."}, {"user_strengths": "You have a basic understanding of systems modeling and its benefits.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To meet the required level, enhance your understanding of how models support work and practice reading and interpreting simple models. Consider participating in hands-on modeling exercises, taking courses on advanced modeling techniques, or working closely with more experienced modelers."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have a good awareness of decision-making bodies and the processes involved, which is a solid foundation.", "competency_name": "Decision Management", "improvement_areas": "To meet the required understanding of decision support methods and autonomous decision-making, consider engaging in training sessions that focus on decision-making processes and tools. Additionally, participating in committee meetings or decision-making groups could provide practical experience and insights."}, {"user_strengths": "Your ability to identify process inadequacies and effectively communicate with stakeholders is excellent and meets the required competency level.", "competency_name": "Project Management", "improvement_areas": "Continue to refine these skills and perhaps take on more complex project management roles to further enhance your capabilities."}, {"user_strengths": "Currently, there is a significant gap in this competency area as you lack basic knowledge.", "competency_name": "Information Management", "improvement_areas": "You need to start with foundational knowledge in information management. Online courses or workshops on information systems and data management could be very beneficial. Engaging with your organization's IT department for practical insights and mentoring might also help bridge this gap."}, {"user_strengths": "You excel in identifying relevant configuration items and managing comprehensive configurations across items, which surpasses the required level.", "competency_name": "Configuration Management", "improvement_areas": "Maintain your high level of competency and continue to share your knowledge and solutions with others to foster a learning environment."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have a solid understanding of the relevance of defining objectives for a system and are capable of articulating these objectives clearly to the entire team.", "competency_name": "Leadership", "improvement_areas": "Since your recorded level meets the required level, continue to practice and refine your leadership skills by taking on more diverse projects and seeking feedback from peers and mentors."}, {"user_strengths": "You excel in independently managing projects, processes, and tasks using your self-organization skills.", "competency_name": "Self-Organization", "improvement_areas": "As your recorded level matches the required level in self-organization, continue to enhance this skill by exploring advanced project management tools and techniques that could further streamline your processes."}, {"user_strengths": "You are aware of the necessity of communication competencies.", "competency_name": "Communication", "improvement_areas": "To reach the required level, you need to enhance your understanding of the relevance of communication skills in systems engineering. Engage in training sessions or workshops focused on effective communication, and actively seek opportunities to practice these skills in real-world settings."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have a good understanding of how to identify, derive, and read requirements, which is foundational in systems engineering.", "competency_name": "Requirements Definition", "improvement_areas": "To advance your skills to the required level, focus on gaining practical experience in documenting, linking, and analyzing requirements independently. Consider working closely with a mentor or attending workshops that focus on advanced requirements management and documentation techniques."}, {"user_strengths": "You are aware of the significance of architectural models and their categorization in the development process.", "competency_name": "System Architecting", "improvement_areas": "To reach the required understanding, deepen your knowledge by studying architectural modeling languages and methodologies. Practical experience in reading and interpreting architectural models will also be beneficial. Participate in projects where you can observe and engage with experts in system architecting."}, {"user_strengths": "You excel in setting up testing strategies and orchestrating tests and simulations, which is critical for ensuring system reliability and performance.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Continue to refine and share your expertise in test case derivation and documentation, as your recorded level is already beyond the required level. Mentor others in your team to help elevate the overall competency in this area."}, {"user_strengths": "You are adept at executing operation, service, and maintenance phases and identifying improvements, demonstrating practical application in real-world scenarios.", "competency_name": "Operation and Support", "improvement_areas": "Enhance your understanding of how these phases integrate into the overall development life cycle. Consider studying lifecycle management theories and engaging in discussions with lifecycle experts to gain deeper insights."}, {"user_strengths": "You have a firm grasp of Agile fundamentals and the impact of Agile practices on project success.", "competency_name": "Agile Methods", "improvement_areas": "To elevate your capability to the required level, seek opportunities to actively participate in Agile projects. Engage in roles that allow you to apply Agile methods dynamically across different project scenarios. Training in advanced Agile techniques could also be beneficial."}], "competency_area": "Technical"}]	2024-12-31 17:41:27.676431
45	65	1	[{"feedbacks": [{"user_strengths": "You have a good understanding of how individual components interact within a system.", "competency_name": "Systems Thinking", "improvement_areas": "Enhance your ability to analyze current systems and derive continuous improvements. Consider engaging in practical exercises or projects that focus on system analysis and improvement, attending workshops, and seeking mentorship from experienced colleagues."}, {"user_strengths": "You excel in evaluating concepts across all lifecycle phases, which is a higher level than required.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Continue to leverage and share your expertise in this area. You might consider leading discussions or workshops to help peers understand the importance of lifecycle considerations."}, {"user_strengths": "Currently, there is a significant knowledge gap in this area.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Start by gaining a basic understanding of how to integrate agile thinking into daily work. Online courses, reading materials on agile methodologies, and practical involvement in agile projects could be beneficial."}, {"user_strengths": "You meet the required understanding of how models support work and the ability to read simple models.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "Although your current level meets the requirements, consider advancing your skills in creating and manipulating complex models to provide further value in your role."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "Your understanding of decision support methods is solid, and you have a good grasp of which decisions you can make independently versus those requiring committee approval.", "competency_name": "Decision Management", "improvement_areas": "Since your recorded level meets the required level, continue to stay updated on best practices and case studies in decision management to further enhance your proficiency."}, {"user_strengths": "You are at the beginning of your journey in understanding project management.", "competency_name": "Project Management", "improvement_areas": "To reach the required level, focus on gaining practical experiences in project planning and stakeholder communication. Consider enrolling in a project management course or seek mentorship from experienced project managers."}, {"user_strengths": "You excel in defining storage structures and documentation guidelines, ensuring that information is available where and when it's needed.", "competency_name": "Information Management", "improvement_areas": "Although you currently operate above the required level, maintaining an understanding of key knowledge transfer platforms and the information sharing process is crucial. It might be beneficial to align your application skills with strategic understanding to optimize information flow."}, {"user_strengths": "You have an in-depth ability to manage configurations, identify relevant items, and propose improvements effectively.", "competency_name": "Configuration Management", "improvement_areas": "Your recorded level exceeds the required level. Continue refining your skills and perhaps share your knowledge through training or workshops to assist others in your team."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "Your current level in leadership surpasses the required level, showcasing your ability to strategically develop team members and enhance their problem-solving skills.", "competency_name": "Leadership", "improvement_areas": "Continue to refine and expand your leadership skills by mentoring others in your team, ensuring that the objectives you set are not only understood but also embraced by all team members."}, {"user_strengths": "You meet the required level for self-organization. Your ability to manage projects, processes, and tasks independently is commendable.", "competency_name": "Self-Organization", "improvement_areas": "To further enhance your self-organization skills, consider exploring advanced project management tools and methodologies, and perhaps share your techniques with colleagues to foster a collaborative and efficient work environment."}, {"user_strengths": "You are aware of the importance of effective communication in systems engineering.", "competency_name": "Communication", "improvement_areas": "To meet the required level of understanding in communication, aim to deepen your knowledge about how effective communication directly impacts project success. Engage in workshops or training sessions focused on communication skills, and seek opportunities to practice these skills in your daily interactions."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You are currently meeting the required level in Requirements Definition, showcasing your ability to independently handle and analyze requirements.", "competency_name": "Requirements Definition", "improvement_areas": "Since you are already at the required level, focus on refining and updating your skills as new methods and tools emerge in the field."}, {"user_strengths": "You meet the necessary understanding for System Architecting, being able to comprehend architectural models and their relevance in the development process.", "competency_name": "System Architecting", "improvement_areas": "To further strengthen this competency, try engaging more actively with architectural design processes or participating in workshops that focus on advanced architectural techniques."}, {"user_strengths": "You exceed the required level in this competency, demonstrating an advanced capability in setting up testing strategies and orchestrating tests.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Leverage your advanced skills by mentoring others or leading initiatives to improve testing protocols within your team."}, {"user_strengths": "You have a solid understanding of the integration of operation, service, and maintenance phases into development, aligning with the required level.", "competency_name": "Operation and Support", "improvement_areas": "To deepen your knowledge, consider exploring case studies or real-life examples where these phases have been critical to project success."}, {"user_strengths": "You have a good foundation in understanding Agile methods and their impact.", "competency_name": "Agile Methods", "improvement_areas": "To reach the applied level, start actively participating in Agile projects and seek feedback on your application of Agile techniques from experienced colleagues."}], "competency_area": "Technical"}]	2024-12-31 18:12:14.938586
46	66	1	[{"feedbacks": [{"user_strengths": "You have a solid understanding of the interaction between the components of a system, aligning perfectly with the requirements.", "competency_name": "Systems Thinking", "improvement_areas": "Since you have achieved the required level, you might consider deepening your knowledge by exploring complex system interactions in varying contexts."}, {"user_strengths": "Your ability to evaluate concepts through all lifecycle phases exceeds the requirement, showcasing your comprehensive grasp and application in this area.", "competency_name": "Lifecycle Consideration", "improvement_areas": "You could leverage your advanced skills by mentoring peers or leading initiatives that focus on lifecycle optimization within your projects."}, {"user_strengths": "You are adept at applying agile methodologies to develop systems focused on customer benefit, meeting the required competency level.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To further enhance your proficiency, consider engaging in advanced agile training or workshops that focus on maximizing customer value in system design."}, {"user_strengths": "You are effectively defining and differentiating system models independently, meeting the expectations for this competency.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To expand your expertise, consider exploring advanced modeling techniques or tools that could provide deeper insights or efficiencies in system analysis."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "Your understanding of decision support methods is on par with what is required. You effectively differentiate decisions that you can handle yourself and those that need committee involvement, aligning with the required level.", "competency_name": "Decision Management", "improvement_areas": "Since your current level meets the required standard, continue to apply your knowledge in practical settings and stay updated with new decision-making tools and methodologies to maintain your competency."}, {"user_strengths": "Currently, there's an opportunity for significant growth in this area.", "competency_name": "Project Management", "improvement_areas": "To bridge the gap between your recorded level and the required level, begin by familiarizing yourself with the basics of project management. Online courses or workshops on project management principles could be beneficial. Engage with project managers in your organization to gain insights and practical experience. Developing a basic understanding of creating project plans and managing project statuses will be crucial."}, {"user_strengths": "You excel in Information Management, going beyond the required understanding level by being able to define comprehensive information management processes.", "competency_name": "Information Management", "improvement_areas": "Leverage your advanced skills by mentoring others or leading initiatives to improve information management practices within your organization. This will not only reinforce your own knowledge but also benefit your team."}, {"user_strengths": "You have a basic awareness of the configuration management tools, which is a good starting point.", "competency_name": "Configuration Management", "improvement_areas": "To meet the required understanding, focus on deepening your knowledge about defining configuration items and the process of using these tools effectively. Participate in hands-on training sessions or seek mentorship from experienced colleagues to enhance your practical skills in creating relevant configurations."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have a basic awareness of the importance of leadership in your role, which is a good starting point.", "competency_name": "Leadership", "improvement_areas": "To meet the required level, focus on understanding how to define and articulate objectives clearly to your team. Enhancing your skills in setting clear, achievable goals could be beneficial. Consider seeking out leadership workshops or mentorship within your organization to observe and learn effective communication and goal-setting techniques."}, {"user_strengths": "You excel in self-organization, demonstrating a high ability to manage and optimize complex projects and processes. Your current competency level exceeds the required level, showcasing your strong capability in this area.", "competency_name": "Self-Organization", "improvement_areas": "Maintain and continue to refine these skills. You might consider sharing your strategies and techniques with peers to help them improve their self-organization skills, thereby enhancing overall team efficiency."}, {"user_strengths": "You have a solid understanding of the importance of communication, particularly in its application to systems engineering, which aligns with the required competency level.", "competency_name": "Communication", "improvement_areas": "Since you meet the required level, focus on continuous improvement. Practice active listening and clear communication in your daily interactions. Engage in training sessions that offer advanced communication strategies to further enhance your ability to convey complex ideas effectively."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You possess a strong ability to independently identify, derive, document, and analyze requirements, which surpasses the required understanding level.", "competency_name": "Requirements Definition", "improvement_areas": "As your competency in this area already exceeds the required level, focus on maintaining your skills and possibly mentoring others or leading initiatives to improve requirements processes in your team or organization."}, {"user_strengths": "You have advanced capabilities in creating and managing highly complex models and suggesting improvements, well beyond the required level of creating average complexity models.", "competency_name": "System Architecting", "improvement_areas": "Leverage your expertise to provide guidance to peers and contribute to the development of best practices in system architecting within your organization."}, {"user_strengths": "Currently, this area is a significant gap as you lack knowledge.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Begin by familiarizing yourself with the basics of integration, verification, and validation processes. Start by reading test plans, test cases, and understanding their results. Seek training opportunities or workshops to build this foundational knowledge."}, {"user_strengths": "You understand the integration of operation, service, and maintenance phases into development, which aligns with the required familiarity.", "competency_name": "Operation and Support", "improvement_areas": "Since you meet the required level, focus on deepening your understanding or applying this knowledge in practical scenarios to enhance your competency."}, {"user_strengths": "You recognize and list Agile values and methods, which is foundational.", "competency_name": "Agile Methods", "improvement_areas": "To meet the required level, you need to enhance your ability to work effectively in an Agile environment and apply Agile methods. Consider participating in Agile projects, attending Agile training, or obtaining a certification to improve your practical application of Agile methodologies."}], "competency_area": "Technical"}]	2025-01-03 20:11:02.639629
47	67	1	[{"feedbacks": [{"user_strengths": "You have demonstrated the ability to analyze your current system and identify areas for continuous improvement, which shows a solid application of systems thinking principles.", "competency_name": "Systems Thinking", "improvement_areas": "To elevate your competency to the required level, focus on extending your influence by promoting systemic thinking across the organization. Consider leading workshops or training sessions that emphasize the benefits of systems thinking and inspire your colleagues to adopt these strategies."}, {"user_strengths": "You have a good understanding of the importance of considering all lifecycle phases during development.", "competency_name": "Lifecycle Consideration", "improvement_areas": "To reach the required competency level, work on developing your ability to evaluate concepts with respect to all lifecycle phases. You could benefit from participating in projects that span multiple phases, or seeking mentorship from experienced colleagues who can provide insights on practical evaluations."}, {"user_strengths": "You excel in promoting agile thinking within the organization and inspiring others, meeting the highest required level in this competency.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Since you have achieved the required level, continue to enhance this competency by staying updated on the latest trends in agile methodologies and considering ways to integrate new ideas into your practice to keep your team motivated and engaged."}, {"user_strengths": "You possess a basic understanding of systems modeling and its benefits, which is a good starting point.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To advance to the required level, focus on deepening your practical skills in systems modeling. Consider enrolling in specialized courses or workshops that teach advanced modeling techniques and best practices. Additionally, actively seek out projects where you can apply these new skills and gain hands-on experience."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You are skilled in preparing and documenting decisions within your scope and applying decision support methods like utility analysis.", "competency_name": "Decision Management", "improvement_areas": "You should work on evaluating decisions more effectively and establishing decision-making bodies. Learning to define guidelines for decision-making will also help you reach the required level."}, {"user_strengths": "You have a good understanding of the project mandate and can create project plans and status reports independently.", "competency_name": "Project Management", "improvement_areas": "Aim to identify and suggest improvements in project management processes. Enhancing your skills in communicating project-related information to stakeholders will also be beneficial."}, {"user_strengths": "You excel in defining comprehensive information management processes.", "competency_name": "Information Management", "improvement_areas": "As your recorded and required levels are aligned, continue to refine and update your skills to maintain this competency."}, {"user_strengths": "You have a basic awareness of the importance of configuration management and are familiar with the tools used.", "competency_name": "Configuration Management", "improvement_areas": "Focus on identifying all relevant configuration items and developing comprehensive configurations. Learning to propose improvements and assist others in configuration management will help you meet the required competency level."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You excel in the area of Leadership, demonstrating a strategic ability to develop team members to enhance their problem-solving skills. This alignment with the required level indicates strong proficiency.", "competency_name": "Leadership", "improvement_areas": "Since you are already at the required level, focus on maintaining and further refining your leadership skills through continuous learning and by taking on new challenges that push your strategic boundaries."}, {"user_strengths": "You have a basic understanding of the concepts of self-organization.", "competency_name": "Self-Organization", "improvement_areas": "To meet the required level, aim to deepen your understanding and application of self-organization. Engage in training modules focused on project and process management, apply these principles in your daily work, and seek feedback to continuously improve."}, {"user_strengths": "You understand the importance of communication within systems engineering and recognize its relevance.", "competency_name": "Communication", "improvement_areas": "To achieve mastery in communication, practice active listening and engage in more complex communication scenarios within your work environment. Participate in workshops that emphasize interpersonal skills and seek mentorship from colleagues known for their communication expertise."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have a solid understanding of identifying, deriving, and writing different types and levels of requirements. Your ability to read and comprehend requirement documents and interface specifications is commendable.", "competency_name": "Requirements Definition", "improvement_areas": "To advance to the required level, focus on enhancing your skills in recognizing deficiencies in the requirements process and developing improvement suggestions. Practicing the creation of context and interface descriptions and discussing these with stakeholders will also be beneficial."}, {"user_strengths": "You excel in creating and managing highly complex models and identifying shortcomings in the process. Your ability to suggest improvements in the method or modeling language is exactly at the level required.", "competency_name": "System Architecting", "improvement_areas": "Since your current level meets the required standard, continue to refine these skills and stay updated with the latest trends and technologies in system architecting to maintain your competency."}, {"user_strengths": "Currently, you are at the beginning stage in this area.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "To meet the required level, you need to significantly develop your knowledge and skills. Start by familiarizing yourself with the basics of testing strategies, experimental plans, and the derivation of test cases. Engaging in training or workshops on these topics and seeking mentorship from experienced colleagues will be crucial."}, {"user_strengths": "You are familiar with the stages of operation, service, and maintenance, and understand the importance of considering these during development.", "competency_name": "Operation and Support", "improvement_areas": "To meet the required level of defining organizational processes for operation and maintenance, focus on gaining a deeper understanding of these processes. Participate in projects that involve these stages and seek opportunities to lead or participate in the planning and execution phases."}, {"user_strengths": "You effectively define and implement relevant Agile methods for projects, motivate others to adopt these methods, and successfully lead Agile teams.", "competency_name": "Agile Methods", "improvement_areas": "As you have already reached the required level, continue to enhance your leadership in Agile practices. Keeping up with new Agile trends and techniques will help you stay ahead and bring innovative practices to your teams."}], "competency_area": "Technical"}]	2025-01-03 20:23:11.017665
48	68	1	[{"feedbacks": [{"user_strengths": "You are meeting the required level for Systems Thinking, which is fundamental for understanding and managing complex systems.", "competency_name": "Systems Thinking", "improvement_areas": "Since you are at the expected level, focus on maintaining this competency through regular practice and staying updated with the latest systems thinking methodologies."}, {"user_strengths": "You exceed the required level in Lifecycle Consideration, which demonstrates a strong ability in managing and understanding the entire lifecycle of systems.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Leverage your advanced skills in Lifecycle Consideration to mentor others and lead projects that require detailed lifecycle analysis. Additionally, consider exploring related areas where you can apply your expertise."}, {"user_strengths": "", "competency_name": "Customer / Value Orientation", "improvement_areas": "It's crucial to develop a basic understanding of Customer / Value Orientation. Start by learning the fundamentals of how systems engineering processes can be aligned with customer needs and values. Online courses or workshops focusing on customer-centric design principles could be beneficial."}, {"user_strengths": "You have a basic understanding of Systems Modeling and Analysis.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To meet the required level, it's necessary to deepen your understanding. Engage in more complex modeling projects, take advanced courses, or work closely with a mentor in this area. Practical experience and targeted training will be key in advancing your skills."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "Starting point in Decision Management.", "competency_name": "Decision Management", "improvement_areas": "The recorded level is at the initial stage, while the required level is to have a good understanding. Focus on learning basic decision-making frameworks and their applications in different scenarios."}, {"user_strengths": "High proficiency in Project Management.", "competency_name": "Project Management", "improvement_areas": "Although the recorded level exceeds the required level, continue refining these skills to maintain excellence and adapt to new methodologies."}, {"user_strengths": "Meeting the required understanding level in Information Management.", "competency_name": "Information Management", "improvement_areas": "Keep updated with the latest practices and technologies in information management to maintain competency."}, {"user_strengths": "Your skill level in Configuration Management exceeds the basic requirement.", "competency_name": "Configuration Management", "improvement_areas": "Leverage this advanced understanding to mentor others or take on more complex projects."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have shown a high level of mastery in Leadership, surpassing the required understanding level. Your ability to effectively lead and manage teams is a significant asset.", "competency_name": "Leadership", "improvement_areas": "Since you already excel in this area, continue to apply your skills in real-world scenarios to further refine and demonstrate your leadership capabilities."}, {"user_strengths": "You are currently applying self-organization skills effectively, which is above the required understanding level.", "competency_name": "Self-Organization", "improvement_areas": "Continue to enhance your self-organization by setting higher personal standards and integrating advanced organizational tools and techniques into your daily routine."}, {"user_strengths": "Your competency in communication matches the required level, indicating a solid understanding of effective communication strategies.", "competency_name": "Communication", "improvement_areas": "To further enhance your communication skills, consider engaging in activities that require diverse communication styles, such as public speaking, writing workshops, or interpersonal communication training."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have demonstrated a strong mastery in the area of Requirements Definition, which is higher than the required level.", "competency_name": "Requirements Definition", "improvement_areas": "There are no improvements needed for this competency as you already exceed the required competency level."}, {"user_strengths": "Currently, this is a starting point for you.", "competency_name": "System Architecting", "improvement_areas": "Focus on developing basic knowledge and skills in System Architecting to reach the required application level. Consider enrolling in a foundational course or seeking mentorship from a colleague who is experienced in this domain."}, {"user_strengths": "You meet the required level of understanding for Integration, Verification, and Validation.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Continue to apply your knowledge and stay updated with the latest practices in this area to maintain your competency level."}, {"user_strengths": "Your knowledge in Operation and Support is at the required level.", "competency_name": "Operation and Support", "improvement_areas": "Maintain your current knowledge and look for opportunities to apply them in practical scenarios."}, {"user_strengths": "Your understanding of Agile Methods aligns with the required level.", "competency_name": "Agile Methods", "improvement_areas": "Continue to deepen your understanding and practical application of Agile Methods by participating in related projects or further training."}], "competency_area": "Technical"}]	2025-01-05 13:29:51.879596
49	69	1	[{"feedbacks": [{"user_strengths": "You have a solid understanding of systems thinking, which is crucial for viewing problems and solutions holistically.", "competency_name": "Systems Thinking", "improvement_areas": "To elevate your competency to the required application level, focus on practical exercises that involve solving real-world problems using systems thinking methodologies. Participating in workshops or case studies can also be very beneficial."}, {"user_strengths": "You excel in lifecycle consideration, surpassing the required competency level. This strength is essential for effectively managing the full lifecycle of systems engineering projects.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Continue to leverage this strength in your projects, and consider mentoring others to elevate the overall team competency."}, {"user_strengths": "You have a good understanding of how to align engineering projects with customer values and needs.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To advance to the application level, start by actively engaging with customers or stakeholders during the planning and development phases of projects. This direct interaction will enhance your practical skills in aligning system outputs with client expectations."}, {"user_strengths": "Currently, this is an area that needs significant improvement.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "Begin by acquiring foundational knowledge in systems modeling and analysis. Online courses, textbooks, or training sessions can provide the necessary theoretical understanding. Once you grasp the basics, apply this knowledge to small-scale projects to develop your skills further."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have a strong grasp on decision management, as your recorded level exceeds the required level for this competency.", "competency_name": "Decision Management", "improvement_areas": "Since you are already proficient, consider sharing your expertise with peers or junior colleagues to enhance team capabilities and decision-making processes."}, {"user_strengths": "You meet the required level for project management, indicating a solid understanding of the fundamentals in this area.", "competency_name": "Project Management", "improvement_areas": "To further develop your skills, you could seek opportunities to lead small projects or components of larger projects to apply and deepen your knowledge."}, {"user_strengths": "Currently, there are opportunities for significant growth in this area.", "competency_name": "Information Management", "improvement_areas": "To bridge the gap between your current level and the required understanding, consider engaging in targeted learning such as online courses, workshops, or seeking mentorship from a colleague who excels in information management."}, {"user_strengths": "You have a basic understanding of configuration management.", "competency_name": "Configuration Management", "improvement_areas": "To reach the required application level, focus on practical experience. Hands-on projects, participation in seminars or training sessions focusing on advanced configuration management practices will be beneficial."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You exhibit a solid application of leadership skills, which is a strong foundation to build upon.", "competency_name": "Leadership", "improvement_areas": "Aim to deepen your understanding of leadership theories and practices to meet the required level of understanding."}, {"user_strengths": "You have mastered self-organization, which is commendable and exceeds the necessary application level.", "competency_name": "Self-Organization", "improvement_areas": "Continue refining and leveraging your strong self-organization skills to enhance your productivity and efficiency."}, {"user_strengths": "You have a basic knowledge of communication skills.", "competency_name": "Communication", "improvement_areas": "Focus on applying these communication skills more effectively in practical scenarios to reach the required level of application."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have demonstrated a high level of proficiency in defining requirements, which is above the expected level.", "competency_name": "Requirements Definition", "improvement_areas": "Continue refining this skill and consider mentoring others or leading initiatives that involve complex requirements definition."}, {"user_strengths": "You have a foundational understanding of system architecting.", "competency_name": "System Architecting", "improvement_areas": "To enhance your skills, actively seek out projects that require more in-depth system architecture planning. Engage in training or workshops focused on advanced architecting techniques."}, {"user_strengths": "You have a basic knowledge of integration, verification, and validation processes.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "To meet the required understanding, consider participating in more hands-on integration activities and studying specific case studies or guidelines on verification and validation."}, {"user_strengths": "You excel in operation and support, surpassing the necessary competency level.", "competency_name": "Operation and Support", "improvement_areas": "Leverage your expertise to help improve operational efficiencies and support frameworks within your organization."}, {"user_strengths": "Currently, you are unfamiliar with agile methods.", "competency_name": "Agile Methods", "improvement_areas": "To reach the required competency level, start with foundational training in agile methodologies. Engage in projects that use these methods to gain practical experience."}], "competency_area": "Technical"}]	2025-01-14 19:52:36.733034
50	70	1	[{"feedbacks": [{"user_strengths": "You have a strong foundational understanding of Systems Thinking.", "competency_name": "Systems Thinking", "improvement_areas": "To elevate your application skills from understanding to applying, consider engaging more actively in projects that require complex system analysis and integration. Participate in workshops or training that focus on practical application of systems thinking in real-world scenarios."}, {"user_strengths": "You have mastered Lifecycle Consideration, which is above the required level for this competency.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Since you have already mastered this area, focus on sharing your knowledge with peers or consider taking on leadership roles in projects that involve extensive lifecycle management."}, {"user_strengths": "You meet the required level in understanding and applying customer and value orientation principles.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To further enhance your skills, try to lead customer engagement initiatives or develop strategies that directly address customer needs and add value to your projects."}, {"user_strengths": "Currently, your competency in Systems Modeling and Analysis needs development.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To reach the required level, start with foundational courses in systems modeling. Engage in projects under guidance to gain practical experience, and use tools like SysML to practice modeling various system components and interactions."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You are meeting the required level for Decision Management, demonstrating a strong grasp and application of the necessary skills.", "competency_name": "Decision Management", "improvement_areas": "Since you are currently at the desired level of competency, focus on maintaining and refining your skills through ongoing practice and staying updated with new methodologies in decision management."}, {"user_strengths": "You exceed the required level for Project Management, showcasing advanced skills and an ability to handle complex project management tasks.", "competency_name": "Project Management", "improvement_areas": "Leverage your advanced skills in project management to mentor others or take on more strategic roles in your projects. Continuing education in the latest project management tools and techniques can further enhance your proficiency."}, {"user_strengths": "You exceed the required level for Information Management, indicating a proficiency in managing and utilizing information effectively.", "competency_name": "Information Management", "improvement_areas": "Use your expertise to lead initiatives in information management, potentially offering training or workshops to colleagues. Keeping abreast of the latest trends in data management and analytics could further solidify your leadership in this area."}, {"user_strengths": "You are meeting the required level for Configuration Management, ensuring that system configurations are effectively managed and controlled.", "competency_name": "Configuration Management", "improvement_areas": "To continue excelling in this area, consider exploring advanced tools and methodologies in configuration management. Participating in forums or groups focused on this discipline can provide valuable insights and networking opportunities."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have demonstrated a strong command in leadership, surpassing the required competency level.", "competency_name": "Leadership", "improvement_areas": "Since you already exceed the required level, focus on maintaining and refining this skill, potentially mentoring others or taking on more strategic leadership roles."}, {"user_strengths": "You have a basic understanding of self-organization.", "competency_name": "Self-Organization", "improvement_areas": "To meet the required level, you should aim to apply self-organization principles more effectively in your daily work. Consider using tools like task management software, setting clear priorities, and regularly reviewing your workflows to improve efficiency."}, {"user_strengths": "You are already applying communication skills effectively.", "competency_name": "Communication", "improvement_areas": "Although you meet the required level, always look for ways to enhance your communication skills, such as practicing active listening, engaging in more complex discussions, or attending workshops."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "Your competency in Requirements Definition is at an advanced level, meaning you have a comprehensive understanding and ability to effectively define system requirements.", "competency_name": "Requirements Definition", "improvement_areas": "While you exceed the required competency level, continue to refine and share your expertise within your team or through leadership roles."}, {"user_strengths": "You meet the required competency level for System Architecting, indicating a solid understanding of how to design and structure system architectures.", "competency_name": "System Architecting", "improvement_areas": "To advance further, consider engaging in projects that push the boundaries of your current knowledge or seek advanced training and mentorship in this area."}, {"user_strengths": "You excel in Integration, Verification, and Validation, surpassing the required competency level. This showcases your advanced skills in ensuring systems meet their intended requirements.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Leverage your expertise by mentoring others or taking on more complex projects that challenge your current skill set."}, {"user_strengths": "You meet the required competency level in Operation and Support, indicating you understand the essential aspects of maintaining and supporting systems post-deployment.", "competency_name": "Operation and Support", "improvement_areas": "To enhance your skills, consider participating in more diverse operational scenarios or undergoing specialized training in emerging technologies."}, {"user_strengths": "You show an advanced understanding and application of Agile Methods, exceeding the necessary competency level.", "competency_name": "Agile Methods", "improvement_areas": "Since you are already proficient, you could lead Agile transformations within your organization or contribute to Agile community practices outside your current role."}], "competency_area": "Technical"}]	2025-01-14 20:07:16.27282
51	71	1	[{"feedbacks": [{"user_strengths": "You have a solid understanding of Systems Thinking.", "competency_name": "Systems Thinking", "improvement_areas": "To advance your level, try to apply these concepts in real-world projects, and seek feedback from more experienced colleagues. Engage in case studies or workshops that focus on Systems Thinking to enhance your practical skills."}, {"user_strengths": "You meet the required competency level for Lifecycle Consideration.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Continue to refine this skill by staying updated with the latest methodologies and engaging in continuous learning. You might also consider mentoring others to deepen your understanding and expertise."}, {"user_strengths": "You excel in Customer / Value Orientation, surpassing the required level.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Leverage your strength by leading initiatives that focus on improving customer value. Share your insights and strategies with peers to help elevate their competencies."}, {"user_strengths": "You have a good grasp of Systems Modeling and Analysis.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To reach the required application level, practice by participating in more complex modeling projects. Consider enrolling in advanced courses or workshops that focus on practical applications of systems modeling and analysis."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "Currently, there is a significant gap in the competency level for Decision Management.", "competency_name": "Decision Management", "improvement_areas": "To meet the required level of 'anwenden', it is important to start by gaining a foundational understanding of decision-making processes. Engage in training courses or workshops focused on decision-making strategies and critical thinking. Participating in decision-making meetings under the guidance of a mentor can provide practical experience."}, {"user_strengths": "You excel in Project Management, surpassing the required level of 'verstehen' with your mastery level.", "competency_name": "Project Management", "improvement_areas": "Since you already have a high competency, consider sharing your knowledge through mentoring others or leading advanced project management training sessions to further refine and apply your skills in new contexts."}, {"user_strengths": "You meet the required level of 'verstehen' in Information Management.", "competency_name": "Information Management", "improvement_areas": "To further enhance your skills, explore more advanced aspects or new technologies related to information management. Attending seminars or advanced courses can provide deeper insights and keep you updated with the latest trends."}, {"user_strengths": "You are currently at the 'beherrschen' level, which is above the required 'anwenden' level for Configuration Management.", "competency_name": "Configuration Management", "improvement_areas": "Maintain your high level by staying updated with the latest tools and practices in configuration management. Consider leading initiatives or training programs to share your expertise and insights with your team."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have shown exceptional proficiency in Leadership, surpassing the required level. Your ability to master this competency is a strong asset.", "competency_name": "Leadership", "improvement_areas": "Since you have already mastered this area, continue to refine and apply your leadership skills in more diverse scenarios to maintain and enhance your capability."}, {"user_strengths": "You have a basic understanding of Self-Organization.", "competency_name": "Self-Organization", "improvement_areas": "To meet the required level, focus on applying your knowledge in practical situations. Consider using tools like planners or digital apps to help manage your tasks and responsibilities more effectively. Engaging in workshops or trainings on time management and productivity could also be beneficial."}, {"user_strengths": "Currently, you are at the beginning stage of learning effective Communication techniques.", "competency_name": "Communication", "improvement_areas": "Since the required level is to apply these skills, it is crucial to actively work on improving your communication. You could start by participating in communication workshops, practicing public speaking, or even joining a local debate club to enhance your verbal skills. Regularly seek feedback on your communication style and effectiveness from peers or mentors to continually improve."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have demonstrated a mastery level in Requirements Definition, which is above the required application level. This indicates a strong ability to define, manage, and document system and software requirements efficiently.", "competency_name": "Requirements Definition", "improvement_areas": "Since you already exceed the required level, you could focus on sharing your knowledge and expertise with peers, possibly through mentoring or conducting workshops."}, {"user_strengths": "You have a solid understanding of System Architecting.", "competency_name": "System Architecting", "improvement_areas": "To meet the required application level, it would be beneficial to gain more practical experience. You could work on real-life projects under the guidance of a mentor, or take specific courses focused on architectural design and modeling."}, {"user_strengths": "Currently, there is a significant gap in this competency.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "To progress to the understanding level, start with foundational resources such as textbooks or online courses on integration, verification, and validation techniques. Hands-on practice through simulations or small-scale projects will also be crucial."}, {"user_strengths": "Your understanding of Operation and Support meets the required level, indicating a good grasp of maintaining and supporting systems post-deployment.", "competency_name": "Operation and Support", "improvement_areas": "To further enhance your skills, consider exploring advanced topics or new technologies that could improve system operation and support methodologies."}, {"user_strengths": "You are proficient in applying Agile Methods, which aligns with the required level.", "competency_name": "Agile Methods", "improvement_areas": "To continue excelling, stay updated with the latest Agile trends and techniques. Participating in Agile communities and workshops can also provide valuable insights and networking opportunities."}], "competency_area": "Technical"}]	2025-01-15 18:55:03.971317
52	72	1	[{"feedbacks": [{"user_strengths": "You have achieved the required competency level for Systems Thinking, which is great as it shows you can apply systems thinking principles effectively.", "competency_name": "Systems Thinking", "improvement_areas": "To further enhance your skills, consider engaging in more complex projects that require higher levels of systems integration, which will challenge and deepen your understanding."}, {"user_strengths": "You exceed the required competency level for Lifecycle Consideration, demonstrating a mastery level. This indicates a profound understanding and ability to integrate lifecycle considerations into systems engineering tasks.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Although you are already performing above the required level, you can leverage your expertise by mentoring others or leading workshops to help peers elevate their understanding of lifecycle impacts in systems engineering."}, {"user_strengths": "You have a basic understanding of Customer / Value Orientation.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To achieve the required level, focus on applying your knowledge in real-world scenarios. Participate in projects that involve direct interaction with customers or stakeholders to gain practical experience and insights into their values and needs."}, {"user_strengths": "You have a good grasp of Systems Modeling and Analysis concepts.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To reach the required application level, practical application is essential. Engage in projects that involve complex systems modeling and analysis. Utilize simulation tools and software to translate theoretical knowledge into practical skills."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have a foundational understanding in Decision Management.", "competency_name": "Decision Management", "improvement_areas": "To meet the required level, focus on deepening your understanding of decision-making processes and their impacts. Participate in decision-making scenarios or case studies to enhance your analytical skills."}, {"user_strengths": "You are at the beginning of your journey in Project Management.", "competency_name": "Project Management", "improvement_areas": "Significant improvement is needed to meet the application level. Engage in project management courses and actively participate in project planning and execution to gain practical experience."}, {"user_strengths": "You are capable of applying Information Management practices effectively.", "competency_name": "Information Management", "improvement_areas": "To advance to a deeper understanding, focus on the theory behind information systems and their strategic management. Consider enrolling in advanced courses or seminars."}, {"user_strengths": "You meet the required competency level in Configuration Management, demonstrating good understanding and application.", "competency_name": "Configuration Management", "improvement_areas": "Maintain your competency through continuous learning and staying updated with the latest practices and tools in Configuration Management."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You are meeting the required level for leadership skills, demonstrating a solid understanding in this area.", "competency_name": "Leadership", "improvement_areas": "While you are meeting expectations, consider seeking opportunities to further refine and apply your leadership skills through real-world challenges and advanced leadership training."}, {"user_strengths": "You exceed the required level in self-organization, showing mastery where only application is necessary.", "competency_name": "Self-Organization", "improvement_areas": "Utilize your advanced skills in self-organization to mentor others and take on more complex projects that can benefit from your organizational strengths."}, {"user_strengths": "Currently, this is an area identified for significant improvement.", "competency_name": "Communication", "improvement_areas": "Focus on elevating your communication skills to at least the 'understand' level. Engage in training modules, active listening exercises, and practice scenarios that emphasize effective communication strategies."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You demonstrate a strong mastery in Requirements Definition, which is a critical aspect of systems engineering. Your ability to proficiently define the needs and required functionality early in the development cycle helps ensure that the product meets customer requirements and expectations.", "competency_name": "Requirements Definition", "improvement_areas": "Since you are already performing above the required level, you might consider sharing your expertise with peers or mentoring others who are less proficient in this area."}, {"user_strengths": "Currently, your exposure to System Architecting appears limited.", "competency_name": "System Architecting", "improvement_areas": "To bridge this gap, focus on understanding the fundamental concepts and principles of System Architecting. You might start by attending workshops or online courses focused on basic architectural design principles and their applications. Engaging in projects under the guidance of a mentor who is proficient in this area can also be extremely beneficial."}, {"user_strengths": "You have a basic understanding of Integration, Verification, and Validation, which are essential for ensuring that systems work together and meet all technical requirements.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "To elevate your proficiency to the required level, seek additional hands-on experience through projects that allow you to apply these concepts in real-world scenarios. Participating in more detailed training sessions or workshops can also help deepen your understanding and practical skills."}, {"user_strengths": "You are capable of applying knowledge in Operation and Support effectively.", "competency_name": "Operation and Support", "improvement_areas": "To reach a deeper understanding, it would be beneficial to explore case studies and real-world examples that highlight the lifecycle of systems operations and the challenges faced during support phases. Consider engaging more with specialists in this area to gain insights and practical knowledge."}, {"user_strengths": "You excel in Agile Methods, showing an advanced level of proficiency that surpasses the required level.", "competency_name": "Agile Methods", "improvement_areas": "Leverage your expertise by leading agile projects or conducting training sessions for your team. This not only helps your organization but also solidifies your knowledge and skills in agile practices."}], "competency_area": "Technical"}]	2025-01-15 18:58:16.830758
53	73	1	[{"feedbacks": [{"user_strengths": "Your current level in Systems Thinking, where you apply knowledge effectively, is commendable as it showcases your ability to utilize this skill practically in your role.", "competency_name": "Systems Thinking", "improvement_areas": "While your application of systems thinking is strong, there is an opportunity to deepen your understanding to ensure a robust grasp of the underlying principles and theories. Engaging with foundational texts or courses on systems thinking and discussing theories with peers could enhance your understanding."}, {"user_strengths": "You excel in Lifecycle Consideration, indicating a mastery level of understanding and application in your work. This competency does not require further advancement per the current standards, showcasing your expertise.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Since you have mastered this area, consider mentoring others or leading workshops to share your knowledge and experience."}, {"user_strengths": "You have a solid understanding of Customer / Value Orientation, which is critical for ensuring that projects meet customer needs and provide real value.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To further enhance this competency, you might consider engaging more directly with customers to receive feedback and better understand their perspectives and needs."}, {"user_strengths": "Currently, this is an area identified for significant improvement.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To reach the required understanding level in Systems Modeling and Analysis, consider starting with introductory courses or tutorials that cover basic concepts and tools. Practical application through small projects or case studies can also solidify your knowledge."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have demonstrated competency in Decision Management at a level where no specific requirement is set, indicating a solid understanding of the area.", "competency_name": "Decision Management", "improvement_areas": "As there is no requirement level set, continue to apply your skills in practical scenarios to maintain and further develop your expertise."}, {"user_strengths": "Currently, there is no requirement for competency in Project Management.", "competency_name": "Project Management", "improvement_areas": "Even though there is no formal requirement, gaining at least a foundational understanding could enhance your capabilities in managing and leading projects."}, {"user_strengths": "You meet the required competency level for Information Management, showing your ability to effectively apply these skills in practical settings.", "competency_name": "Information Management", "improvement_areas": "Continue to practice and possibly explore advanced techniques or tools to stay current and further enhance your competency."}, {"user_strengths": "You excel in Configuration Management, surpassing the non-existent requirement and demonstrating mastery in this area.", "competency_name": "Configuration Management", "improvement_areas": "Leverage your expertise to mentor others and maybe consider sharing your knowledge through workshops or seminars."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You are on track with the required level for leadership skills, showing a good understanding of how to guide and influence others effectively.", "competency_name": "Leadership", "improvement_areas": "To enhance your leadership skills further, consider taking on more leadership roles in projects, seeking feedback from peers and mentors, and studying leadership styles and their impacts on team dynamics."}, {"user_strengths": "You excel in self-organization, mastering this skill beyond the required level. This indicates strong capabilities in managing your time and responsibilities effectively.", "competency_name": "Self-Organization", "improvement_areas": "Leverage your advanced self-organization skills to mentor others or lead workshops. Sharing your techniques can help improve team productivity and provide personal satisfaction."}, {"user_strengths": "You have basic knowledge in communication.", "competency_name": "Communication", "improvement_areas": "To reach the required level, focus on developing a deeper understanding of effective communication techniques. Engage in workshops, practice active listening, participate in speaking engagements, and seek feedback on your communication style to enhance your proficiency."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "Currently, your level in Requirements Definition is at an initial stage.", "competency_name": "Requirements Definition", "improvement_areas": "Since the required level is 'verstehen', you will need to deepen your understanding of how to define and manage system requirements effectively. Consider enrolling in workshops or online courses focused on requirements engineering, and actively participate in projects where you can practice these skills under supervision."}, {"user_strengths": "You meet the required competency level in System Architecting, which indicates a solid understanding of how to design systems architectures.", "competency_name": "System Architecting", "improvement_areas": "To further enhance your expertise, engage with more complex projects that challenge your current skills or seek mentorship from experienced architects within your organization."}, {"user_strengths": "You excel in Integration, Verification, and Validation, showing mastery in these critical areas of systems engineering.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Continue to apply your skills in diverse projects to maintain and expand your expertise. Additionally, consider sharing your knowledge through training or mentoring junior engineers."}, {"user_strengths": "You have a good understanding of Operation and Support, meeting the required proficiency level.", "competency_name": "Operation and Support", "improvement_areas": "To advance further, stay updated with the latest tools and techniques in operational support systems. Participation in ongoing training programs or certifications can be beneficial."}, {"user_strengths": "Your mastery in Agile Methods demonstrates exceptional competency, well beyond the basic requirements.", "competency_name": "Agile Methods", "improvement_areas": "Leverage your expertise by leading agile projects and initiatives. Additionally, contributing to workshops or speaking at conferences could further establish your leadership in this area."}], "competency_area": "Technical"}]	2025-01-15 20:02:02.67324
54	74	1	[{"feedbacks": [{"user_strengths": "You have a good understanding of Systems Thinking.", "competency_name": "Systems Thinking", "improvement_areas": "To advance to the required mastery level, it's important to apply Systems Thinking in more complex scenarios and decision-making processes. Consider participating in simulation projects or systems dynamics workshops to deepen your practical application skills."}, {"user_strengths": "You meet the required competency level for Lifecycle Consideration, indicating strong abilities in managing and considering the full lifecycle of systems.", "competency_name": "Lifecycle Consideration", "improvement_areas": "To continue excelling, stay updated with the latest methodologies and best practices in lifecycle management through professional development courses and industry conferences."}, {"user_strengths": "You meet the required competency level for Customer / Value Orientation, demonstrating a strong focus on delivering value to customers.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Maintain this competency by regularly seeking feedback from customers and stakeholders to align system objectives with customer needs and values."}, {"user_strengths": "You meet the required competency level for Systems Modeling and Analysis, indicating proficiency in using various modeling tools and analytical techniques.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To enhance your skills, consider exploring advanced modeling techniques and tools. Participating in specialized training or certification programs can provide deeper insights into cutting-edge practices in systems modeling and analysis."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have mastered decision management to the required level, demonstrating excellent proficiency in making informed decisions that align with project goals and organizational strategies.", "competency_name": "Decision Management", "improvement_areas": "Maintain your current level of expertise and continue to stay updated with new decision-making tools and methodologies to enhance your skills further."}, {"user_strengths": "You have mastered project management to the required level, showcasing your ability to effectively manage resources, timelines, and project scopes.", "competency_name": "Project Management", "improvement_areas": "To further enhance your project management skills, consider exploring advanced project management techniques and software. Engage in complex projects to apply these new tools and methods in a real-world setting."}, {"user_strengths": "You are applying information management skills effectively.", "competency_name": "Information Management", "improvement_areas": "To meet the required mastery level, focus on deepening your understanding of data governance, security measures, and advanced IT solutions. Engage in training or certification programs to elevate your skills to the master level."}, {"user_strengths": "You have mastered configuration management to the required level, showing strong capabilities in maintaining consistency of product performance and functional attributes throughout its life cycle.", "competency_name": "Configuration Management", "improvement_areas": "Continue to enhance your skills by staying updated with the latest tools and technologies in configuration management. Participate in workshops or seminars to keep your knowledge fresh and applicable."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "Currently, you are at the beginning of your journey in leadership.", "competency_name": "Leadership", "improvement_areas": "You need to develop this competency to meet the required mastery level. Engage in leadership workshops, seek opportunities for leading small projects, and consider finding a mentor who excels in leadership."}, {"user_strengths": "You have mastered self-organization, which is crucial for managing both time and resources effectively.", "competency_name": "Self-Organization", "improvement_areas": "Maintain your current level of competency. Continue to refine and adapt your organizational methods as your responsibilities or environments change."}, {"user_strengths": "You excel in communication, demonstrating a mastery that is well-suited for clear and effective exchanges in professional settings.", "competency_name": "Communication", "improvement_areas": "Continue practicing and enhancing your communication skills. Stay updated with new tools and techniques to ensure your skills remain relevant and strong."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You demonstrate thorough expertise in defining system requirements, which is crucial for setting clear goals and expectations for system functionality.", "competency_name": "Requirements Definition", "improvement_areas": "Since you already excel in this area, consider mentoring others or leading workshops to share your knowledge and experiences."}, {"user_strengths": "You have mastered the skill of designing and organizing complex systems effectively, ensuring all parts work harmoniously together.", "competency_name": "System Architecting", "improvement_areas": "To further enhance your leadership in this area, you might explore the latest trends and technologies in system architecture to stay ahead."}, {"user_strengths": "Your proficiency in integrating, verifying, and validating systems ensures reliability and compliance with specifications.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Continuing education through seminars or specialized courses can help you stay updated with emerging tools and methodologies."}, {"user_strengths": "You are adept at managing the operational phase and providing ongoing support, which is essential for system longevity and user satisfaction.", "competency_name": "Operation and Support", "improvement_areas": "Consider engaging with user feedback more actively to anticipate and address potential system improvements or updates."}, {"user_strengths": "Your expertise in Agile methods shows your ability to adapt quickly and efficiently to changes, ensuring project agility and team dynamism.", "competency_name": "Agile Methods", "improvement_areas": "To continue leading in Agile practices, you might facilitate more cross-functional training sessions to enhance team versatility."}], "competency_area": "Technical"}]	2025-01-16 02:33:59.945272
55	75	1	[{"feedbacks": [{"user_strengths": "You have attained a level where you can apply systems thinking effectively.", "competency_name": "Systems Thinking", "improvement_areas": "However, to reach mastery, focus on further developing your ability to predict and evaluate complex system interactions and feedback loops in diverse scenarios."}, {"user_strengths": "You have mastered lifecycle consideration, aligning perfectly with the required level.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Maintain this competency through continuous learning and application in evolving contexts."}, {"user_strengths": "You have a good understanding of customer and value orientation.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To master this area, work on integrating customer feedback into the system design process more effectively and anticipate future needs and values of the market."}, {"user_strengths": "Currently, this is an area needing substantial development.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "Begin with foundational training in systems modeling tools and techniques. Engage in projects that require hands-on modeling to build practical experience."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have a good understanding of decision management which shows your ability to analyze and make informed decisions.", "competency_name": "Decision Management", "improvement_areas": "To reach the mastery level, consider engaging more actively in decision-making processes and seek feedback on your decisions to refine your judgment skills."}, {"user_strengths": "Currently, your foundation in project management is at a beginner level.", "competency_name": "Project Management", "improvement_areas": "To excel, you need to significantly enhance your skills. Start with basic project management courses and gradually take on small project responsibilities to build practical experience."}, {"user_strengths": "Your mastery in information management is commendable and meets the required competency level.", "competency_name": "Information Management", "improvement_areas": "Continue to stay updated with the latest trends and technologies to maintain your competency."}, {"user_strengths": "You have a solid understanding of configuration management.", "competency_name": "Configuration Management", "improvement_areas": "To achieve mastery, deepen your practical experience by taking on more responsibilities in this area or attending advanced workshops."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You are currently applying your leadership skills effectively.", "competency_name": "Leadership", "improvement_areas": "To elevate your leadership skills to the 'beherrschen' level, consider engaging in advanced leadership training programs. Seek opportunities to lead larger teams or projects, and actively solicit feedback from peers and mentors to refine your leadership style and effectiveness."}, {"user_strengths": "You have mastered self-organization, meeting the required competency level.", "competency_name": "Self-Organization", "improvement_areas": "Maintain this competency by keeping up with new organizational tools and techniques. Consider sharing your expertise through workshops or mentoring others in your team to help them improve their self-organization skills."}, {"user_strengths": "You have a basic understanding of communication principles.", "competency_name": "Communication", "improvement_areas": "To advance to the 'beherrschen' level, focus on enhancing your communication skills through various training such as public speaking, writing workshops, or interpersonal communication courses. Engage in more projects that require you to present and communicate complex information to diverse audiences."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "Currently, there is no recorded strength in this area as the competency level is at the beginning stage.", "competency_name": "Requirements Definition", "improvement_areas": "To improve in Requirements Definition, consider enrolling in specialized courses or workshops that focus on understanding and defining system requirements. Engage in projects that allow you to practice these skills under the guidance of a mentor who is proficient in this area."}, {"user_strengths": "You have a good understanding of System Architecting, which is a solid foundation.", "competency_name": "System Architecting", "improvement_areas": "To advance your skills to the required level, seek opportunities to lead small architecture projects or participate in larger ones. Attending advanced seminars or obtaining certifications in system architecture could also be beneficial."}, {"user_strengths": "Currently, there is no recorded strength in this area as the competency level is at the beginning stage.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "To develop skills in Integration, Verification, and Validation, consider hands-on training or simulation exercises. Collaborating with experienced engineers on integration projects can provide practical experience and insights."}, {"user_strengths": "You have a good understanding of Operation and Support, which is beneficial.", "competency_name": "Operation and Support", "improvement_areas": "To reach the mastery level, involve yourself in operational troubleshooting and support scenarios. This could include shadowing experts or taking on roles that provide direct exposure to operational challenges."}, {"user_strengths": "You have mastered Agile Methods, which is excellent as it meets the required competency level.", "competency_name": "Agile Methods", "improvement_areas": "Maintain your proficiency in Agile Methods by staying updated with the latest agile practices and technologies. Consider sharing your knowledge through mentoring or leading workshops."}], "competency_area": "Technical"}]	2025-01-16 10:22:55.025132
56	76	1	[{"feedbacks": [{"user_strengths": "You have a good understanding of Systems Thinking, which is crucial for grasping how system components interact and impact each other.", "competency_name": "Systems Thinking", "improvement_areas": "To move from understanding to applying, consider engaging in more practical scenarios where you can use systems thinking to solve complex problems. Hands-on projects or case studies could be very beneficial."}, {"user_strengths": "You excel in Lifecycle Consideration, demonstrating mastery in considering the entire lifecycle of systems.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Since your recorded level exceeds the required, you might consider sharing your expertise with colleagues or mentoring others to strengthen your team's overall competency."}, {"user_strengths": "You meet the required level for Customer / Value Orientation, understanding and applying principles that focus on delivering value to customers.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To enhance your skills, try to lead projects that directly interact with customers or involve critical customer feedback to refine system value propositions."}, {"user_strengths": "You are familiar with the basics of Systems Modeling and Analysis.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To meet the required level of applying these skills, seek additional training or workshops. Practical application through projects or simulations can also help deepen your understanding and ability to analyze systems effectively."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You currently excel in the area of Decision Management, exhibiting a mastery level that exceeds the required application level. This indicates a strong capability in making critical decisions efficiently and effectively.", "competency_name": "Decision Management", "improvement_areas": "Since you already surpass the needed competency level, focus on maintaining this expertise and perhaps consider mentoring others or taking on additional responsibilities that leverage this strength."}, {"user_strengths": "You meet the required competency level for Project Management, demonstrating effective skills in planning, executing, and closing projects.", "competency_name": "Project Management", "improvement_areas": "To further enhance your capability, you might explore advanced project management techniques or certifications (like PMP or Agile methodologies) to deepen your expertise and adaptability in managing diverse projects."}, {"user_strengths": "In the area of Information Management, you also demonstrate a level of mastery higher than what is required. This shows your strong ability in managing and utilizing information to support organizational objectives.", "competency_name": "Information Management", "improvement_areas": "Leverage your advanced skills by staying updated with the latest trends and technologies in information management. You could also share your knowledge through workshops or training sessions within your organization."}, {"user_strengths": "You have a basic understanding of Configuration Management.", "competency_name": "Configuration Management", "improvement_areas": "Since the recorded level is below the required application level, focus on developing practical experience in this area. Engage in projects that allow you to apply configuration management practices, and consider participating in related workshops or courses to enhance your understanding and skills."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "Currently, your leadership skills are at a foundational level, which means you're likely just beginning to understand what makes effective leadership.", "competency_name": "Leadership", "improvement_areas": "To meet the required application level, consider seeking opportunities to lead small projects or teams. Participating in leadership workshops or finding a mentor to guide you can also accelerate your development."}, {"user_strengths": "You have a good understanding of self-organization techniques, which is crucial for personal and professional growth.", "competency_name": "Self-Organization", "improvement_areas": "To advance to an application level, start implementing more advanced organization tools and strategies in your daily work. Regularly setting and reviewing personal goals could also be beneficial."}, {"user_strengths": "You have mastered communication skills, exceeding the necessary level for your role.", "competency_name": "Communication", "improvement_areas": "Although you have exceeded the required level, continuous improvement can involve refining specific communication techniques or exploring new communication technologies to stay ahead in your field."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "", "competency_name": "Requirements Definition", "improvement_areas": "This competency is foundational to the systems engineering process. To improve, consider enrolling in courses or workshops that focus on eliciting, documenting, and managing requirements. Engage in projects to actively practice defining requirements, and seek feedback from experienced colleagues."}, {"user_strengths": "Your understanding of system architecture basics is a positive starting point.", "competency_name": "System Architecting", "improvement_areas": "To deepen your understanding, study advanced concepts and participate in hands-on projects that involve complex system designs. Collaborate with experienced architects and participate in architecture review meetings to gain insights."}, {"user_strengths": "Your ability to apply knowledge in integration, verification, and validation demonstrates a practical understanding, aligning with the required level.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Continue to build on this strength by staying updated on new tools and methodologies, and consider leading a team or initiative in this area to refine your skills further."}, {"user_strengths": "You meet the required level for this competency, indicating a solid understanding of system operation and support.", "competency_name": "Operation and Support", "improvement_areas": "To enhance your expertise, seek opportunities to work on diverse projects across different phases of system lifecycle. Share your knowledge through mentoring or creating training materials."}, {"user_strengths": "", "competency_name": "Agile Methods", "improvement_areas": "Since agile methodologies are increasingly important in systems engineering, start with foundational agile training courses. Join agile project teams and learn from experienced practitioners to build practical skills."}], "competency_area": "Technical"}]	2025-01-16 15:00:29.617309
57	77	1	[{"feedbacks": [{"user_strengths": "You have a good understanding of Systems Thinking, which is a crucial skill in systems engineering.", "competency_name": "Systems Thinking", "improvement_areas": "To reach the required application level, consider participating in project simulations or real-world scenarios where you can apply systems thinking to solve complex problems. Engaging in interdisciplinary teamwork can also enhance your practical application of this skill."}, {"user_strengths": "You excel in Lifecycle Consideration, mastering this competency beyond the required level.", "competency_name": "Lifecycle Consideration", "improvement_areas": "You could leverage your expertise by mentoring others or leading workshops. This will not only affirm your mastery but also contribute to your team's overall competency."}, {"user_strengths": "Currently, this is an area that needs significant improvement.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Start by familiarizing yourself with the basics of customer and value orientation. Attend training sessions, participate in customer engagement activities, and study market analysis techniques. Understanding customer needs and value creation is vital for any systems engineer."}, {"user_strengths": "You have a solid understanding of Systems Modeling and Analysis.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To advance to the application level, engage more actively in modeling projects. Utilize software tools for systems modeling, and seek feedback from experienced colleagues to refine your techniques and understanding."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have demonstrated mastery in Decision Management, surpassing the required application level, which shows strong decision-making skills in complex scenarios.", "competency_name": "Decision Management", "improvement_areas": "Since you already exceed the required level, focus on maintaining and sharing your expertise with peers, potentially through mentoring or leading workshops."}, {"user_strengths": "You are familiar with the basic concepts of Project Management.", "competency_name": "Project Management", "improvement_areas": "To meet the required understanding level, you should deepen your knowledge. Consider enrolling in a project management course or seeking practical experience through participation in larger projects."}, {"user_strengths": "You are at the beginning of your journey in Information Management.", "competency_name": "Information Management", "improvement_areas": "To reach the required understanding level, start with foundational courses or training. Engage actively in projects where information management is critical to accelerate your learning."}, {"user_strengths": "You're already applying the principles of Configuration Management.", "competency_name": "Configuration Management", "improvement_areas": "To elevate your competency to the understanding level, seek deeper insights into the theoretical aspects and best practices. Participate in advanced workshops or seek mentorship within your organization."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You are demonstrating a strong grasp on leadership skills, having achieved a level of proficiency that surpasses the required level for this competency.", "competency_name": "Leadership", "improvement_areas": "Since you have already mastered this skill, consider sharing your knowledge with peers or taking on more leadership roles to continue honing and showcasing your abilities."}, {"user_strengths": "Currently, this is an area where you have room for significant improvement.", "competency_name": "Self-Organization", "improvement_areas": "To elevate your competency in self-organization to the required level, start by setting specific daily or weekly goals. Use tools like calendars, task lists, or apps designed to enhance productivity. Also, consider attending workshops or reading materials on time management and organizational skills."}, {"user_strengths": "Your competency in communication is outstanding, exceeding the necessary level required for this area.", "competency_name": "Communication", "improvement_areas": "Continue practicing and refining your communication skills. Engage in diverse communication settings and perhaps mentor others who are looking to improve in this area."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "Currently, you are at the beginning stage in understanding Requirements Definition.", "competency_name": "Requirements Definition", "improvement_areas": "You need to advance your skills from basic awareness to being able to apply this knowledge in practical scenarios. To improve, consider engaging in workshops or training that focus on practical applications of defining system requirements. Additionally, working closely with a mentor in this area could provide valuable insights and hands-on experience."}, {"user_strengths": "You have a good understanding of System Architecting, meeting the required competency level.", "competency_name": "System Architecting", "improvement_areas": "To further enhance your skills, you might consider sharing your knowledge through peer discussions or participating in advanced projects that challenge your current understanding. Continuous exposure to complex system design will enrich your expertise."}, {"user_strengths": "You have a foundational knowledge of Integration, Verification, and Validation.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "To meet the required competency level of understanding these processes deeply, you should aim to deepen your knowledge. Participating in related projects, attending specialized workshops, or undergoing formal training could be beneficial. Engaging with case studies or simulation exercises can also help solidify your understanding."}, {"user_strengths": "You excel in Operation and Support, surpassing the required competency level.", "competency_name": "Operation and Support", "improvement_areas": "You could leverage your advanced skills by leading training sessions or creating guideline documents for peers. This will not only reinforce your expertise but also assist others in reaching higher competency levels."}, {"user_strengths": "Currently, you are at the beginning stage in understanding Agile Methods.", "competency_name": "Agile Methods", "improvement_areas": "You need to improve from having no knowledge to being able to apply Agile Methods in your projects. Engaging in specific Agile training programs, joining Agile project teams for hands-on experience, or finding a mentor skilled in Agile methodologies are effective ways to boost your competency."}], "competency_area": "Technical"}]	2025-02-04 19:07:10.305626
58	78	1	[{"feedbacks": [{"user_strengths": "You are applying systems thinking effectively in practical scenarios, which is beyond the basic understanding required.", "competency_name": "Systems Thinking", "improvement_areas": "Continue to apply this competency in various scenarios to deepen your practical understanding and maintain your advanced level."}, {"user_strengths": "You have mastered lifecycle considerations, significantly surpassing the required understanding level.", "competency_name": "Lifecycle Consideration", "improvement_areas": "You could share your expertise with peers or consider mentoring others to enhance team capabilities."}, {"user_strengths": "Currently, this is an area needing attention as your understanding is at the beginning level.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Start by familiarizing yourself with basic concepts of customer and value orientation. Engage with relevant materials or short courses to build a foundational understanding."}, {"user_strengths": "Your understanding of systems modeling and analysis meets the required level.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To further enhance your skills, consider applying these concepts in more complex and varied situations."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "Your current level in Decision Management meets the required level, indicating a solid understanding and capability to apply decision-making processes effectively.", "competency_name": "Decision Management", "improvement_areas": "Maintain your level of expertise and stay updated with new decision-making tools and methodologies to continuously enhance your efficiency and effectiveness."}, {"user_strengths": "You exceed the required level in Project Management, showcasing your advanced skills in overseeing and directing projects. This is a significant strength, as it demonstrates a high level of proficiency.", "competency_name": "Project Management", "improvement_areas": "Consider leveraging your advanced skills by mentoring others or taking on larger, more complex projects to further capitalize on your expertise."}, {"user_strengths": "Currently, there is a notable gap in Information Management as your understanding does not meet the required level.", "competency_name": "Information Management", "improvement_areas": "Engage in training or courses focused on Information Management. Studying case studies and best practices can also enhance your understanding and application in this area."}, {"user_strengths": "Your recorded level in Configuration Management meets the required foundational understanding.", "competency_name": "Configuration Management", "improvement_areas": "To advance further, consider engaging in more practical applications or deeper studies into Configuration Management theories and tools."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have demonstrated a high proficiency in Leadership, surpassing the required level significantly.", "competency_name": "Leadership", "improvement_areas": "Since you already excel in this area, you could focus on mentoring others to enhance their leadership skills or take on more strategic leadership roles to further utilize your advanced skills."}, {"user_strengths": "You meet the required level for Self-Organization, indicating effective personal management and planning skills.", "competency_name": "Self-Organization", "improvement_areas": "To enhance your skills even further, consider exploring advanced organizational tools and techniques, or perhaps participate in workshops that focus on productivity and efficiency."}, {"user_strengths": "You have a practical application level in Communication, which is above the required understanding level.", "competency_name": "Communication", "improvement_areas": "You could further refine your communication skills by engaging in diverse communication settings, attending advanced communication skills workshops, or seeking feedback from peers to identify areas for subtle improvements."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have a foundational understanding of Requirements Definition.", "competency_name": "Requirements Definition", "improvement_areas": "You need to develop the ability to apply this knowledge in practical scenarios. Consider engaging more deeply with projects that require you to define and manage system requirements. Practical application through real-life projects or simulations can significantly enhance your skills."}, {"user_strengths": "You have mastered System Architecting, which is excellent as this competency is critical for effective systems engineering.", "competency_name": "System Architecting", "improvement_areas": "Since your recorded level is above the required level, you might consider mentoring others or leading workshops to share your expertise and insights."}, {"user_strengths": "You are already performing at a level where you can apply these skills effectively.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Your current competency exceeds the required level. You could explore advanced applications of these skills or take on more complex projects to further challenge your capabilities."}, {"user_strengths": "You have a good understanding of Operation and Support, which is above the basic knowledge required.", "competency_name": "Operation and Support", "improvement_areas": "Given your higher understanding, you might consider exploring deeper aspects of this competency or helping colleagues increase their knowledge."}, {"user_strengths": "You have mastered Agile Methods, demonstrating a significant strength in adapting and managing projects efficiently.", "competency_name": "Agile Methods", "improvement_areas": "Since you exceed the required level, sharing your knowledge through coaching or developing training materials for others could be beneficial."}], "competency_area": "Technical"}]	2025-02-17 23:30:33.365087
59	79	1	[{"feedbacks": [{"user_strengths": "Your understanding of Systems Thinking demonstrates a solid grasp of the principles, which is a strong foundation.", "competency_name": "Systems Thinking", "improvement_areas": "To achieve mastery, focus on applying these principles in varied, complex real-world situations. Consider participating in advanced problem-solving workshops or engaging in cross-functional projects to deepen your practical experience."}, {"user_strengths": "You have a basic awareness of Lifecycle Consideration.", "competency_name": "Lifecycle Consideration", "improvement_areas": "To progress to mastery, it's essential to gain a deeper understanding and hands-on experience. Engage in training programs focused on lifecycle models and their applications in different phases of a system's life. Practical involvement in projects from inception to retirement can significantly enhance your comprehension and skills."}, {"user_strengths": "You are already applying principles of Customer / Value Orientation effectively in your projects.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To elevate this to mastery, work on integrating these principles more consistently across all project stages and stakeholder interactions. Seek feedback from clients and stakeholders to refine your approaches and ensure alignment with customer values throughout the project lifecycle."}, {"user_strengths": "You have mastered Systems Modeling and Analysis, which is commendable.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "Maintain this competency through continuous learning and staying updated with the latest tools and methodologies. Consider mentoring others in this area to further solidify your knowledge and contribute to the team's overall skill enhancement."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have a good understanding of Decision Management concepts and principles, which is a solid foundation.", "competency_name": "Decision Management", "improvement_areas": "To advance to the required level, focus on applying these concepts more extensively in real-world scenarios. Engage in decision-making processes within your projects to gain practical experience and consider seeking mentorship from experienced decision-makers."}, {"user_strengths": "You are already applying Project Management skills effectively in practical situations.", "competency_name": "Project Management", "improvement_areas": "To elevate your skills to the required expert level, consider leading more complex projects and take part in advanced project management training. Learning from experienced project managers and handling more responsibility will deepen your expertise."}, {"user_strengths": "You have mastered Information Management, meeting the highest required competency level.", "competency_name": "Information Management", "improvement_areas": "Maintain this competency by staying updated with the latest tools and practices in Information Management. Consider sharing your knowledge through workshops or mentoring."}, {"user_strengths": "You have a basic understanding of Configuration Management.", "competency_name": "Configuration Management", "improvement_areas": "To reach the required level of expertise, deepen your understanding through advanced courses and practical application. Work closely with experts in Configuration Management to gain hands-on experience and insights."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have a good understanding of leadership principles, which is a solid foundation.", "competency_name": "Leadership", "improvement_areas": "To advance to a mastery level, consider taking on more leadership roles within projects to apply your knowledge practically. Additionally, leadership workshops or mentoring from experienced leaders could enhance your skills."}, {"user_strengths": "You are familiar with the basics of self-organization.", "competency_name": "Self-Organization", "improvement_areas": "To reach a mastery level, focus on implementing advanced time management and prioritization techniques. Tools like Eisenhower Box or Pomodoro Technique can help improve your efficiency. Regular self-reflection on your organizational habits could also prove beneficial."}, {"user_strengths": "You possess a basic understanding of communication skills.", "competency_name": "Communication", "improvement_areas": "To achieve mastery, actively seek opportunities to communicate in varied settings, such as presentations, meetings, and written communications. Engaging in workshops or courses on effective communication and interpersonal skills will also be crucial."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You are meeting the required level in Requirements Definition, demonstrating a thorough understanding and capability in this area.", "competency_name": "Requirements Definition", "improvement_areas": "Since you have mastered this competency, continue to keep your skills sharp by staying updated with latest best practices and emerging trends."}, {"user_strengths": "You have a basic understanding of System Architecting.", "competency_name": "System Architecting", "improvement_areas": "To advance to the required level, consider engaging in more hands-on projects, attending workshops, and seeking mentorship from experienced architects to deepen your skills."}, {"user_strengths": "This area is new to you.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Start by learning the basics through online courses or textbooks. Gradually participate in projects under supervision to gain practical experience and confidence."}, {"user_strengths": "You have a basic understanding of Operation and Support.", "competency_name": "Operation and Support", "improvement_areas": "To reach the required level, practical experience is key. Try to get involved in more operational support projects and consider specialized training or certifications."}, {"user_strengths": "You have a foundational knowledge of Agile Methods.", "competency_name": "Agile Methods", "improvement_areas": "To improve, actively participate in Agile projects, consider Agile certification, and learn from seasoned Agile practitioners to enhance your understanding and application of Agile principles."}], "competency_area": "Technical"}]	2025-02-17 23:34:55.436512
60	80	1	[{"feedbacks": [{"user_strengths": "You are performing well in Systems Thinking, meeting the required level of competency. This indicates a solid understanding and application of systems thinking principles in your work.", "competency_name": "Systems Thinking", "improvement_areas": "Since you are already at the required level, focus on deepening your knowledge and staying updated with the latest trends and methodologies in systems thinking to maintain your competency."}, {"user_strengths": "Currently, there is a significant opportunity for growth in this area.", "competency_name": "Lifecycle Consideration", "improvement_areas": "You need to develop a basic understanding and then apply lifecycle consideration principles in your work. Start by learning the fundamental concepts of system lifecycle stages, including development, operation, and disposal. Engage in training sessions or workshops, and seek guidance from a mentor who has expertise in lifecycle management."}, {"user_strengths": "You have a basic understanding of customer and value orientation.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To meet the required level, you should apply this understanding in practical scenarios. Consider participating in projects that require direct interaction with customers or focus on value delivery. Also, seek feedback from experienced colleagues and participate in customer-oriented training programs to enhance your skills."}, {"user_strengths": "You have a good grasp of systems modeling and analysis.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To reach the required competency level, focus on applying your understanding in real-world projects. Engage in hands-on activities, such as participating in simulation exercises or model-based systems engineering projects. Additionally, consider advanced training or certification in relevant software tools and methodologies."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have a good understanding of Decision Management principles.", "competency_name": "Decision Management", "improvement_areas": "To reach the 'application' level, consider engaging in scenario-based exercises or decision-making simulations. Participating in cross-functional team meetings where decision-making processes are critical can also provide practical experience."}, {"user_strengths": "You have a basic knowledge of Project Management.", "competency_name": "Project Management", "improvement_areas": "To enhance your understanding, you might enroll in a project management course or seek opportunities to work under a seasoned project manager. Practical experience, such as leading a small project or a component of a larger project, will also be beneficial."}, {"user_strengths": "You excel in Information Management, surpassing the required competency level.", "competency_name": "Information Management", "improvement_areas": "Maintain your advanced skills by staying updated with the latest trends and technologies in information management. Consider sharing your knowledge through mentoring or conducting workshops."}, {"user_strengths": "You meet the required level of understanding in Configuration Management.", "competency_name": "Configuration Management", "improvement_areas": "To further develop your skills, you could explore advanced topics or certifications in configuration management or participate in more complex projects to apply your knowledge in diverse scenarios."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "Your current level in Leadership demonstrates that you have a strong ability to apply these skills in practical situations, which is commendable.", "competency_name": "Leadership", "improvement_areas": "Given your current level exceeds the required level, continue to hone these skills and consider taking on more leadership roles to refine your expertise further."}, {"user_strengths": "Currently, there's an opportunity for significant improvement in Self-Organization.", "competency_name": "Self-Organization", "improvement_areas": "To meet the required level, consider engaging in time management and organizational training programs. Start by setting small, achievable goals each day to enhance your organizational skills gradually."}, {"user_strengths": "You excel in Communication, as demonstrated by mastering this skill beyond the required level.", "competency_name": "Communication", "improvement_areas": "Maintain your high competency by staying engaged in environments where communication is critical, and consider mentoring others to develop their skills."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You excel in defining system requirements, showcasing a high level of mastery that surpasses the needed application level. Your capability in this area ensures the development of clear, accurate, and comprehensive requirements.", "competency_name": "Requirements Definition", "improvement_areas": "As you are already performing above the required level, you could leverage this strength by mentoring others or leading workshops to enhance your team's overall skill in requirements definition."}, {"user_strengths": "Your understanding of system architecting aligns with the required level, indicating that you have a solid grasp of the fundamental principles needed for this aspect of systems engineering.", "competency_name": "System Architecting", "improvement_areas": "To further enhance your skills, consider engaging in projects that require more complex architectural solutions or seek advanced training to deepen your understanding and potentially move towards a mastery level."}, {"user_strengths": "You have mastered the processes of integration, verification, and validation, which is above the required level of understanding. This indicates a strong ability to ensure that systems meet their requirements and perform as expected.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Since you exceed the necessary competency level, consider taking on a leadership role in these areas or developing guidelines and best practices to help elevate your team's capabilities."}, {"user_strengths": "You have a good understanding of operation and support, which is crucial for the effective management and maintenance of systems.", "competency_name": "Operation and Support", "improvement_areas": "To meet the required application level, focus on gaining hands-on experience in managing live system operations or supporting existing systems. Engaging in training sessions or shadowing experienced colleagues could also be beneficial."}, {"user_strengths": "Your mastery of agile methods exceeds the required application level, indicating a strong proficiency in implementing agile practices effectively within projects.", "competency_name": "Agile Methods", "improvement_areas": "You could take advantage of your advanced skills by coaching others in agile methodologies or leading agile transformation initiatives within your organization."}], "competency_area": "Technical"}]	2025-02-17 23:36:47.051208
61	81	1	[{"feedbacks": [{"user_strengths": "You have a good understanding of systems thinking principles.", "competency_name": "Systems Thinking", "improvement_areas": "To advance to an 'anwenden' level, focus on applying these principles in practical scenarios. Engage in real-world systems engineering projects to enhance your application skills."}, {"user_strengths": "You meet the required competency level for considering the entire lifecycle of systems.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Continue to deepen your knowledge and stay updated with best practices to maintain your competency."}, {"user_strengths": "You excel in aligning engineering processes with customer values and needs, surpassing the required level.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Leverage your expertise to mentor others or lead projects that emphasize customer value."}, {"user_strengths": "You understand the fundamental concepts of systems modeling and analysis.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To reach the 'anwenden' level, work on applying these concepts in diverse scenarios. Participate in workshops or simulation exercises to build practical skills."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "Your expertise in Decision Management is commendable, as your recorded level is significantly higher than the required level. This demonstrates a strong capability in making effective decisions which can greatly benefit project outcomes.", "competency_name": "Decision Management", "improvement_areas": "Since you have already mastered this competency, consider mentoring others in your team or organization to enhance their decision-making skills."}, {"user_strengths": "You are meeting the required level in Project Management, which indicates that you have a solid understanding and ability to effectively manage projects.", "competency_name": "Project Management", "improvement_areas": "To further enhance your skills, consider exploring advanced project management techniques and tools. Engaging in more complex projects or taking on more leadership roles in project settings could provide valuable hands-on experience."}, {"user_strengths": "You have surpassed the required level in Information Management, showcasing your strong capabilities in managing information effectively within projects.", "competency_name": "Information Management", "improvement_areas": "Leverage your advanced knowledge to lead initiatives aimed at improving information systems and processes within your organization. Sharing your insights through workshops or training sessions can also be beneficial."}, {"user_strengths": "Currently, there is a significant gap in Configuration Management as it is not yet a developed skill.", "competency_name": "Configuration Management", "improvement_areas": "To reach the required level, start by familiarizing yourself with the basic concepts of Configuration Management. Online courses, workshops, or seeking mentorship from experienced colleagues can be effective ways to build this competency. Engaging in projects that allow you to apply these concepts practically will also aid in your development."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You are currently meeting the required level in leadership skills, demonstrating effective application of your abilities in this area.", "competency_name": "Leadership", "improvement_areas": "Continue to refine and expand your leadership techniques by seeking new responsibilities, leading new projects, and soliciting feedback from peers and supervisors to further enhance your skills."}, {"user_strengths": "Your understanding of self-organization principles is a solid foundation.", "competency_name": "Self-Organization", "improvement_areas": "To reach the required application level, start implementing these principles in daily work tasks. Use tools like planners or digital apps to track and manage your tasks more effectively. Setting specific, measurable goals for your organizational skills can also provide clear benchmarks for improvement."}, {"user_strengths": "Your communication skills are at the level required, indicating proficient application in your interactions.", "competency_name": "Communication", "improvement_areas": "To continue excelling in this area, engage in more diverse communication scenarios. Consider joining a workshop or a public speaking club to refine various aspects of communication such as non-verbal cues, persuasive communication, and active listening."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have achieved the required level of understanding in Requirements Definition, which is crucial in ensuring that system requirements meet customer and stakeholder needs effectively.", "competency_name": "Requirements Definition", "improvement_areas": "Since you are at the required level, focus on maintaining and gradually enhancing your skills through ongoing practice and exposure to diverse projects."}, {"user_strengths": "You excel in System Architecting, surpassing the required level. Your advanced skills enable you to design and organize complex systems effectively.", "competency_name": "System Architecting", "improvement_areas": "Leverage your expertise in this area to mentor others and consider exploring advanced topics or certifications in system architecting to continue your professional growth."}, {"user_strengths": "You have a practical application level in Integration, Verification, and Validation, which is fundamental in ensuring systems function as intended.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "To reach the required understanding level, consider engaging in more in-depth studies or training, such as workshops or formal courses that focus on the theoretical aspects of these processes."}, {"user_strengths": "Your practical application skills in Operation and Support demonstrate your ability to effectively manage and maintain system operations.", "competency_name": "Operation and Support", "improvement_areas": "To deepen your understanding, consider studying case studies, best practices, and theoretical models to better grasp the underlying principles and strategies used in this competency."}, {"user_strengths": "You have a good understanding of Agile Methods, which are essential in managing projects in flexible and efficient manners.", "competency_name": "Agile Methods", "improvement_areas": "To elevate your skills to the application level, actively participate in Agile projects, attend Agile training programs, and consider obtaining certifications like Certified ScrumMaster (CSM) or SAFe Agilist to enhance your practical skills in applying Agile methodologies."}], "competency_area": "Technical"}]	2025-02-24 18:28:40.014755
62	82	1	[{"feedbacks": [{"user_strengths": "You have demonstrated a good ability to apply systems thinking in practice, which is a strong foundation.", "competency_name": "Systems Thinking", "improvement_areas": "To master this skill, focus on integrating complex system interactions and feedback mechanisms in your decision-making processes. Consider seeking out projects that challenge your ability to foresee and manage system-wide impacts, and perhaps engage in advanced training or workshops that emphasize holistic problem-solving strategies."}, {"user_strengths": "Currently, this area does not have a required level, indicating flexibility or less immediate need for this skill in your current role.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Although not required, understanding lifecycle considerations can enhance your ability to predict system behaviors over time. You might consider familiarizing yourself with basic lifecycle models and their impact on system design and maintenance as part of your broader systems engineering knowledge."}, {"user_strengths": "You have a good understanding of aligning system designs with customer values and needs.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To reach a mastery level, you should work on refining your ability to anticipate and integrate customer feedback into all stages of system development. Engage directly with customers to gather insights and employ value-driven management techniques to ensure the final product meets or exceeds customer expectations. Advanced courses in customer relationship management could also be beneficial."}, {"user_strengths": "You meet the current requirements for systems modeling and analysis.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To further enhance your skills, consider exploring more complex models and analytical techniques. Engaging in hands-on projects or simulations can provide practical experience and deepen your understanding of how different models can be applied to solve real-world problems."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have a solid understanding of Decision Management, which is a positive foundation to build upon.", "competency_name": "Decision Management", "improvement_areas": "To reach the required application level, consider practicing decision-making in real-world scenarios. Engage in simulation exercises or decision-making workshops to enhance your skills."}, {"user_strengths": "You are already applying your knowledge in Project Management effectively, which is commendable.", "competency_name": "Project Management", "improvement_areas": "To master this competency, you might focus on advanced project management techniques. Consider obtaining a higher certification like PMP or engaging in complex project management roles to refine your expertise."}, {"user_strengths": "You have a basic knowledge of Information Management, which is a good starting point.", "competency_name": "Information Management", "improvement_areas": "As there is no specific higher level required currently, you can maintain your current knowledge. However, staying updated with the latest information management tools and practices would be beneficial."}, {"user_strengths": "You excel in Configuration Management, showing mastery in this area.", "competency_name": "Configuration Management", "improvement_areas": "Since you have mastered this competency, consider mentoring others or leading initiatives to share your knowledge and best practices within your organization."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have a foundational understanding of leadership principles.", "competency_name": "Leadership", "improvement_areas": "To elevate your leadership skills to the required level, consider engaging in leadership roles within project teams or community groups. Additionally, attending leadership workshops or seminars can provide practical insights and techniques to enhance your ability to lead effectively."}, {"user_strengths": "You have mastered self-organization, which is a vital skill for managing both personal responsibilities and professional projects effectively.", "competency_name": "Self-Organization", "improvement_areas": "Continue refining and adapting your organizational strategies to maintain your high level of competency, and consider mentoring others to help them develop similar skills."}, {"user_strengths": "You are able to apply communication skills effectively in practice.", "competency_name": "Communication", "improvement_areas": "To reach the highest competency level, focus on improving specific areas such as persuasive communication, public speaking, or cross-cultural communication. Participate in advanced communication skills workshops or seek opportunities for public speaking to gain more experience and confidence."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "Since the required level is 'None', you have no explicit gaps to address. This suggests that you may not need this competency in your current role.", "competency_name": "Requirements Definition", "improvement_areas": "While there is no current requirement, gaining a basic understanding of requirements definition could be beneficial for future roles or projects."}, {"user_strengths": "You have a good understanding of system architecting, which is a critical skill in systems engineering. This competency is well-aligned with your role as there is no further requirement specified.", "competency_name": "System Architecting", "improvement_areas": "Continuing to enhance your understanding through practical application or advanced studies could provide even greater value to your projects."}, {"user_strengths": "Your ability to apply knowledge in integration, verification, and validation is impressive and indicates a strong proficiency in ensuring that systems work as intended.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "To further refine your skills, consider additional hands-on projects or specialized training that focuses on complex and varying systems."}, {"user_strengths": "You have a good understanding of operation and support, an essential aspect of ensuring systems perform effectively after deployment.", "competency_name": "Operation and Support", "improvement_areas": "To elevate your proficiency, engaging in operational troubleshooting exercises or simulations could be very beneficial."}, {"user_strengths": "Your familiarity with agile methods is a good starting point.", "competency_name": "Agile Methods", "improvement_areas": "Since the required level is to master these methods, you should consider engaging in advanced agile training programs, participating in agile project teams, or gaining certification to deepen your expertise."}], "competency_area": "Technical"}]	2025-03-01 11:07:02.434383
63	83	1	[{"feedbacks": [{"user_strengths": "You have a foundational understanding of Systems Thinking.", "competency_name": "Systems Thinking", "improvement_areas": "To elevate your competency to the required application level, engage in practical problem-solving scenarios where you can apply systems thinking principles to real-world situations. Participate in workshops or courses that focus on the holistic approach to systems engineering."}, {"user_strengths": "You are at the beginning of your learning journey in Lifecycle Consideration.", "competency_name": "Lifecycle Consideration", "improvement_areas": "To meet the application level, start by familiarizing yourself with the basic concepts of system lifecycles. You could benefit from joining project teams that are at different stages of a system’s lifecycle to gain hands-on experience and insights from seasoned professionals."}, {"user_strengths": "You are at the beginning of your learning journey in understanding Customer / Value Orientation.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To advance to the application level, focus on understanding customer needs and system value delivery. Engage in customer interaction, seek feedback, and participate in projects that require you to directly address customer requirements and expectations."}, {"user_strengths": "You excel in Systems Modeling and Analysis, demonstrating a mastery level.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "Maintain and expand your expertise by mentoring others or leading workshops. Ensure that you stay updated with the latest tools and methodologies to keep your skills sharp and relevant."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have mastered Decision Management, which exceeds the required proficiency level. This indicates a strong capability in making effective decisions, likely contributing positively to project outcomes.", "competency_name": "Decision Management", "improvement_areas": "Since you have already exceeded the required level, focus on maintaining this competency and potentially sharing your expertise with others through mentoring or leading training sessions."}, {"user_strengths": "You have a basic understanding of Project Management.", "competency_name": "Project Management", "improvement_areas": "To move from basic knowledge to a deeper understanding, consider engaging in more structured project management training or workshops. Applying your knowledge in real project scenarios can also help deepen your understanding."}, {"user_strengths": "You have a basic understanding of Information Management.", "competency_name": "Information Management", "improvement_areas": "To progress to a deeper understanding, actively involve yourself in projects that require systematic information management. Participate in relevant seminars or online courses to enhance your knowledge and skills."}, {"user_strengths": "Your starting point is at the initial level.", "competency_name": "Configuration Management", "improvement_areas": "To reach a deeper understanding, it's important to start with foundational courses in configuration management. Practical application through involvement in projects or shadowing experienced colleagues can greatly accelerate your learning."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "Your current level of leadership skills is 'anwenden', which implies a practical application of leadership techniques. This is a strong position, as it shows that you are capable of actively leading teams and projects.", "competency_name": "Leadership", "improvement_areas": "Although your recorded level is quite practical, the required level is 'verstehen', which focuses more on understanding the theories and principles behind leadership. To bridge this gap, you might consider studying leadership theories, attending workshops or seminars focused on different leadership styles and principles, or engaging with a mentor who can provide insights into the theoretical aspects of leading."}, {"user_strengths": "You have mastered self-organization, which is an excellent strength. This level of proficiency indicates that you have developed effective strategies for managing your time and resources, which is crucial for personal and professional success.", "competency_name": "Self-Organization", "improvement_areas": "You have already exceeded the required level for self-organization, so there is no need for improvement in this area. However, continue to refine and adapt your self-organization skills as your responsibilities evolve."}, {"user_strengths": "Your level in communication matches the required level, which means you are effectively applying communication skills in your professional environment.", "competency_name": "Communication", "improvement_areas": "Since you meet the required level, focus on maintaining and gradually enhancing these skills. Consider exploring advanced communication techniques, participating in communication skills workshops, or seeking feedback from peers to continuously improve."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have demonstrated a high level of proficiency in Requirements Definition, mastering this competency beyond the required level.", "competency_name": "Requirements Definition", "improvement_areas": "No improvement needed in this area. You might consider sharing your expertise with peers or exploring advanced topics within this competency."}, {"user_strengths": "You have a solid understanding and application skills in System Architecting, which exceeds the required familiarity.", "competency_name": "System Architecting", "improvement_areas": "No further improvement required. You could continue to apply your skills in practical scenarios to further solidify your knowledge."}, {"user_strengths": "You have demonstrated the capability to apply knowledge in Integration, Verification, and Validation, exceeding the basic understanding that is required.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "No improvement needed. Continue practicing these skills to maintain your competency level."}, {"user_strengths": "Your ability to apply knowledge in Operation and Support goes beyond the basic familiarity required.", "competency_name": "Operation and Support", "improvement_areas": "No further improvement is necessary, but maintaining this skill through continuous application will be beneficial."}, {"user_strengths": "You have a basic understanding of Agile Methods.", "competency_name": "Agile Methods", "improvement_areas": "To meet the required application level, consider engaging more deeply with Agile projects, participating in Agile training sessions or workshops, and seeking mentorship from experienced Agile practitioners to enhance your practical skills."}], "competency_area": "Technical"}]	2025-03-03 13:42:03.562652
64	84	1	[{"feedbacks": [{"user_strengths": "You have a good foundational understanding of Systems Thinking.", "competency_name": "Systems Thinking", "improvement_areas": "To meet the required level, focus on applying these concepts in real-world scenarios or projects to enhance your practical skills."}, {"user_strengths": "You are familiar with the basic concepts of Lifecycle Consideration.", "competency_name": "Lifecycle Consideration", "improvement_areas": "To progress, deepen your understanding by exploring more detailed aspects and their applications in different stages of a system's life."}, {"user_strengths": "You have a solid understanding of Customer / Value Orientation.", "competency_name": "Customer / Value Orientation", "improvement_areas": "Next, aim to apply these principles consistently in your projects to align better with customer needs and add value effectively."}, {"user_strengths": "You excel in applying Systems Modeling and Analysis techniques.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "You could focus on understanding the underlying theories and principles even more deeply to enhance your strategic use of these techniques."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You are currently applying practical knowledge in Decision Management which is above the required understanding level.", "competency_name": "Decision Management", "improvement_areas": "Continue to apply your skills in real-world scenarios to further solidify your understanding and practical capabilities."}, {"user_strengths": "You meet the required competency level for Project Management as you are applying the knowledge effectively.", "competency_name": "Project Management", "improvement_areas": "Maintain your current level of competency by staying updated with the latest project management techniques and tools."}, {"user_strengths": "Currently, there is a significant opportunity for growth in Information Management.", "competency_name": "Information Management", "improvement_areas": "Begin by understanding the basic concepts and theories in Information Management. Engage in training or courses to build a foundational knowledge."}, {"user_strengths": "You meet the required competency level for Configuration Management.", "competency_name": "Configuration Management", "improvement_areas": "To enhance your knowledge, consider exploring advanced aspects of Configuration Management or related case studies to deepen your understanding."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "Currently, there is a foundational level of knowledge in leadership, indicating an initial understanding or exposure.", "competency_name": "Leadership", "improvement_areas": "There is a significant gap in the application of leadership skills. To elevate your competency, consider engaging in leadership workshops or seminars. Seek opportunities for leadership roles within team projects to gain practical experience. Additionally, learning from a mentor who is recognized for strong leadership could provide valuable insights and guidance."}, {"user_strengths": "You have mastered self-organization, which means you effectively manage your tasks and responsibilities.", "competency_name": "Self-Organization", "improvement_areas": "Although you have mastered this competency, maintaining this skill is crucial. Continue utilizing organizational tools and techniques to ensure you stay at the forefront of effective self-management. Also, consider sharing your strategies with peers, which can reinforce your own skills and assist others in their organizational efforts."}, {"user_strengths": "You meet the required level for communication, demonstrating your ability to effectively convey information and interact with others.", "competency_name": "Communication", "improvement_areas": "To further refine your communication skills, engage in advanced communication training programs or workshops. Practice diverse forms of communication, such as public speaking, writing, and digital communication. Seeking feedback from colleagues and mentors will also help you identify areas for improvement and development."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have a good understanding of Requirements Definition, which is crucial for ensuring that systems meet user needs and specifications.", "competency_name": "Requirements Definition", "improvement_areas": "To elevate your skills to the 'applying' level, consider participating in workshops that focus on practical applications of requirement gathering and management tools. Engage in real-world projects where you can practice translating customer needs into detailed requirements."}, {"user_strengths": "You have basic knowledge of System Architecting.", "competency_name": "System Architecting", "improvement_areas": "To progress to the 'application' level, it's important to engage in hands-on design and architecture tasks. Seek opportunities to work alongside experienced architects and participate in projects that allow you to design system components from the ground up."}, {"user_strengths": "Your understanding is well-aligned with the required level for Integration, Verification, and Validation.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "To enhance your proficiency, focus on gaining more practical experience through simulations and real-system testing. This will deepen your understanding and ability to effectively integrate and validate systems."}, {"user_strengths": "Currently, your familiarity with Operation and Support is limited.", "competency_name": "Operation and Support", "improvement_areas": "To reach the needed understanding level, start with foundational training in system operation and lifecycle management. Engage with support teams and participate in maintenance activities to gain insights into real-world challenges and solutions."}, {"user_strengths": "You have a basic grasp of Agile Methods.", "competency_name": "Agile Methods", "improvement_areas": "To enhance your ability to apply Agile Methods, consider joining Agile project teams or undertaking specific Agile training courses. Practical application through projects will help solidify your understanding and improve your agile management skills."}], "competency_area": "Technical"}]	2025-03-05 15:36:18.362195
65	85	1	[{"feedbacks": [{"user_strengths": "You have a solid foundational understanding of systems thinking, which allows you to appreciate complex interrelationships in systems.", "competency_name": "Systems Thinking", "improvement_areas": "To advance your competency to the required level, consider engaging in practical exercises that apply systems thinking principles to real-world scenarios. Participating in workshops or online courses can also bolster your skills in this area."}, {"user_strengths": "You have demonstrated the ability to apply lifecycle considerations in your work, ensuring that all phases of a system's life are addressed appropriately.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Continue to build on this competency by seeking opportunities to lead projects that involve lifecycle management. Look for case studies or simulations that challenge you to think more critically about lifecycle impacts."}, {"user_strengths": "You excel in customer and value orientation, effectively understanding and meeting stakeholder needs, which is a key strength in systems engineering.", "competency_name": "Customer / Value Orientation", "improvement_areas": "While you are already performing well here, consider mentoring others in this area to deepen your understanding. This will not only reinforce your knowledge but also enhance your leadership skills."}, {"user_strengths": "You possess a good theoretical understanding of systems modeling and analysis, which is an important aspect of systems engineering.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To meet the required level, engage in hands-on practice with modeling tools and methodologies. Taking on projects that require you to create and analyze models will significantly enhance your practical skills."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "Your current level indicates a foundational understanding of decision management concepts. This is a good starting point for building your skills in this area.", "competency_name": "Decision Management", "improvement_areas": "To improve in decision management, consider seeking training opportunities that focus on decision-making frameworks and methodologies. Engaging in case studies or simulations can also help you apply theoretical knowledge in practical scenarios."}, {"user_strengths": "You demonstrate a strong grasp of project management principles and practices. Your ability to manage projects effectively is a significant asset.", "competency_name": "Project Management", "improvement_areas": "Since the required level is understanding, you might benefit from reviewing theoretical concepts and best practices in project management. Consider participating in workshops or obtaining certifications to deepen your knowledge further."}, {"user_strengths": "Your current understanding of information management matches the required level, indicating that you are well-equipped to handle information-related tasks effectively.", "competency_name": "Information Management", "improvement_areas": "To further enhance your skills, explore advanced topics in information management, such as data analytics or information lifecycle management. Engaging with industry-specific information management practices could also provide additional insights."}, {"user_strengths": "Your proficiency in configuration management is commendable, showcasing your ability to handle complex configurations and systems effectively.", "competency_name": "Configuration Management", "improvement_areas": "Since the required level is understanding, consider focusing on refining your skills related to the underlying principles and theories of configuration management. Participating in training sessions or mentorship programs can provide valuable insights and help you bridge any gaps."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have a foundational understanding of leadership concepts, which shows your willingness to engage with this important competency.", "competency_name": "Leadership", "improvement_areas": "To advance your leadership skills, consider seeking out leadership training programs or workshops. Engaging in team projects where you can take on a leadership role will provide practical experience and help you develop a deeper understanding of leading teams effectively."}, {"user_strengths": "You have demonstrated a good understanding of self-organization principles, which is essential for managing your time and tasks effectively.", "competency_name": "Self-Organization", "improvement_areas": "To elevate your self-organization skills further, practice applying these principles in real-life scenarios. Consider using tools like planners or digital apps that help in task management. Setting personal goals and reviewing your progress regularly can also enhance your ability to apply self-organization techniques."}, {"user_strengths": "It appears there is a recognition of the importance of communication, but further development is needed in this area.", "competency_name": "Communication", "improvement_areas": "To improve your communication skills, consider joining public speaking clubs like Toastmasters or engaging in workshops focused on effective communication. Practicing active listening and seeking feedback on your communication style from peers can also be beneficial. Aim to participate in group discussions or presentations to gain more experience."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have demonstrated the ability to effectively apply requirements definition processes, which aligns perfectly with the expected competency level. This is a crucial skill for ensuring project success.", "competency_name": "Requirements Definition", "improvement_areas": "Continue to refine your skills by actively participating in requirements gathering sessions and seeking feedback from stakeholders to deepen your understanding."}, {"user_strengths": "You have a foundational understanding of system architecting concepts, but there is room for improvement to reach a deeper level of comprehension. This is a vital area for developing robust systems.", "competency_name": "System Architecting", "improvement_areas": "Consider enrolling in advanced courses or workshops that focus on system architecture principles. Additionally, collaborating with experienced architects on projects can provide valuable insights."}, {"user_strengths": "You possess strong skills in integration, verification, and validation, surpassing the expected level. This expertise is essential for ensuring system reliability and performance.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "To further enhance your capabilities, explore advanced techniques and frameworks used in verification and validation, and consider leading small projects to share your knowledge with others."}, {"user_strengths": "Currently, there is no recorded knowledge in operation and support, indicating an opportunity for growth in this area.", "competency_name": "Operation and Support", "improvement_areas": "Start with foundational training or online courses that cover operational support frameworks. Engaging in hands-on experiences, such as shadowing colleagues in operational roles, can also be beneficial."}, {"user_strengths": "Your skills in applying Agile methods are well-aligned with the requirements, showcasing your adaptability and understanding of modern project management techniques.", "competency_name": "Agile Methods", "improvement_areas": "To build on this strength, consider pursuing Agile certifications or participating in Agile project environments to further enhance your expertise and leadership in Agile practices."}], "competency_area": "Technical"}]	2025-03-06 09:41:44.21634
66	86	1	[{"feedbacks": [{"user_strengths": "You have demonstrated the ability to apply systems thinking effectively, indicating a solid understanding of how different components of a system interact with each other.", "competency_name": "Systems Thinking", "improvement_areas": "To further enhance your skills in systems thinking, consider engaging in projects that require a holistic view of systems. Participating in workshops or training sessions focused on systems dynamics can deepen your understanding and application of this competency."}, {"user_strengths": "You have mastered the lifecycle consideration aspect, showcasing your ability to understand and manage the various stages of a system's life cycle.", "competency_name": "Lifecycle Consideration", "improvement_areas": "Leverage your mastery by mentoring others who are less experienced in this area. Additionally, pursuing advanced certifications related to lifecycle management can help you stay updated with best practices and new methodologies."}, {"user_strengths": "You currently have a gap in this area, indicating that there's an opportunity for growth in understanding customer needs and value delivery.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To improve, consider attending customer experience workshops or training focused on value proposition development. Engaging directly with customers or stakeholders to gather feedback can also provide practical insights into their needs, enhancing your orientation toward customer value."}, {"user_strengths": "You have a solid understanding of systems modeling and analysis, which is a critical skill in systems engineering.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To advance this competency further, practice by working on real-world projects that require modeling and analysis. Online courses or certifications in specific modeling tools and techniques can also provide you with more in-depth knowledge and hands-on experience."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You are beginning to engage with decision management concepts, which is a crucial starting point for your development in this area.", "competency_name": "Decision Management", "improvement_areas": "To build your competency, consider seeking resources or training that focus on decision-making frameworks and techniques. Participating in workshops or team discussions where decisions are made can also provide practical experience."}, {"user_strengths": "You have a solid understanding of project management principles, and your ability to apply them in practice is commendable.", "competency_name": "Project Management", "improvement_areas": "To further enhance your skills, you could pursue a certification in project management methodologies (like PMP or Agile) or take on more complex projects that challenge your current abilities."}, {"user_strengths": "You have a foundational knowledge of information management, which is important for organizing and utilizing data effectively.", "competency_name": "Information Management", "improvement_areas": "To improve, consider engaging in training focused on information management systems or tools. Practical application through real-world projects can also help to solidify your understanding."}, {"user_strengths": "You have demonstrated a high level of competency in configuration management, showcasing your ability to manage project components effectively.", "competency_name": "Configuration Management", "improvement_areas": "To maintain and further enhance your skills, consider exploring advanced topics in configuration management or mentoring others in this area, which can reinforce your knowledge."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "Currently, there are no specific required competencies for leadership, which offers a great opportunity to explore this area without pressure. It's a chance to develop foundational leadership skills at your own pace.", "competency_name": "Leadership", "improvement_areas": "Consider taking initiative in group settings or volunteer for leadership roles in small projects. Reading books on leadership or attending workshops can also provide valuable insights and tools."}, {"user_strengths": "You have a solid grasp of self-organization, which is essential for managing tasks and responsibilities effectively. This skill will serve you well in both personal and professional contexts.", "competency_name": "Self-Organization", "improvement_areas": "To enhance your self-organization skills, try implementing time management techniques such as the Pomodoro Technique or using productivity tools like calendars and task management apps. Setting specific, achievable goals can also help improve your organization further."}, {"user_strengths": "Your communication skills are strong, indicating that you can convey ideas effectively and engage with others in both verbal and written forms. This is a vital asset in any environment.", "competency_name": "Communication", "improvement_areas": "To further refine your communication skills, seek feedback from peers on your communication style. Engaging in public speaking or joining groups like Toastmasters can help enhance your confidence and ability to communicate in various situations."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You are currently at the introductory level in Requirements Definition, which allows for a fresh perspective as you begin to learn about this critical aspect of systems engineering.", "competency_name": "Requirements Definition", "improvement_areas": "To improve in this area, consider taking foundational courses on requirements engineering. Engaging in workshops or collaborating with experienced colleagues on real projects can also provide you with practical insights."}, {"user_strengths": "You have demonstrated a solid understanding of System Architecting, allowing you to approach system design with a good grasp of architectural principles.", "competency_name": "System Architecting", "improvement_areas": "To enhance your skills further, consider participating in advanced training sessions or seeking mentorship from a seasoned architect. Engaging in complex projects that require architectural design can also strengthen your capabilities."}, {"user_strengths": "You possess a strong command of Integration, Verification, and Validation, which is crucial for ensuring system reliability and performance.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "To maintain and further enhance your expertise, consider staying updated with the latest methodologies and tools in this area. Participating in relevant certification programs can also deepen your knowledge."}, {"user_strengths": "Currently, your knowledge in Operation and Support is at the introductory level, which provides a chance to delve into this essential area as you progress in your career.", "competency_name": "Operation and Support", "improvement_areas": "To advance, focus on gaining practical experience through internships or projects that involve operational support. Additionally, pursuing training in system maintenance and user support can build your confidence and understanding."}, {"user_strengths": "You have a good understanding of Agile Methods, which is beneficial as it aligns well with modern systems engineering practices.", "competency_name": "Agile Methods", "improvement_areas": "To build on your current understanding, consider getting involved in Agile projects or pursuing certifications in Agile methodologies. Engaging in community discussions or forums can also enhance your practical knowledge."}], "competency_area": "Technical"}]	2025-03-06 10:26:54.501841
67	87	1	[{"feedbacks": [{"user_strengths": "You have demonstrated a solid application of systems thinking principles, which indicates a good understanding of how various components interact within a system.", "competency_name": "Systems Thinking", "improvement_areas": "To progress toward mastery, consider engaging in more complex system projects or case studies that challenge your current understanding. Participating in workshops or online courses focused on advanced systems thinking can also provide valuable insights."}, {"user_strengths": "Currently, you are starting from a base level of understanding, which provides a clean slate for growth in this area.", "competency_name": "Lifecycle Consideration", "improvement_areas": "To reach mastery, I recommend enrolling in training programs that cover system lifecycle management. Hands-on experience in project management or product development, where you can observe and participate in lifecycle considerations, will be highly beneficial."}, {"user_strengths": "You possess a foundational understanding of customer and value orientation, which is essential for systems engineering.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To enhance your competency to the required level, seek opportunities to engage directly with customers or stakeholders to better understand their needs. Courses on customer relationship management or value-based design can further solidify your skills."}, {"user_strengths": "Your current understanding of systems modeling and analysis indicates a good grasp of the concepts and some practical application.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To achieve mastery, consider working on real-world projects that require complex modeling and analysis. Utilizing software tools that are standard in the industry for systems modeling, along with online tutorials or advanced courses, will also help deepen your expertise."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have demonstrated a good ability to apply decision management principles in practical contexts, showing a solid understanding of the decision-making process.", "competency_name": "Decision Management", "improvement_areas": "To progress to a mastery level, consider engaging in advanced decision-making training or workshops that focus on complex scenarios. Additionally, seek opportunities to participate in larger-scale decision-making processes within your organization, which will enhance your skills through practical experience."}, {"user_strengths": "You have a foundational understanding of project management principles, which is commendable and provides a good base for further development.", "competency_name": "Project Management", "improvement_areas": "To enhance your project management skills, consider enrolling in a formal project management course or certification program. Additionally, seek opportunities to lead small projects or assist in project management activities to gain practical experience."}, {"user_strengths": "You have achieved a mastery level in information management, indicating a strong capability to handle, analyze, and leverage information effectively.", "competency_name": "Information Management", "improvement_areas": "Continue to build on your expertise by staying updated with the latest trends and tools in information management. Consider sharing your knowledge with peers or mentoring others, as teaching can deepen your own understanding."}, {"user_strengths": "You have a solid understanding of configuration management principles, which is a strong foundation for further development.", "competency_name": "Configuration Management", "improvement_areas": "To reach a mastery level, pursue advanced training in configuration management methodologies and tools. Engaging in hands-on practice, such as participating in configuration management tasks on projects, will also help solidify your skills."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have demonstrated a strong capability in leadership, showing that you have mastered this competency. Your ability to guide and inspire others is a significant asset in your professional environment.", "competency_name": "Leadership", "improvement_areas": "Continue leveraging your leadership skills by taking on more complex projects or mentoring others. Consider seeking leadership roles in team initiatives or volunteer to lead workshops to further hone your skills."}, {"user_strengths": "Currently, this area has been identified as a gap, indicating that you have not yet developed the necessary skills in self-organization.", "competency_name": "Self-Organization", "improvement_areas": "To improve in self-organization, begin by setting clear, achievable goals and breaking tasks into manageable steps. You may also benefit from time management workshops or using organizational tools (like planners or digital apps) to track your progress and prioritize tasks."}, {"user_strengths": "You are applying communication skills effectively, which is commendable. This shows that you have a good grasp of expressing ideas and collaborating with others.", "competency_name": "Communication", "improvement_areas": "To reach a mastery level in communication, work on refining your skills by seeking feedback on your interactions and presentations. Participating in public speaking groups or engaging in writing workshops can also enhance your communication capabilities."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You are eager to learn and develop in the area of requirements definition, which is crucial for systems engineering.", "competency_name": "Requirements Definition", "improvement_areas": "To improve your competency in requirements definition, consider enrolling in a workshop or online course focused on this topic. Hands-on exercises and real-world examples can significantly enhance your understanding. Additionally, seeking mentorship from a more experienced colleague can provide valuable insights."}, {"user_strengths": "You have a solid understanding of system architecting concepts and can apply them effectively in your work.", "competency_name": "System Architecting", "improvement_areas": "To advance from applying to mastering in system architecting, consider pursuing advanced training or certifications. Engaging in complex projects where you can lead the architectural design will also help deepen your expertise. Regularly reviewing case studies of successful architectures can provide inspiration and learning opportunities."}, {"user_strengths": "You possess a foundational understanding of integration, verification, and validation principles, which is essential for ensuring system quality.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "To enhance your skills in this area, you could benefit from practical experience in integration and testing activities. Participating in cross-functional teams or projects will provide exposure to these processes. Additionally, seeking out relevant training sessions can help bridge any gaps in your knowledge."}, {"user_strengths": "You have a good foundational knowledge of operation and support, which aligns with the required competency level.", "competency_name": "Operation and Support", "improvement_areas": "Continue to build on your knowledge by engaging in operational roles or tasks that allow you to practice your skills. Consider job shadowing opportunities or asking for additional responsibilities in your current role that focus on operational support."}, {"user_strengths": "You have demonstrated mastery in agile methods, showcasing your ability to effectively implement agile practices in your projects.", "competency_name": "Agile Methods", "improvement_areas": "To maintain your mastery in agile methods, stay updated with the latest trends and practices in the agile community. Participating in agile conferences, webinars, or reading industry-related literature can help you continue to grow and adapt within this competency."}], "competency_area": "Technical"}]	2025-03-06 14:22:10.878027
68	88	1	[{"feedbacks": [{"user_strengths": "You have demonstrated a solid proficiency in Systems Thinking, consistently applying this knowledge effectively in your work. This ability to see the big picture and understand interdependencies is a valuable asset.", "competency_name": "Systems Thinking", "improvement_areas": "To further enhance your Systems Thinking skills, consider engaging in more complex systems projects or simulations. Participating in workshops that focus on advanced systems thinking methodologies can also deepen your understanding."}, {"user_strengths": "Your mastery of Lifecycle Consideration is impressive and indicates a strong grasp of the various phases of system development and management.", "competency_name": "Lifecycle Consideration", "improvement_areas": "While you have exceeded expectations here, it's beneficial to continue exploring emerging trends and best practices in lifecycle management. Consider obtaining certifications related to lifecycle processes or joining professional groups that focus on lifecycle management."}, {"user_strengths": "Currently, this area shows a significant gap, as you are not yet familiar with the concepts of Customer / Value Orientation. This indicates an opportunity for growth.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To improve in this area, start by studying customer engagement strategies and value proposition development. Participating in customer-focused projects or seeking mentorship from colleagues experienced in customer orientation will provide practical insights."}, {"user_strengths": "Your understanding of Systems Modeling and Analysis aligns well with the required expectations, indicating a solid foundation in this area.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To build on this foundation, consider taking on more analytical projects that require complex modeling. Engaging with software tools specifically designed for systems modeling and analysis can also enhance your practical skills."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You demonstrate a practical ability to apply decision management techniques in your work, which shows you are capable of making informed choices in various scenarios.", "competency_name": "Decision Management", "improvement_areas": "To progress further, focus on enhancing your understanding of the underlying principles and theories of decision management. Consider enrolling in workshops or courses that cover decision-making frameworks and methodologies, as well as seeking out mentorship from experienced decision-makers."}, {"user_strengths": "Your proficiency in project management is commendable, as you have demonstrated a strong grasp of project execution and overall control of project deliverables.", "competency_name": "Project Management", "improvement_areas": "To align with the required level, aim to refine your skills in applying project management concepts more broadly. You might benefit from participating in project management certification programs, or taking on additional responsibilities in more complex projects to practice your skills in applying project management methodologies."}, {"user_strengths": "You have a solid understanding of information management principles, which allows you to effectively manage and utilize information resources in your work.", "competency_name": "Information Management", "improvement_areas": "Since your current level aligns with the required level, consider deepening your knowledge by exploring advanced topics in information management. This could include data governance, information lifecycle management, or emerging technologies in information systems."}, {"user_strengths": "Your expertise in configuration management is impressive, indicating that you are highly capable of maintaining consistency in product performance and ensuring proper documentation and tracking of system components.", "competency_name": "Configuration Management", "improvement_areas": "Since your level exceeds the required understanding, consider leading initiatives that help others improve their configuration management practices. This could also be an opportunity for you to explore advanced strategies or tools in configuration management to further enhance your skills."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "While you may not have yet acquired the foundational knowledge in leadership, your willingness to learn is a positive sign. Recognizing the importance of leadership in systems engineering is a step in the right direction.", "competency_name": "Leadership", "improvement_areas": "To improve your leadership skills, consider seeking mentorship from established leaders in your field. Participating in leadership workshops or training programs can provide valuable insights and practical experience. Additionally, volunteering for team lead positions in projects can give you hands-on experience."}, {"user_strengths": "You have a solid understanding of self-organization concepts, which shows that you are on the right path to mastering this competency. Your knowledge can serve as a strong foundation for further development.", "competency_name": "Self-Organization", "improvement_areas": "To advance your self-organization skills, try implementing time management techniques, such as the Pomodoro technique or task prioritization methods. Tools like digital planners or project management software can also aid in organizing your tasks more effectively. Consider attending time management workshops to learn new strategies."}, {"user_strengths": "You excel in communication, demonstrating a strong command of this essential skill. Your ability to convey ideas effectively is a significant asset in systems engineering.", "competency_name": "Communication", "improvement_areas": "To further enhance your communication skills, seek opportunities to practice active listening and feedback techniques. Joining groups or clubs focused on public speaking, such as Toastmasters, could be beneficial. Additionally, consider exploring advanced communication training to refine your skills further and learn how to adapt your communication style to various audiences."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have demonstrated a solid understanding of requirements definition, meeting expectations well. This indicates that you are capable of effectively identifying and defining system requirements.", "competency_name": "Requirements Definition", "improvement_areas": "To further enhance your skills, consider seeking opportunities to lead requirements gathering sessions or participate in workshops that focus on advanced techniques for requirements analysis."}, {"user_strengths": "Your level of expertise in system architecting exceeds the required expectations, showcasing your ability to design systems effectively.", "competency_name": "System Architecting", "improvement_areas": "To align with the required level, focus on practical applications of your architectural skills. Engaging in hands-on projects or collaborating with peers on architectural design challenges can provide valuable experience and reinforce your knowledge."}, {"user_strengths": "Currently, there is a gap in your understanding of integration, verification, and validation processes.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "To improve in this area, consider taking introductory courses or certifications that focus on integration and verification practices. Participating in team projects where these processes are implemented can also provide practical experience."}, {"user_strengths": "You have a satisfactory understanding of operation and support, meeting the expectations set for this competency area.", "competency_name": "Operation and Support", "improvement_areas": "To build upon this foundation, look for ways to engage more deeply with operational support activities. This could involve shadowing experienced colleagues or taking part in operational reviews to better understand the nuances of this area."}, {"user_strengths": "You have a strong command over Agile methods, which is above the required level, indicating your proficiency in applying Agile practices effectively.", "competency_name": "Agile Methods", "improvement_areas": "To progress from mastering to applying, consider focusing on real-world Agile project scenarios where you can implement your knowledge. Additionally, mentoring others in Agile practices can reinforce your own understanding and help you to internalize the application of Agile methods."}], "competency_area": "Technical"}]	2025-03-06 14:23:20.35212
69	89	1	[{"feedbacks": [{"user_strengths": "You have a solid understanding of Systems Thinking, which is crucial for grasping complex systems and their interrelated components. This foundational knowledge will serve you well as you tackle more advanced topics in systems engineering.", "competency_name": "Systems Thinking", "improvement_areas": ""}, {"user_strengths": "Your mastery of Lifecycle Consideration indicates a high level of expertise in managing the lifecycle stages of systems, which is an asset in ensuring successful project outcomes.", "competency_name": "Lifecycle Consideration", "improvement_areas": ""}, {"user_strengths": "You possess a good understanding of Customer and Value Orientation, which is essential for aligning engineering efforts with customer needs and maximizing value delivery.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To enhance your capability in this area, consider engaging in practical exercises or projects that emphasize customer interaction and value assessment. Participating in workshops focused on value management or customer engagement strategies can also be beneficial."}, {"user_strengths": "You are currently in the early stages of your journey in Systems Modeling and Analysis, which indicates that you are open to learning and developing new skills in this critical area.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To improve in Systems Modeling and Analysis, I recommend pursuing online courses or workshops that focus on modeling techniques and analysis methods. Additionally, collaborating with experienced colleagues on projects that involve these skills can provide hands-on experience and accelerate your learning."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have a solid understanding of decision management principles, which allows you to make informed choices in your projects.", "competency_name": "Decision Management", "improvement_areas": ""}, {"user_strengths": "You have a foundational awareness of project management concepts, providing a good base to build upon.", "competency_name": "Project Management", "improvement_areas": "To enhance your skills in project management, consider pursuing additional training or certifications such as PMP or PRINCE2. Engaging in hands-on practice by managing smaller projects can also significantly improve your understanding."}, {"user_strengths": "You are actively applying your knowledge of information management, which is beneficial in managing project data and documentation effectively.", "competency_name": "Information Management", "improvement_areas": "To advance your competency in information management, strive for a deeper understanding of data governance and security practices. You might consider taking online courses or workshops that focus on information systems or data management."}, {"user_strengths": "You demonstrate mastery in configuration management, showcasing your ability to effectively oversee and control system configurations.", "competency_name": "Configuration Management", "improvement_areas": ""}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have demonstrated a solid ability to apply leadership skills in practical scenarios, which indicates a proactive approach to leading teams and projects.", "competency_name": "Leadership", "improvement_areas": "To advance your understanding of leadership principles, consider engaging in formal training or workshops focused on leadership theories and practices. Reading books on leadership styles and strategies can also enhance your perspective."}, {"user_strengths": "N/A", "competency_name": "Self-Organization", "improvement_areas": "Improving your self-organization skills is crucial. Start by implementing daily planning techniques, such as time-blocking or setting specific goals. Utilizing digital tools like task managers can help you structure your tasks effectively."}, {"user_strengths": "You have a basic awareness of communication principles, which provides a foundation for your interactions with others.", "competency_name": "Communication", "improvement_areas": "To enhance your understanding of communication, consider participating in workshops or training sessions focused on effective communication techniques. Practicing active listening and engaging in discussions can further improve your skills."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You are beginning to engage with the concept of requirements definition, demonstrating curiosity about the role of requirements in systems engineering.", "competency_name": "Requirements Definition", "improvement_areas": "To improve your understanding, consider taking a foundational course on requirements engineering. Engaging in workshops or working with a mentor who specializes in this area could also provide practical insights."}, {"user_strengths": "You have an awareness of system architecting principles, indicating a basic familiarity with its importance in systems engineering.", "competency_name": "System Architecting", "improvement_areas": "To advance to applying this competency, seek opportunities to participate in projects where system architecting is required. Collaborating with experienced architects or attending relevant training sessions can help solidify your skills."}, {"user_strengths": "Your understanding of integration, verification, and validation processes is solid, showing that you grasp the key concepts and their significance in the systems engineering lifecycle.", "competency_name": "Integration, Verification, Validation", "improvement_areas": ""}, {"user_strengths": "You are effectively applying concepts of operation and support, demonstrating a practical ability in managing and supporting system operations.", "competency_name": "Operation and Support", "improvement_areas": "Consider refining your skills further by engaging in more complex operational scenarios or seeking feedback from peers on your approach."}, {"user_strengths": "You have mastered agile methods, showcasing a high level of proficiency and the ability to guide others in agile practices.", "competency_name": "Agile Methods", "improvement_areas": ""}], "competency_area": "Technical"}]	2025-03-06 14:46:24.163306
70	90	1	[{"feedbacks": [{"user_strengths": "You have a solid awareness of the interrelationships within your system and its boundaries, which is a crucial foundation for systems thinking.", "competency_name": "Systems Thinking", "improvement_areas": "To advance to the required level, focus on applying your knowledge by analyzing your current system. Consider engaging in projects where you can practice deriving continuous improvements based on your analysis. Participating in workshops or training sessions on systems analysis could also be beneficial."}, {"user_strengths": "You demonstrate a good understanding of the importance of considering all lifecycle phases during development, which is essential for effective systems engineering.", "competency_name": "Lifecycle Consideration", "improvement_areas": "To meet the required level, work on identifying and assessing all lifecycle phases relevant to your projects. You might find it helpful to engage in case studies or simulations that require you to evaluate lifecycle considerations. Additionally, seeking mentorship from experienced professionals in lifecycle management can provide valuable insights."}, {"user_strengths": "You have a foundational awareness of agile thinking principles, which is a good starting point for customer and value orientation in systems engineering.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To progress to the required level, aim to develop systems using agile methodologies with a focus on customer benefits. Consider participating in agile project teams or taking part in agile training programs. This hands-on experience will help you apply your knowledge in real-world scenarios."}, {"user_strengths": "You are familiar with the basics of modeling and its benefits, which is an important first step in systems modeling and analysis.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To reach the required level, practice defining your own system models independently. Engage in exercises that require you to create both cross-domain and domain-specific models. Online courses or workshops focused on systems modeling can provide you with the necessary skills and confidence to apply your knowledge effectively."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You are proficient in preparing and making decisions relevant to your scope, and you document these decisions effectively. Additionally, you can apply decision support methods such as utility analysis, demonstrating a solid application of decision management principles.", "competency_name": "Decision Management", "improvement_areas": ""}, {"user_strengths": "You have a good understanding of the project mandate and can contextualize project management within the broader framework of systems engineering. You are capable of creating relevant project plans and generating status reports independently, which is a valuable skill in project management.", "competency_name": "Project Management", "improvement_areas": ""}, {"user_strengths": "", "competency_name": "Information Management", "improvement_areas": "To improve your competency in Information Management, consider engaging in training programs or workshops that focus on knowledge transfer platforms. Familiarize yourself with the types of information that need to be shared within your team and organization. Seeking mentorship from experienced colleagues in this area can also provide valuable insights."}, {"user_strengths": "", "competency_name": "Configuration Management", "improvement_areas": "To enhance your understanding of Configuration Management, I recommend studying the processes involved in defining configuration items. Look for resources or training that cover the tools necessary for creating configurations relevant to your work. Collaborating with team members who have experience in this area can also help you gain practical knowledge."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "Currently, there are no strengths identified in this competency area as you are unaware of the concepts of leadership.", "competency_name": "Leadership", "improvement_areas": "To improve your leadership skills, consider taking a foundational course on leadership principles. Engaging in workshops or reading books on effective leadership can also enhance your understanding. Additionally, seek mentorship from experienced leaders who can provide insights and guidance."}, {"user_strengths": "You have a basic awareness of self-organization concepts, which is a good starting point for further development.", "competency_name": "Self-Organization", "improvement_areas": "To advance your self-organization skills, practice managing small projects or tasks independently. Utilize tools like to-do lists or project management software to help structure your work. Consider attending workshops focused on time management and productivity techniques to enhance your application of self-organization."}, {"user_strengths": "Currently, there are no strengths identified in this competency area as you are unaware of the concepts of effective communication.", "competency_name": "Communication", "improvement_areas": "To improve your communication skills, start by learning the fundamentals of effective communication through online courses or workshops. Practice active listening and empathetic communication in your daily interactions. Joining a local speaking club or participating in group discussions can also provide valuable practice and feedback."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "Currently, the user is aware of the importance of requirements but lacks the necessary knowledge to apply this competency effectively.", "competency_name": "Requirements Definition", "improvement_areas": "To improve in this area, consider taking a course on requirements engineering. Engage in hands-on practice by participating in projects where you can identify, derive, and document requirements. Additionally, seek mentorship from experienced professionals who can guide you through the process."}, {"user_strengths": "The user has a basic awareness of architectural models and their purpose in the development process.", "competency_name": "System Architecting", "improvement_areas": "To advance your understanding, explore resources such as books or online courses focused on system architecture. Participate in workshops or study groups where you can discuss architectural models and their relevance in projects. This will help you gain a deeper understanding of how to read and extract information from these models."}, {"user_strengths": "The user currently lacks knowledge in this competency area.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "To build your understanding, consider enrolling in training focused on integration, verification, and validation processes. Engage in practical exercises that involve reading and analyzing test plans and results. Collaborating with a mentor who has experience in this area can also provide valuable insights."}, {"user_strengths": "The user demonstrates a good understanding of the integration of operation, service, and maintenance phases into development.", "competency_name": "Operation and Support", "improvement_areas": "To enhance your familiarity, review documentation related to the stages of operation, service, and maintenance. Consider creating a summary or visual representation of these stages to solidify your understanding. Engaging in discussions with colleagues about their experiences in these phases can also provide practical insights."}, {"user_strengths": "The user meets the required level by effectively applying Agile methods in various project scenarios.", "competency_name": "Agile Methods", "improvement_areas": ""}], "competency_area": "Technical"}]	2025-03-06 14:54:40.437081
71	91	1	[{"feedbacks": [{"user_strengths": "You demonstrate a solid ability to analyze your present system and derive continuous improvements from it, showcasing a practical application of systems thinking.", "competency_name": "Systems Thinking", "improvement_areas": "To advance to a Mastering level, consider seeking opportunities to lead initiatives that promote systemic thinking within your organization. Engaging in workshops or training sessions focused on advanced systems thinking can also help you develop the skills needed to inspire others."}, {"user_strengths": "You have a good understanding of the importance of considering all lifecycle phases during development, which is essential for effective systems engineering.", "competency_name": "Lifecycle Consideration", "improvement_areas": ""}, {"user_strengths": "You excel in promoting agile thinking within your organization and have the ability to inspire others, demonstrating a strong customer and value orientation.", "competency_name": "Customer / Value Orientation", "improvement_areas": ""}, {"user_strengths": "You currently do not have knowledge in this competency area, indicating an opportunity for growth.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To improve in Systems Modeling and Analysis, consider enrolling in relevant courses or training programs that cover modeling techniques and analysis methods. Hands-on practice with modeling tools and software can also enhance your understanding. Seeking mentorship from experienced colleagues in this area can provide valuable insights and guidance."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have a solid awareness of the main decision-making bodies and understand how decisions are made, which is a great foundation for further development in this area.", "competency_name": "Decision Management", "improvement_areas": ""}, {"user_strengths": "", "competency_name": "Project Management", "improvement_areas": "To improve your competency in Project Management, consider enrolling in a project management training course or workshop. This will help you gain a better understanding of project mandates and the context of project management within systems engineering. Additionally, seek opportunities to work on projects where you can practice creating project plans and generating status reports, which will enhance your practical skills."}, {"user_strengths": "You have achieved a high level of competency in Information Management, as you can define a comprehensive information management process. This demonstrates your expertise and capability in this area.", "competency_name": "Information Management", "improvement_areas": ""}, {"user_strengths": "You possess a good awareness of the necessity of configuration management and are knowledgeable about the tools used to create configurations. This foundational knowledge is essential for further growth in this area.", "competency_name": "Configuration Management", "improvement_areas": ""}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You demonstrate a solid ability to negotiate objectives with your team, which is a key strength in leadership.", "competency_name": "Leadership", "improvement_areas": ""}, {"user_strengths": "You have a good understanding of how self-organization concepts can influence your daily work, which is a valuable foundation.", "competency_name": "Self-Organization", "improvement_areas": "To advance to a mastering level, consider engaging in training programs focused on project management and self-organization techniques. Additionally, seek opportunities to lead complex projects where you can practice and refine your self-organization skills in real-world scenarios."}, {"user_strengths": "You recognize the importance of communication competencies, which is a great starting point for further development.", "competency_name": "Communication", "improvement_areas": "To enhance your communication skills, consider participating in workshops or courses that focus on effective communication strategies. Practicing active listening and engaging in public speaking opportunities can also help you build confidence and proficiency in this area."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You demonstrate a strong ability to independently identify sources of requirements, derive, write, and document them effectively. Your skills in linking, deriving, and analyzing requirements in documents or models are commendable, as is your capability to create and analyze context descriptions and interface specifications.", "competency_name": "Requirements Definition", "improvement_areas": ""}, {"user_strengths": "You possess a solid understanding of the relevance of architectural models in the development process. Your ability to read architectural models and extract pertinent information is a valuable skill that enhances your contributions to system design.", "competency_name": "System Architecting", "improvement_areas": ""}, {"user_strengths": "You excel in setting up testing strategies and experimental plans independently and proactively. Your capability to derive necessary test cases based on requirements and verification/validation criteria, as well as orchestrating and documenting tests and simulations, showcases your mastery in this area.", "competency_name": "Integration, Verification, Validation", "improvement_areas": ""}, {"user_strengths": "You have a good understanding of how the operation, service, and maintenance phases integrate into the development lifecycle. Your ability to list the activities required throughout the lifecycle indicates a solid foundational knowledge.", "competency_name": "Operation and Support", "improvement_areas": ""}, {"user_strengths": "You effectively work in Agile environments and can apply necessary methods, adapting Agile techniques to various project scenarios. This flexibility is a strong asset in dynamic project settings.", "competency_name": "Agile Methods", "improvement_areas": "To advance your competency in Agile Methods to a mastering level, consider seeking opportunities to lead Agile teams or projects. Engaging in training focused on defining and implementing Agile methods can also be beneficial. Additionally, mentoring or collaborating with experienced Agile practitioners can provide insights into motivating others and successfully leading teams."}], "competency_area": "Technical"}]	2025-03-07 14:10:09.744204
72	93	1	[{"feedbacks": [{"user_strengths": "You have a solid awareness of the interrelationships within your system and its boundaries, which is a crucial foundation for deeper understanding.", "competency_name": "Systems Thinking", "improvement_areas": "To enhance your competency in Systems Thinking, focus on developing a deeper understanding of how the individual components of your system interact. Consider engaging in training sessions or workshops that emphasize systems dynamics and interdependencies. Additionally, collaborating with colleagues on projects that require a comprehensive view of system interactions can provide practical experience."}, {"user_strengths": "You demonstrate a strong ability to identify, consider, and assess all lifecycle phases relevant to your scope, which is essential for effective project management.", "competency_name": "Lifecycle Consideration", "improvement_areas": ""}, {"user_strengths": "You excel in promoting agile thinking within your organization and inspiring others, showcasing your mastery in this area.", "competency_name": "Customer / Value Orientation", "improvement_areas": ""}, {"user_strengths": "You possess a good understanding of how models support your work and can read simple models, which is a valuable skill in systems engineering.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": ""}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You are proficient in preparing and making decisions relevant to your scope, and you document these decisions effectively. Additionally, you apply decision support methods, such as utility analysis, which demonstrates a solid understanding of decision management principles.", "competency_name": "Decision Management", "improvement_areas": ""}, {"user_strengths": "You have a strong grasp of project management, as evidenced by your ability to identify process inadequacies and suggest improvements. Your communication skills are commendable, allowing you to effectively convey reports, plans, and mandates to stakeholders.", "competency_name": "Project Management", "improvement_areas": "To further enhance your project management skills, consider focusing on understanding the project mandate in the context of systems engineering. Engaging in training or workshops that cover project planning and status reporting can help you develop the ability to create relevant project plans and generate corresponding status reports independently."}, {"user_strengths": "", "competency_name": "Information Management", "improvement_areas": "To improve your awareness in information management, start by exploring resources that outline the benefits of established information and knowledge management practices. Consider taking introductory courses or attending seminars that focus on the importance of information management in systems engineering."}, {"user_strengths": "You demonstrate a good understanding of the process of defining configuration items and can identify those relevant to your work. Your ability to use the necessary tools for creating configurations indicates a solid foundation in this area.", "competency_name": "Configuration Management", "improvement_areas": "To advance your awareness of configuration management, focus on learning about the necessity of this practice within systems engineering. Familiarizing yourself with the tools used to create configurations will also enhance your competency. Consider seeking out resources or training that cover the basics of configuration management."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You are aware of the necessity of leadership competencies, which is a great starting point for your development in this area.", "competency_name": "Leadership", "improvement_areas": "To enhance your leadership skills, consider seeking out training programs or workshops focused on leadership development. Engaging in mentorship opportunities with experienced leaders can also provide valuable insights and practical experience in defining objectives and articulating them to your team."}, {"user_strengths": "You demonstrate a solid understanding of how self-organization concepts can influence your daily work, which is essential for effective personal management.", "competency_name": "Self-Organization", "improvement_areas": ""}, {"user_strengths": "You are aware of the importance of communication, which is a crucial first step in developing this competency.", "competency_name": "Communication", "improvement_areas": "To improve your communication skills, consider enrolling in courses that focus on effective communication strategies, particularly in the context of systems engineering. Practicing active listening and seeking feedback on your communication style can also help you gain a deeper understanding of its relevance and application."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You demonstrate a strong ability to independently identify sources of requirements, derive, write, and document them effectively. Your skills in linking, deriving, and analyzing requirements in documents or models are commendable, as is your capability to create and analyze context descriptions and interface specifications.", "competency_name": "Requirements Definition", "improvement_areas": "To further enhance your competency, focus on deepening your understanding of the different types and levels of requirements. Consider engaging in training sessions or workshops that cover the theoretical aspects of requirements definition, which will help you solidify your foundational knowledge."}, {"user_strengths": "Currently, you are not aware of the knowledge in this competency area, which indicates an opportunity for growth.", "competency_name": "System Architecting", "improvement_areas": "To improve in System Architecting, start by familiarizing yourself with the purpose of architectural models and their categorization in the development process. You can explore online courses or resources that introduce architectural modeling methodologies and languages. Additionally, seeking mentorship from experienced professionals in this area can provide valuable insights."}, {"user_strengths": "You have a solid awareness of the objectives of verification and validation, along with knowledge of various types and approaches of V&V, which meets the required level.", "competency_name": "Integration, Verification, Validation", "improvement_areas": ""}, {"user_strengths": "You have mastered the ability to define organizational processes for operation, maintenance, and servicing, which exceeds the required level.", "competency_name": "Operation and Support", "improvement_areas": ""}, {"user_strengths": "Currently, you are not aware of the knowledge in this competency area, which indicates an opportunity for growth.", "competency_name": "Agile Methods", "improvement_areas": "To improve your understanding of Agile Methods, consider studying the fundamentals of Agile workflows and their application within development processes. You can find numerous resources, such as books, online courses, or workshops, that cover Agile principles and practices. Engaging in practical projects that utilize Agile methodologies will also enhance your understanding."}], "competency_area": "Technical"}]	2025-03-12 18:18:46.193809
73	94	1	[{"feedbacks": [{"user_strengths": "You are able to analyze your present system and derive continuous improvements from it, demonstrating a solid application of systems thinking principles.", "competency_name": "Systems Thinking", "improvement_areas": ""}, {"user_strengths": "You can identify the lifecycle phases of your system, which is a good foundational understanding of lifecycle considerations.", "competency_name": "Lifecycle Consideration", "improvement_areas": "To improve in this area, focus on gaining a deeper understanding of how to assess and consider all lifecycle phases relevant to your scope. You might consider taking a course on systems engineering lifecycle management or seeking mentorship from a more experienced colleague who can guide you through practical applications."}, {"user_strengths": "You understand how to integrate agile thinking into daily work, which is a valuable skill in today's fast-paced environments.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To advance in this competency, work on developing systems using agile methodologies with a focus on customer benefit. Participating in agile project teams or workshops can provide hands-on experience. Additionally, consider studying case studies that highlight successful agile implementations to better understand customer value integration."}, {"user_strengths": "You are familiar with the basics of modeling and its benefits, which is a good starting point for more advanced modeling techniques.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To enhance your skills in this area, aim to define your own system models independently. You could benefit from practical exercises or software tools that allow you to create and analyze models. Online courses or tutorials on systems modeling can also provide valuable insights and techniques."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have a solid understanding of decision support methods and are aware of the distinction between decisions you can make independently and those that require committee involvement.", "competency_name": "Decision Management", "improvement_areas": "To advance to the next level, focus on gaining practical experience in preparing and making decisions within your relevant scopes. Consider seeking opportunities to apply decision support methods, such as utility analysis, in real scenarios. Participating in workshops or training sessions on decision-making frameworks could also be beneficial."}, {"user_strengths": "You have a basic awareness of project management methods and can identify your activities within a project plan.", "competency_name": "Project Management", "improvement_areas": "To improve your competency in project management, aim to deepen your understanding of the project mandate and how it fits within systems engineering. Engage in training that covers project planning and status reporting, and seek to create project plans and reports independently to build your confidence and skills."}, {"user_strengths": "You demonstrate the ability to define storage structures and documentation guidelines effectively, ensuring relevant information is accessible.", "competency_name": "Information Management", "improvement_areas": "While you are currently applying your skills, it would be beneficial to enhance your understanding of key platforms for knowledge transfer. Consider exploring resources or training that focus on information sharing practices and the types of information that need to be communicated to various stakeholders."}, {"user_strengths": "You currently do not have knowledge in this competency area, which presents an opportunity for growth.", "competency_name": "Configuration Management", "improvement_areas": "To develop your understanding of configuration management, start by familiarizing yourself with the process of defining configuration items. Look for training programs or resources that cover the tools and techniques used in configuration management, and seek mentorship from colleagues who have experience in this area."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have demonstrated a strong ability to strategically develop team members, enhancing their problem-solving capabilities. This indicates a high level of proficiency in leadership, allowing you to guide and mentor others effectively.", "competency_name": "Leadership", "improvement_areas": ""}, {"user_strengths": "You possess a solid understanding of self-organization concepts and how they can influence your daily work, which is a great foundation for further development.", "competency_name": "Self-Organization", "improvement_areas": "To improve in this area, focus on applying self-organization skills in managing projects, processes, and tasks independently. Consider taking on small projects where you can practice these skills, or seek out training sessions that emphasize project management and self-organization techniques."}, {"user_strengths": "You recognize the importance of communication within systems engineering and understand its relevance, which is essential for effective collaboration.", "competency_name": "Communication", "improvement_areas": "To enhance your communication skills, work on applying them in real-world scenarios. Engage in activities that require you to communicate constructively and empathetically, such as team discussions or presentations. You might also benefit from workshops or courses focused on effective communication strategies."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have a solid understanding of the different types of requirements and the importance of traceability in requirement management. Your knowledge of the basic processes involved in identifying, formulating, deriving, and analyzing requirements is commendable.", "competency_name": "Requirements Definition", "improvement_areas": "To advance to the next level, focus on gaining practical experience in independently identifying sources of requirements and documenting them in various formats. Consider seeking opportunities to work on projects where you can practice writing and analyzing requirements, and explore tools that facilitate requirement management."}, {"user_strengths": "You demonstrate a good understanding of the relevance of architectural models in the development process and can effectively read and extract information from these models.", "competency_name": "System Architecting", "improvement_areas": ""}, {"user_strengths": "You are capable of creating test plans and conducting tests, which is a valuable skill in systems engineering.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "To enhance your competency, focus on improving your ability to read and understand test plans, test cases, and results. Consider reviewing existing test documentation and participating in test reviews to gain insights into the analysis of test outcomes."}, {"user_strengths": "You have mastered the definition of organizational processes for operation, maintenance, and servicing, which is a critical aspect of systems engineering.", "competency_name": "Operation and Support", "improvement_areas": ""}, {"user_strengths": "You currently do not have knowledge in Agile methods, which is an area for growth.", "competency_name": "Agile Methods", "improvement_areas": "To meet the required level, consider taking a course or workshop on Agile methodologies. Engage in projects that utilize Agile practices to gain hands-on experience, and seek mentorship from colleagues who are experienced in Agile environments."}], "competency_area": "Technical"}]	2025-03-12 19:20:14.510053
74	95	1	[{"feedbacks": [{"user_strengths": "You are able to analyze your present system and derive continuous improvements from it, demonstrating a practical application of systems thinking.", "competency_name": "Systems Thinking", "improvement_areas": "To enhance your understanding of systems thinking, consider engaging in training or workshops that focus on the interaction of system components. Reading literature on systems theory and participating in group discussions can also deepen your understanding."}, {"user_strengths": "You have a strong mastery of evaluating concepts regarding the consideration of all lifecycle phases, indicating a comprehensive understanding of lifecycle considerations in systems engineering.", "competency_name": "Lifecycle Consideration", "improvement_areas": ""}, {"user_strengths": "You are able to identify the fundamental principles of agile thinking, which is essential for maintaining a customer and value-oriented approach in systems engineering.", "competency_name": "Customer / Value Orientation", "improvement_areas": ""}, {"user_strengths": "You understand how models support your work and are able to read simple models, which is a solid foundation for further development in systems modeling.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To improve your familiarity with the basics of modeling and its benefits, consider taking introductory courses on systems modeling. Engaging in practical exercises or projects that require modeling can also enhance your skills."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You are currently at the awareness level in Decision Management, which indicates that you are open to learning and developing your skills in this area.", "competency_name": "Decision Management", "improvement_areas": "To improve your competency in Decision Management, consider seeking out training resources or workshops that focus on decision-making frameworks and techniques. Engaging in case studies or simulations can also provide practical experience."}, {"user_strengths": "You have mastered Project Management, demonstrating the ability to identify process inadequacies and suggest improvements, as well as effectively communicate with stakeholders.", "competency_name": "Project Management", "improvement_areas": ""}, {"user_strengths": "You are applying your skills in Information Management by defining storage structures and documentation guidelines effectively.", "competency_name": "Information Management", "improvement_areas": "To enhance your competency, aim to deepen your understanding of the key platforms for knowledge transfer. Consider taking courses or reading materials that focus on information sharing strategies and stakeholder communication."}, {"user_strengths": "You have a solid understanding of Configuration Management, being able to define configuration items and use necessary tools effectively.", "competency_name": "Configuration Management", "improvement_areas": ""}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have a solid understanding of the importance of defining objectives for a system and can communicate these objectives effectively to your team, which is a valuable skill in leadership.", "competency_name": "Leadership", "improvement_areas": "To enhance your leadership competencies further, consider engaging in workshops or training sessions focused on leadership principles. Additionally, seeking mentorship from experienced leaders can provide you with insights and practical strategies to develop your awareness of leadership competencies."}, {"user_strengths": "You demonstrate strong self-organization skills by effectively managing projects, processes, and tasks independently, showcasing your ability to apply these skills in practice.", "competency_name": "Self-Organization", "improvement_areas": "To further solidify your understanding of self-organization concepts, you might explore resources such as books or online courses that cover the theoretical aspects of self-organization. This will help you build a more comprehensive awareness of the topic."}, {"user_strengths": "Currently, you have not yet developed awareness in the area of communication, which is essential for effective collaboration and teamwork.", "competency_name": "Communication", "improvement_areas": "To improve your communication skills, consider enrolling in communication skills training or workshops. Engaging in group activities or public speaking opportunities can also help you gain practical experience and build your awareness of effective communication techniques."}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have demonstrated a strong ability to recognize deficiencies in the requirements process and develop suggestions for improvement. Your skills in creating context and interface descriptions and discussing these with stakeholders are commendable, indicating a high level of proficiency in this area.", "competency_name": "Requirements Definition", "improvement_areas": ""}, {"user_strengths": "You possess a solid understanding of the relevant process steps for architectural models and can create models of average complexity. Your ability to ensure that the information is reproducible and aligned with methodology and modeling language is a significant strength.", "competency_name": "System Architecting", "improvement_areas": "To enhance your competency in System Architecting, focus on deepening your understanding of the relevance of architectural models as inputs and outputs in the development process. Consider engaging in training sessions or workshops that cover architectural modeling principles and best practices. Additionally, practice reading and extracting information from various architectural models to strengthen your skills."}, {"user_strengths": "You have achieved a high level of competency in Integration, Verification, and Validation, demonstrating the ability to independently set up testing strategies and experimental plans. Your capability to derive test cases based on requirements and orchestrate tests is impressive.", "competency_name": "Integration, Verification, Validation", "improvement_areas": ""}, {"user_strengths": "Your ability to execute the operation, service, and maintenance phases effectively, along with identifying improvements for future projects, showcases your practical skills in this area.", "competency_name": "Operation and Support", "improvement_areas": ""}, {"user_strengths": "You excel in defining and implementing Agile methods for projects, and your ability to motivate others and lead Agile teams is a notable strength. Your conviction in the benefits of Agile methods reflects a deep understanding of their application.", "competency_name": "Agile Methods", "improvement_areas": ""}], "competency_area": "Technical"}]	2025-03-12 19:34:14.08378
75	96	1	[{"feedbacks": [{"user_strengths": "You demonstrate the ability to analyze your present system and derive continuous improvements from it, which shows a practical application of systems thinking.", "competency_name": "Systems Thinking", "improvement_areas": "To enhance your understanding of systems thinking, consider studying the interactions between individual components of systems. Resources such as books on systems theory or online courses focused on systems dynamics can be beneficial. Engaging in discussions with peers or mentors who have expertise in this area can also deepen your understanding."}, {"user_strengths": "Currently, you have not yet developed awareness in this competency area.", "competency_name": "Lifecycle Consideration", "improvement_areas": "To improve your knowledge of lifecycle consideration, start by familiarizing yourself with the different lifecycle phases of systems. You can find introductory materials online, such as articles or videos that explain the lifecycle phases in systems engineering. Additionally, consider enrolling in a foundational course on systems engineering that covers lifecycle considerations."}, {"user_strengths": "Currently, you have not yet developed awareness in this competency area.", "competency_name": "Customer / Value Orientation", "improvement_areas": "To build your understanding of customer and value orientation, begin by exploring the fundamental principles of agile thinking. Look for resources such as books, online courses, or workshops that focus on agile methodologies. Participating in agile project teams or discussions can also provide practical insights into how value orientation is applied in real-world scenarios."}, {"user_strengths": "You are familiar with the basics of modeling and its benefits, which indicates a solid foundational knowledge in this area.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": ""}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You have demonstrated the ability to prepare and make decisions within your relevant scopes, effectively documenting them and applying decision support methods like utility analysis. This shows a solid practical application of decision management principles.", "competency_name": "Decision Management", "improvement_areas": ""}, {"user_strengths": "", "competency_name": "Project Management", "improvement_areas": "To improve your competency in Project Management, consider enrolling in a foundational project management course or workshop. This will help you gain essential knowledge about project planning, execution, and monitoring. Additionally, seeking mentorship from experienced project managers can provide you with practical insights and guidance."}, {"user_strengths": "You have achieved a high level of mastery in defining a comprehensive information management process, which indicates a strong understanding of how to manage information effectively.", "competency_name": "Information Management", "improvement_areas": ""}, {"user_strengths": "You have a good understanding of the process of defining configuration items and can identify those relevant to your work. This indicates a solid grasp of the tools necessary for creating configurations.", "competency_name": "Configuration Management", "improvement_areas": "To enhance your competency in Configuration Management, focus on increasing your awareness of the necessity of configuration management practices. You might consider reading relevant literature or attending workshops that cover the fundamentals of configuration management and the tools used in the field."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You have demonstrated exceptional leadership skills by strategically developing team members, enhancing their problem-solving capabilities.", "competency_name": "Leadership", "improvement_areas": ""}, {"user_strengths": "You have a solid understanding of self-organization concepts and how they can influence your daily work.", "competency_name": "Self-Organization", "improvement_areas": ""}, {"user_strengths": "You effectively communicate in a constructive and empathetic manner, which is crucial for fostering positive interactions.", "competency_name": "Communication", "improvement_areas": ""}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You have demonstrated a strong ability in Requirements Definition, as you can recognize deficiencies in the process and develop suggestions for improvement. Your capability to create context and interface descriptions and engage in discussions with stakeholders is commendable.", "competency_name": "Requirements Definition", "improvement_areas": ""}, {"user_strengths": "Currently, you are in the early stages of your knowledge in System Architecting. While you have not yet developed awareness in this area, this presents a great opportunity for growth.", "competency_name": "System Architecting", "improvement_areas": "To improve your competency in System Architecting, consider enrolling in foundational courses or workshops that cover the basics of system architecture. Engaging with mentors or professionals in the field can also provide valuable insights and practical knowledge."}, {"user_strengths": "You have a good awareness of the objectives of verification and validation, as well as various types and approaches of V&V. This foundational knowledge is essential for further development in this area.", "competency_name": "Integration, Verification, Validation", "improvement_areas": ""}, {"user_strengths": "You have a solid awareness of the stages of operation, service, and maintenance phases, and you understand their importance during development. This is a good foundation for further understanding.", "competency_name": "Operation and Support", "improvement_areas": "To enhance your competency in Operation and Support, focus on gaining a deeper understanding of how these phases are integrated into the development lifecycle. Consider studying lifecycle management resources or participating in relevant training sessions that cover the activities required throughout the lifecycle."}, {"user_strengths": "You have a good awareness of Agile values and methods, as well as the basic principles of Agile methodologies. This foundational knowledge is beneficial for your ongoing development in Agile practices.", "competency_name": "Agile Methods", "improvement_areas": ""}], "competency_area": "Technical"}]	2025-03-12 20:28:57.064866
76	97	1	[{"feedbacks": [{"user_strengths": "You have a solid understanding of the interaction of the individual components that make up the system, which is essential for effective systems engineering.", "competency_name": "Systems Thinking", "improvement_areas": ""}, {"user_strengths": "You demonstrate a high level of expertise in evaluating concepts regarding the consideration of all lifecycle phases, showcasing your ability to think critically about system development.", "competency_name": "Lifecycle Consideration", "improvement_areas": "To further enhance your skills, consider focusing on practical applications of lifecycle considerations. Engaging in projects where you can identify and assess lifecycle phases relevant to your scope will help solidify your understanding."}, {"user_strengths": "", "competency_name": "Customer / Value Orientation", "improvement_areas": "To improve in this area, seek out training or workshops on agile methodologies and customer-centric design. Collaborating with teams that prioritize customer benefit can also provide valuable hands-on experience."}, {"user_strengths": "You possess a strong capability in setting guidelines for necessary models and writing guidelines for good modeling practices, indicating a deep understanding of modeling principles.", "competency_name": "Systems Modeling and Analysis", "improvement_areas": "To advance your skills, focus on defining your own system models independently. Participating in cross-domain projects can help you differentiate between cross-domain and domain-specific models, enhancing your practical application of modeling techniques."}], "competency_area": "Core"}, {"feedbacks": [{"user_strengths": "You are aware of the main decision-making bodies and understand how decisions are made, which is a solid foundation for further development in this area.", "competency_name": "Decision Management", "improvement_areas": "To enhance your understanding of decision management, consider studying decision support methods in more depth. Engaging in workshops or training sessions focused on decision-making processes can also be beneficial. Additionally, seeking mentorship from experienced professionals in this area can provide practical insights."}, {"user_strengths": "You demonstrate a strong understanding of the project mandate and can effectively create project plans and status reports, which aligns perfectly with the required level.", "competency_name": "Project Management", "improvement_areas": ""}, {"user_strengths": "You have mastered the ability to define a comprehensive information management process, which exceeds the required level and showcases your expertise in this area.", "competency_name": "Information Management", "improvement_areas": ""}, {"user_strengths": "You currently lack awareness in this competency area, indicating an opportunity for growth.", "competency_name": "Configuration Management", "improvement_areas": "To improve your understanding of configuration management, start by familiarizing yourself with the concepts of configuration items and their importance in project management. Consider taking introductory courses or reading relevant literature on configuration management processes. Additionally, hands-on practice with configuration management tools can significantly enhance your skills."}], "competency_area": "Management"}, {"feedbacks": [{"user_strengths": "You currently lack awareness in the area of Leadership, which indicates an opportunity for growth and development in understanding how to define and articulate objectives for a system.", "competency_name": "Leadership", "improvement_areas": "To improve your Leadership competency, consider engaging in training programs or workshops focused on leadership skills. Reading books on leadership and management can also provide valuable insights. Additionally, seeking mentorship from experienced leaders can help you gain practical knowledge and understanding."}, {"user_strengths": "You demonstrate a strong ability to independently manage projects, processes, and tasks using self-organization skills, which meets the required level.", "competency_name": "Self-Organization", "improvement_areas": ""}, {"user_strengths": "You have a solid understanding of the relevance of communication in systems engineering, which meets the required level.", "competency_name": "Communication", "improvement_areas": ""}], "competency_area": "Social / Personal"}, {"feedbacks": [{"user_strengths": "You demonstrate a strong ability to independently identify sources of requirements, derive, write, and document them effectively. Your skills in linking, deriving, and analyzing requirements are commendable, as is your capability to create and analyze context descriptions and interface specifications.", "competency_name": "Requirements Definition", "improvement_areas": "To further enhance your competency in Requirements Definition, consider focusing on deepening your understanding of the different types and levels of requirements. Engaging in training sessions or workshops that cover these topics can be beneficial. Additionally, reviewing existing requirement documents and models to gain insights into their structure and content can help solidify your understanding."}, {"user_strengths": "You have a solid grasp of the relevant process steps for architectural models and can create models of average complexity that are reproducible and aligned with methodology and modeling language. This indicates a good level of practical application in this area.", "competency_name": "System Architecting", "improvement_areas": "Since your current level meets the required level for System Architecting, no improvement suggestions are necessary."}, {"user_strengths": "You possess the ability to read and understand test plans, test cases, and results, which is essential for effective integration, verification, and validation processes.", "competency_name": "Integration, Verification, Validation", "improvement_areas": "Since your current level meets the required level for Integration, Verification, Validation, no improvement suggestions are necessary."}, {"user_strengths": "You are currently at the awareness level in this competency area, which indicates a starting point for growth.", "competency_name": "Operation and Support", "improvement_areas": "To improve your competency in Operation and Support, it is essential to gain a better understanding of how the operation, service, and maintenance phases integrate into the development process. Consider seeking out training programs or resources that cover lifecycle activities in detail. Engaging with a mentor who has experience in this area can also provide valuable insights and guidance."}, {"user_strengths": "You have a foundational awareness of Agile values and methods, which is a good starting point for further development.", "competency_name": "Agile Methods", "improvement_areas": "To advance your competency in Agile Methods, focus on applying Agile techniques in real project scenarios. Participating in Agile training or workshops can help you learn how to effectively work in an Agile environment. Additionally, consider collaborating with teams that utilize Agile methodologies to gain hands-on experience and adapt these techniques to various project contexts."}], "competency_area": "Technical"}]	2025-03-12 21:22:51.297409
\.


--
-- Data for Name: user_role_cluster; Type: TABLE DATA; Schema: public; Owner: adminderik
--

COPY public.user_role_cluster (user_id, role_cluster_id) FROM stdin;
2	4
2	10
3	2
3	6
4	6
4	4
5	9
5	8
5	4
6	4
6	12
7	4
7	12
7	13
8	4
8	12
9	9
9	8
10	9
10	8
10	14
11	9
11	8
12	9
12	8
13	12
13	4
14	9
14	8
15	5
16	9
16	8
17	8
17	5
18	8
18	5
18	14
20	9
21	4
22	8
23	9
24	11
24	12
25	9
25	5
19	9
26	4
26	14
27	3
28	4
28	14
30	40004
31	40004
32	40004
33	40004
34	40004
35	40004
36	1
36	2
36	3
37	40004
38	70007
38	8
39	70007
39	1
40	70007
40	2
41	70007
41	6
42	70007
42	4
43	70007
43	5
44	70007
44	4
44	9
45	70007
45	12
1	12
46	14
47	70007
47	3
48	14
49	70007
49	3
49	7
50	70007
50	3
50	9
50	13
51	1
51	2
52	70007
52	3
53	70007
53	8
54	70007
54	8
55	70007
55	8
56	70007
56	8
57	70007
57	8
58	70007
58	8
59	70007
59	8
60	4
61	4
62	70007
62	5
63	11
63	14
64	40004
65	40004
66	70007
66	5
67	13
67	11
68	70007
68	8
69	4
70	70007
70	9
71	14
71	4
72	70007
72	9
73	40004
74	70007
74	11
75	12
75	11
76	70007
76	3
77	2
77	1
78	70007
78	8
79	11
79	14
80	2
80	10
81	70007
81	3
82	40004
83	70007
83	2
84	40004
85	2
86	40004
87	40004
88	40004
89	5
90	2
91	40004
92	70007
93	70007
93	14
94	2
95	40004
96	40004
97	70007
97	5
97	12
\.


--
-- Data for Name: user_se_competency_survey_results; Type: TABLE DATA; Schema: public; Owner: adminderik
--

COPY public.user_se_competency_survey_results (id, user_id, organization_id, competency_id, score, submitted_at) FROM stdin;
1233	76	1	1	2	2025-01-16 14:57:50.003868
1234	76	1	4	6	2025-01-16 14:57:50.003872
1235	76	1	5	4	2025-01-16 14:57:50.003872
1236	76	1	6	1	2025-01-16 14:57:50.003873
1237	76	1	7	6	2025-01-16 14:57:50.003873
1238	76	1	8	0	2025-01-16 14:57:50.003874
1239	76	1	9	2	2025-01-16 14:57:50.003874
1240	76	1	10	4	2025-01-16 14:57:50.003874
1241	76	1	11	6	2025-01-16 14:57:50.003875
1242	76	1	12	6	2025-01-16 14:57:50.003875
1243	76	1	13	2	2025-01-16 14:57:50.003875
1244	76	1	14	0	2025-01-16 14:57:50.003876
1245	76	1	15	1	2025-01-16 14:57:50.003876
1246	76	1	16	4	2025-01-16 14:57:50.003876
1247	76	1	17	2	2025-01-16 14:57:50.003877
1248	76	1	18	0	2025-01-16 14:57:50.003877
33	2	1	1	6	2024-11-03 17:40:46.672086
34	2	1	4	2	2024-11-03 17:40:46.672104
35	2	1	5	6	2024-11-03 17:40:46.672108
36	2	1	6	6	2024-11-03 17:40:46.672111
37	2	1	7	6	2024-11-03 17:40:46.672113
38	2	1	8	0	2024-11-03 17:40:46.672116
39	2	1	9	4	2024-11-03 17:40:46.672119
40	2	1	10	6	2024-11-03 17:40:46.672121
41	2	1	11	0	2024-11-03 17:40:46.672124
42	2	1	12	0	2024-11-03 17:40:46.672127
43	2	1	13	1	2024-11-03 17:40:46.672129
44	2	1	14	4	2024-11-03 17:40:46.672132
45	2	1	15	6	2024-11-03 17:40:46.672134
46	2	1	16	0	2024-11-03 17:40:46.672137
47	2	1	17	4	2024-11-03 17:40:46.672139
48	2	1	18	6	2024-11-03 17:40:46.672142
49	3	1	1	4	2024-11-03 19:40:22.918158
50	3	1	4	6	2024-11-03 19:40:22.918172
51	3	1	5	0	2024-11-03 19:40:22.918175
52	3	1	6	2	2024-11-03 19:40:22.918178
53	3	1	7	2	2024-11-03 19:40:22.918181
54	3	1	8	0	2024-11-03 19:40:22.918183
55	3	1	9	6	2024-11-03 19:40:22.918186
56	3	1	10	2	2024-11-03 19:40:22.918189
57	3	1	11	2	2024-11-03 19:40:22.918191
58	3	1	12	4	2024-11-03 19:40:22.918194
59	3	1	13	6	2024-11-03 19:40:22.918196
60	3	1	14	4	2024-11-03 19:40:22.918199
61	3	1	15	4	2024-11-03 19:40:22.918201
62	3	1	16	6	2024-11-03 19:40:22.918204
63	3	1	17	6	2024-11-03 19:40:22.918206
64	3	1	18	0	2024-11-03 19:40:22.918209
65	4	1	1	4	2024-11-06 17:02:47.107747
66	4	1	4	6	2024-11-06 17:02:47.107757
67	4	1	5	2	2024-11-06 17:02:47.107761
68	4	1	6	6	2024-11-06 17:02:47.107763
69	4	1	7	4	2024-11-06 17:02:47.107766
70	4	1	8	6	2024-11-06 17:02:47.107768
71	4	1	9	4	2024-11-06 17:02:47.107771
72	4	1	10	6	2024-11-06 17:02:47.107789
73	4	1	11	4	2024-11-06 17:02:47.107798
74	4	1	12	6	2024-11-06 17:02:47.107802
75	4	1	13	6	2024-11-06 17:02:47.107805
76	4	1	14	6	2024-11-06 17:02:47.107808
77	4	1	15	6	2024-11-06 17:02:47.10781
78	4	1	16	6	2024-11-06 17:02:47.107813
79	4	1	17	4	2024-11-06 17:02:47.107815
80	4	1	18	6	2024-11-06 17:02:47.107818
81	5	1	1	4	2024-11-06 17:07:02.754196
82	5	1	4	6	2024-11-06 17:07:02.75421
83	5	1	5	4	2024-11-06 17:07:02.754213
84	5	1	6	6	2024-11-06 17:07:02.754215
85	5	1	7	4	2024-11-06 17:07:02.754218
86	5	1	8	6	2024-11-06 17:07:02.75422
87	5	1	9	6	2024-11-06 17:07:02.754223
88	5	1	10	4	2024-11-06 17:07:02.754225
89	5	1	11	6	2024-11-06 17:07:02.754227
90	5	1	12	4	2024-11-06 17:07:02.75423
91	5	1	13	6	2024-11-06 17:07:02.754233
92	5	1	14	6	2024-11-06 17:07:02.754235
93	5	1	15	4	2024-11-06 17:07:02.754238
94	5	1	16	6	2024-11-06 17:07:02.75424
95	5	1	17	6	2024-11-06 17:07:02.754242
96	5	1	18	6	2024-11-06 17:07:02.754245
97	6	1	1	4	2024-11-06 23:06:59.730412
98	6	1	4	6	2024-11-06 23:06:59.730426
99	6	1	5	6	2024-11-06 23:06:59.73043
100	6	1	6	4	2024-11-06 23:06:59.730433
101	6	1	7	6	2024-11-06 23:06:59.730436
102	6	1	8	0	2024-11-06 23:06:59.730439
103	6	1	9	4	2024-11-06 23:06:59.730441
104	6	1	10	6	2024-11-06 23:06:59.730443
105	6	1	11	0	2024-11-06 23:06:59.730445
106	6	1	12	6	2024-11-06 23:06:59.730447
107	6	1	13	4	2024-11-06 23:06:59.730449
108	6	1	14	4	2024-11-06 23:06:59.730451
109	6	1	15	6	2024-11-06 23:06:59.730453
110	6	1	16	0	2024-11-06 23:06:59.730455
111	6	1	17	6	2024-11-06 23:06:59.730457
112	6	1	18	6	2024-11-06 23:06:59.730459
113	7	1	1	4	2024-11-06 23:37:46.06532
114	7	1	4	6	2024-11-06 23:37:46.065329
115	7	1	5	6	2024-11-06 23:37:46.065333
116	7	1	6	0	2024-11-06 23:37:46.065335
117	7	1	7	4	2024-11-06 23:37:46.065338
118	7	1	8	6	2024-11-06 23:37:46.06534
119	7	1	9	0	2024-11-06 23:37:46.065343
120	7	1	10	4	2024-11-06 23:37:46.065345
121	7	1	11	6	2024-11-06 23:37:46.065348
122	7	1	12	6	2024-11-06 23:37:46.06535
123	7	1	13	6	2024-11-06 23:37:46.065352
124	7	1	14	6	2024-11-06 23:37:46.065355
125	7	1	15	4	2024-11-06 23:37:46.065357
126	7	1	16	6	2024-11-06 23:37:46.06536
127	7	1	17	6	2024-11-06 23:37:46.065362
128	7	1	18	0	2024-11-06 23:37:46.065364
129	8	1	1	4	2024-11-06 23:49:16.793111
130	8	1	4	6	2024-11-06 23:49:16.793123
131	8	1	5	4	2024-11-06 23:49:16.793126
132	8	1	6	2	2024-11-06 23:49:16.793129
133	8	1	7	2	2024-11-06 23:49:16.793131
134	8	1	8	4	2024-11-06 23:49:16.793134
135	8	1	9	6	2024-11-06 23:49:16.793136
136	8	1	10	4	2024-11-06 23:49:16.793139
137	8	1	11	4	2024-11-06 23:49:16.793141
138	8	1	12	6	2024-11-06 23:49:16.793143
139	8	1	13	6	2024-11-06 23:49:16.793146
140	8	1	14	6	2024-11-06 23:49:16.793148
141	8	1	15	6	2024-11-06 23:49:16.79315
142	8	1	16	6	2024-11-06 23:49:16.793153
143	8	1	17	6	2024-11-06 23:49:16.793155
144	8	1	18	4	2024-11-06 23:49:16.793157
145	9	1	1	4	2024-11-06 23:55:28.436386
146	9	1	4	2	2024-11-06 23:55:28.436395
147	9	1	5	6	2024-11-06 23:55:28.436397
148	9	1	6	2	2024-11-06 23:55:28.436398
149	9	1	7	6	2024-11-06 23:55:28.436399
150	9	1	8	4	2024-11-06 23:55:28.436401
151	9	1	9	2	2024-11-06 23:55:28.436402
152	9	1	10	6	2024-11-06 23:55:28.436403
153	9	1	11	4	2024-11-06 23:55:28.436404
154	9	1	12	0	2024-11-06 23:55:28.436405
155	9	1	13	2	2024-11-06 23:55:28.436406
156	9	1	14	4	2024-11-06 23:55:28.436408
157	9	1	15	6	2024-11-06 23:55:28.436409
158	9	1	16	4	2024-11-06 23:55:28.43641
159	9	1	17	6	2024-11-06 23:55:28.436411
160	9	1	18	4	2024-11-06 23:55:28.436412
161	10	3	1	4	2024-11-07 08:14:23.774878
162	10	3	4	6	2024-11-07 08:14:23.774892
163	10	3	5	6	2024-11-07 08:14:23.774895
164	10	3	6	4	2024-11-07 08:14:23.774897
165	10	3	7	6	2024-11-07 08:14:23.774899
166	10	3	8	6	2024-11-07 08:14:23.774901
167	10	3	9	2	2024-11-07 08:14:23.774903
168	10	3	10	1	2024-11-07 08:14:23.774905
169	10	3	11	0	2024-11-07 08:14:23.774907
170	10	3	12	2	2024-11-07 08:14:23.774909
171	10	3	13	4	2024-11-07 08:14:23.774912
172	10	3	14	6	2024-11-07 08:14:23.774914
173	10	3	15	4	2024-11-07 08:14:23.774916
174	10	3	16	6	2024-11-07 08:14:23.774918
175	10	3	17	4	2024-11-07 08:14:23.77492
176	10	3	18	6	2024-11-07 08:14:23.774923
177	11	1	1	2	2024-11-07 08:16:18.413828
178	11	1	4	4	2024-11-07 08:16:18.413849
179	11	1	5	1	2024-11-07 08:16:18.413853
180	11	1	6	6	2024-11-07 08:16:18.413856
181	11	1	7	4	2024-11-07 08:16:18.413859
182	11	1	8	6	2024-11-07 08:16:18.413862
183	11	1	9	0	2024-11-07 08:16:18.413865
184	11	1	10	2	2024-11-07 08:16:18.413868
185	11	1	11	2	2024-11-07 08:16:18.413871
186	11	1	12	6	2024-11-07 08:16:18.413874
187	11	1	13	4	2024-11-07 08:16:18.413877
188	11	1	14	2	2024-11-07 08:16:18.41388
189	11	1	15	4	2024-11-07 08:16:18.413883
190	11	1	16	6	2024-11-07 08:16:18.413886
191	11	1	17	6	2024-11-07 08:16:18.413889
192	11	1	18	6	2024-11-07 08:16:18.413892
193	12	1	1	4	2024-11-07 09:09:56.686687
194	12	1	4	6	2024-11-07 09:09:56.686697
195	12	1	5	4	2024-11-07 09:09:56.6867
196	12	1	6	6	2024-11-07 09:09:56.686702
197	12	1	7	2	2024-11-07 09:09:56.686704
198	12	1	8	4	2024-11-07 09:09:56.686706
199	12	1	9	6	2024-11-07 09:09:56.686708
200	12	1	10	4	2024-11-07 09:09:56.68671
201	12	1	11	6	2024-11-07 09:09:56.686713
202	12	1	12	2	2024-11-07 09:09:56.686715
203	12	1	13	1	2024-11-07 09:09:56.686717
204	12	1	14	0	2024-11-07 09:09:56.686719
205	12	1	15	1	2024-11-07 09:09:56.686721
206	12	1	16	4	2024-11-07 09:09:56.686723
207	12	1	17	6	2024-11-07 09:09:56.686725
208	12	1	18	0	2024-11-07 09:09:56.686727
209	13	1	1	6	2024-11-07 15:10:53.495196
210	13	1	4	4	2024-11-07 15:10:53.495211
211	13	1	5	2	2024-11-07 15:10:53.495213
212	13	1	6	6	2024-11-07 15:10:53.495214
213	13	1	7	4	2024-11-07 15:10:53.495215
214	13	1	8	4	2024-11-07 15:10:53.495215
215	13	1	9	6	2024-11-07 15:10:53.495216
216	13	1	10	4	2024-11-07 15:10:53.495217
217	13	1	11	4	2024-11-07 15:10:53.495217
218	13	1	12	6	2024-11-07 15:10:53.495218
219	13	1	13	4	2024-11-07 15:10:53.495219
220	13	1	14	2	2024-11-07 15:10:53.49522
221	13	1	15	1	2024-11-07 15:10:53.49522
222	13	1	16	6	2024-11-07 15:10:53.495221
223	13	1	17	4	2024-11-07 15:10:53.495222
224	13	1	18	4	2024-11-07 15:10:53.495222
225	14	1	1	0	2024-11-09 17:51:56.556002
226	14	1	4	6	2024-11-09 17:51:56.556013
227	14	1	5	4	2024-11-09 17:51:56.556015
228	14	1	6	6	2024-11-09 17:51:56.556016
229	14	1	7	0	2024-11-09 17:51:56.556017
230	14	1	8	6	2024-11-09 17:51:56.556018
231	14	1	9	6	2024-11-09 17:51:56.556019
232	14	1	10	0	2024-11-09 17:51:56.55602
233	14	1	11	4	2024-11-09 17:51:56.556021
234	14	1	12	6	2024-11-09 17:51:56.556022
235	14	1	13	4	2024-11-09 17:51:56.556023
236	14	1	14	4	2024-11-09 17:51:56.556024
237	14	1	15	6	2024-11-09 17:51:56.556025
238	14	1	16	6	2024-11-09 17:51:56.556026
239	14	1	17	6	2024-11-09 17:51:56.556027
240	14	1	18	6	2024-11-09 17:51:56.556028
241	15	1	1	6	2024-11-09 17:56:14.359
242	15	1	4	6	2024-11-09 17:56:14.359018
243	15	1	5	6	2024-11-09 17:56:14.359021
244	15	1	6	4	2024-11-09 17:56:14.359024
245	15	1	7	2	2024-11-09 17:56:14.359026
246	15	1	8	1	2024-11-09 17:56:14.359029
247	15	1	9	6	2024-11-09 17:56:14.359031
248	15	1	10	4	2024-11-09 17:56:14.359033
249	15	1	11	6	2024-11-09 17:56:14.359036
250	15	1	12	6	2024-11-09 17:56:14.359038
251	15	1	13	4	2024-11-09 17:56:14.359041
252	15	1	14	6	2024-11-09 17:56:14.359043
253	15	1	15	6	2024-11-09 17:56:14.359046
254	15	1	16	0	2024-11-09 17:56:14.359048
255	15	1	17	0	2024-11-09 17:56:14.359051
256	15	1	18	0	2024-11-09 17:56:14.359053
257	16	1	1	4	2024-11-09 18:10:17.039225
258	16	1	4	6	2024-11-09 18:10:17.039242
259	16	1	5	4	2024-11-09 18:10:17.039247
260	16	1	6	6	2024-11-09 18:10:17.03925
261	16	1	7	0	2024-11-09 18:10:17.039253
262	16	1	8	6	2024-11-09 18:10:17.039257
263	16	1	9	6	2024-11-09 18:10:17.03926
264	16	1	10	6	2024-11-09 18:10:17.039263
265	16	1	11	4	2024-11-09 18:10:17.039266
266	16	1	12	6	2024-11-09 18:10:17.039269
267	16	1	13	0	2024-11-09 18:10:17.039272
268	16	1	14	0	2024-11-09 18:10:17.039275
269	16	1	15	6	2024-11-09 18:10:17.039278
270	16	1	16	1	2024-11-09 18:10:17.039281
271	16	1	17	1	2024-11-09 18:10:17.039284
272	16	1	18	2	2024-11-09 18:10:17.039288
273	17	1	1	4	2024-11-13 11:22:09.095276
274	17	1	4	6	2024-11-13 11:22:09.095292
275	17	1	5	1	2024-11-13 11:22:09.095297
276	17	1	6	0	2024-11-13 11:22:09.0953
277	17	1	7	6	2024-11-13 11:22:09.095303
278	17	1	8	4	2024-11-13 11:22:09.095306
279	17	1	9	2	2024-11-13 11:22:09.095308
280	17	1	10	1	2024-11-13 11:22:09.095311
281	17	1	11	0	2024-11-13 11:22:09.095314
282	17	1	12	0	2024-11-13 11:22:09.095317
283	17	1	13	4	2024-11-13 11:22:09.095319
284	17	1	14	6	2024-11-13 11:22:09.095322
285	17	1	15	1	2024-11-13 11:22:09.095324
286	17	1	16	2	2024-11-13 11:22:09.095327
287	17	1	17	2	2024-11-13 11:22:09.095329
288	17	1	18	4	2024-11-13 11:22:09.095332
289	18	1	1	2	2024-11-13 11:40:20.772816
290	18	1	4	4	2024-11-13 11:40:20.772835
291	18	1	5	4	2024-11-13 11:40:20.772838
292	18	1	6	6	2024-11-13 11:40:20.772841
293	18	1	7	6	2024-11-13 11:40:20.772843
294	18	1	8	4	2024-11-13 11:40:20.772846
295	18	1	9	6	2024-11-13 11:40:20.772849
296	18	1	10	2	2024-11-13 11:40:20.772851
297	18	1	11	4	2024-11-13 11:40:20.772854
298	18	1	12	6	2024-11-13 11:40:20.772856
299	18	1	13	0	2024-11-13 11:40:20.772859
300	18	1	14	1	2024-11-13 11:40:20.772862
301	18	1	15	1	2024-11-13 11:40:20.772864
302	18	1	16	4	2024-11-13 11:40:20.772867
303	18	1	17	6	2024-11-13 11:40:20.772869
304	18	1	18	0	2024-11-13 11:40:20.772871
1249	77	1	1	2	2025-02-04 19:06:31.480999
1250	77	1	4	6	2025-02-04 19:06:31.481002
1251	77	1	5	0	2025-02-04 19:06:31.481003
1252	77	1	6	2	2025-02-04 19:06:31.481003
1253	77	1	7	6	2025-02-04 19:06:31.481003
1254	77	1	8	6	2025-02-04 19:06:31.481004
1255	77	1	9	0	2025-02-04 19:06:31.481004
1256	77	1	10	1	2025-02-04 19:06:31.481004
1257	77	1	11	6	2025-02-04 19:06:31.481005
1258	77	1	12	0	2025-02-04 19:06:31.481005
1259	77	1	13	4	2025-02-04 19:06:31.481006
1260	77	1	14	0	2025-02-04 19:06:31.481006
1261	77	1	15	2	2025-02-04 19:06:31.481006
1262	77	1	16	1	2025-02-04 19:06:31.481007
1263	77	1	17	6	2025-02-04 19:06:31.481007
1264	77	1	18	0	2025-02-04 19:06:31.481007
321	20	1	1	4	2024-11-13 16:59:18.408376
322	20	1	4	6	2024-11-13 16:59:18.4084
323	20	1	5	4	2024-11-13 16:59:18.408405
324	20	1	6	4	2024-11-13 16:59:18.408409
325	20	1	7	6	2024-11-13 16:59:18.408412
326	20	1	8	0	2024-11-13 16:59:18.408415
327	20	1	9	0	2024-11-13 16:59:18.408417
328	20	1	10	1	2024-11-13 16:59:18.408424
329	20	1	11	1	2024-11-13 16:59:18.408427
330	20	1	12	2	2024-11-13 16:59:18.408429
331	20	1	13	2	2024-11-13 16:59:18.408432
332	20	1	14	6	2024-11-13 16:59:18.408435
333	20	1	15	0	2024-11-13 16:59:18.408437
334	20	1	16	4	2024-11-13 16:59:18.40844
335	20	1	17	6	2024-11-13 16:59:18.408442
336	20	1	18	0	2024-11-13 16:59:18.408445
337	21	1	1	2	2024-11-14 00:19:12.210089
338	21	1	4	4	2024-11-14 00:19:12.210106
339	21	1	5	6	2024-11-14 00:19:12.21011
340	21	1	6	4	2024-11-14 00:19:12.210113
341	21	1	7	6	2024-11-14 00:19:12.210117
342	21	1	8	2	2024-11-14 00:19:12.21012
343	21	1	9	0	2024-11-14 00:19:12.210123
344	21	1	10	1	2024-11-14 00:19:12.210126
345	21	1	11	4	2024-11-14 00:19:12.210129
346	21	1	12	6	2024-11-14 00:19:12.210132
347	21	1	13	4	2024-11-14 00:19:12.210135
348	21	1	14	6	2024-11-14 00:19:12.210138
349	21	1	15	0	2024-11-14 00:19:12.210141
350	21	1	16	4	2024-11-14 00:19:12.210144
351	21	1	17	4	2024-11-14 00:19:12.210147
352	21	1	18	1	2024-11-14 00:19:12.21015
353	22	1	1	2	2024-11-14 00:34:59.770927
354	22	1	4	6	2024-11-14 00:34:59.770943
355	22	1	5	2	2024-11-14 00:34:59.770946
356	22	1	6	0	2024-11-14 00:34:59.770948
357	22	1	7	1	2024-11-14 00:34:59.770951
358	22	1	8	6	2024-11-14 00:34:59.770953
359	22	1	9	2	2024-11-14 00:34:59.770956
360	22	1	10	4	2024-11-14 00:34:59.770958
361	22	1	11	6	2024-11-14 00:34:59.77096
362	22	1	12	0	2024-11-14 00:34:59.770963
363	22	1	13	4	2024-11-14 00:34:59.770965
364	22	1	14	0	2024-11-14 00:34:59.770967
365	22	1	15	6	2024-11-14 00:34:59.77097
366	22	1	16	2	2024-11-14 00:34:59.770972
367	22	1	17	6	2024-11-14 00:34:59.770974
368	22	1	18	6	2024-11-14 00:34:59.770977
369	23	1	1	2	2024-11-14 10:03:17.077885
370	23	1	4	6	2024-11-14 10:03:17.077901
371	23	1	5	0	2024-11-14 10:03:17.077904
372	23	1	6	1	2024-11-14 10:03:17.077907
373	23	1	7	4	2024-11-14 10:03:17.077909
374	23	1	8	6	2024-11-14 10:03:17.077912
375	23	1	9	2	2024-11-14 10:03:17.077914
376	23	1	10	4	2024-11-14 10:03:17.077917
377	23	1	11	6	2024-11-14 10:03:17.077919
378	23	1	12	4	2024-11-14 10:03:17.077921
379	23	1	13	6	2024-11-14 10:03:17.077924
380	23	1	14	1	2024-11-14 10:03:17.077926
381	23	1	15	6	2024-11-14 10:03:17.077929
382	23	1	16	2	2024-11-14 10:03:17.077942
383	23	1	17	0	2024-11-14 10:03:17.077945
384	23	1	18	2	2024-11-14 10:03:17.077947
385	24	1	1	4	2024-11-14 11:25:38.742055
386	24	1	4	4	2024-11-14 11:25:38.742072
387	24	1	5	2	2024-11-14 11:25:38.742076
388	24	1	6	0	2024-11-14 11:25:38.742079
389	24	1	7	1	2024-11-14 11:25:38.742082
390	24	1	8	0	2024-11-14 11:25:38.742084
391	24	1	9	4	2024-11-14 11:25:38.742087
392	24	1	10	2	2024-11-14 11:25:38.74209
393	24	1	11	6	2024-11-14 11:25:38.742092
394	24	1	12	4	2024-11-14 11:25:38.742096
395	24	1	13	6	2024-11-14 11:25:38.742098
396	24	1	14	2	2024-11-14 11:25:38.742101
397	24	1	15	4	2024-11-14 11:25:38.742103
398	24	1	16	6	2024-11-14 11:25:38.742106
399	24	1	17	4	2024-11-14 11:25:38.742108
400	24	1	18	0	2024-11-14 11:25:38.742111
401	25	1	1	4	2024-11-14 11:39:05.281112
402	25	1	4	6	2024-11-14 11:39:05.281125
403	25	1	5	2	2024-11-14 11:39:05.281127
404	25	1	6	6	2024-11-14 11:39:05.28113
405	25	1	7	4	2024-11-14 11:39:05.281132
406	25	1	8	0	2024-11-14 11:39:05.281134
407	25	1	9	2	2024-11-14 11:39:05.281136
408	25	1	10	6	2024-11-14 11:39:05.281138
409	25	1	11	4	2024-11-14 11:39:05.28114
410	25	1	12	4	2024-11-14 11:39:05.281142
411	25	1	13	6	2024-11-14 11:39:05.281144
412	25	1	14	6	2024-11-14 11:39:05.281146
413	25	1	15	4	2024-11-14 11:39:05.281148
414	25	1	16	6	2024-11-14 11:39:05.28115
415	25	1	17	4	2024-11-14 11:39:05.281153
416	25	1	18	0	2024-11-14 11:39:05.281155
417	19	1	1	4	2024-11-14 13:32:53.361679
418	19	1	4	6	2024-11-14 13:32:53.361707
419	19	1	5	2	2024-11-14 13:32:53.361713
420	19	1	6	0	2024-11-14 13:32:53.361716
421	19	1	7	4	2024-11-14 13:32:53.361719
422	19	1	8	1	2024-11-14 13:32:53.361721
423	19	1	9	2	2024-11-14 13:32:53.361725
424	19	1	10	4	2024-11-14 13:32:53.361727
425	19	1	11	6	2024-11-14 13:32:53.36173
426	19	1	12	0	2024-11-14 13:32:53.361733
427	19	1	13	2	2024-11-14 13:32:53.361736
428	19	1	14	2	2024-11-14 13:32:53.361739
429	19	1	15	1	2024-11-14 13:32:53.361741
430	19	1	16	4	2024-11-14 13:32:53.361744
431	19	1	17	6	2024-11-14 13:32:53.361747
432	19	1	18	0	2024-11-14 13:32:53.361749
433	26	1	1	4	2024-11-18 12:21:40.663259
434	26	1	4	6	2024-11-18 12:21:40.663278
435	26	1	5	2	2024-11-18 12:21:40.663282
436	26	1	6	6	2024-11-18 12:21:40.663285
437	26	1	7	0	2024-11-18 12:21:40.663288
438	26	1	8	1	2024-11-18 12:21:40.663291
439	26	1	9	1	2024-11-18 12:21:40.663294
440	26	1	10	2	2024-11-18 12:21:40.663297
441	26	1	11	6	2024-11-18 12:21:40.6633
442	26	1	12	6	2024-11-18 12:21:40.663303
443	26	1	13	0	2024-11-18 12:21:40.663306
444	26	1	14	1	2024-11-18 12:21:40.663309
445	26	1	15	4	2024-11-18 12:21:40.663312
446	26	1	16	6	2024-11-18 12:21:40.663315
447	26	1	17	4	2024-11-18 12:21:40.663318
448	26	1	18	0	2024-11-18 12:21:40.663321
449	27	1	1	6	2024-11-18 12:29:38.839076
450	27	1	4	1	2024-11-18 12:29:38.839087
451	27	1	5	6	2024-11-18 12:29:38.83909
452	27	1	6	6	2024-11-18 12:29:38.839094
453	27	1	7	6	2024-11-18 12:29:38.839096
454	27	1	8	6	2024-11-18 12:29:38.839099
455	27	1	9	6	2024-11-18 12:29:38.839102
456	27	1	10	6	2024-11-18 12:29:38.839105
457	27	1	11	6	2024-11-18 12:29:38.839108
458	27	1	12	6	2024-11-18 12:29:38.839111
459	27	1	13	6	2024-11-18 12:29:38.839113
460	27	1	14	6	2024-11-18 12:29:38.839116
461	27	1	15	2	2024-11-18 12:29:38.839118
462	27	1	16	6	2024-11-18 12:29:38.839121
463	27	1	17	6	2024-11-18 12:29:38.839124
464	27	1	18	6	2024-11-18 12:29:38.839126
465	28	1	1	6	2024-11-28 17:23:15.268652
466	28	1	4	6	2024-11-28 17:23:15.268661
467	28	1	5	6	2024-11-28 17:23:15.268665
468	28	1	6	6	2024-11-28 17:23:15.268668
469	28	1	7	6	2024-11-28 17:23:15.268671
470	28	1	8	0	2024-11-28 17:23:15.268675
471	28	1	9	1	2024-11-28 17:23:15.268678
472	28	1	10	2	2024-11-28 17:23:15.268681
473	28	1	11	6	2024-11-28 17:23:15.268683
474	28	1	12	6	2024-11-28 17:23:15.268686
475	28	1	13	6	2024-11-28 17:23:15.268689
476	28	1	14	0	2024-11-28 17:23:15.268692
477	28	1	15	2	2024-11-28 17:23:15.268695
478	28	1	16	4	2024-11-28 17:23:15.268698
479	28	1	17	6	2024-11-28 17:23:15.268701
480	28	1	18	0	2024-11-28 17:23:15.268704
481	30	1	1	4	2024-11-28 21:05:39.216853
482	30	1	4	6	2024-11-28 21:05:39.216872
483	30	1	5	2	2024-11-28 21:05:39.216877
484	30	1	6	2	2024-11-28 21:05:39.216882
485	30	1	7	4	2024-11-28 21:05:39.216886
486	30	1	8	2	2024-11-28 21:05:39.21689
487	30	1	9	6	2024-11-28 21:05:39.216894
488	30	1	10	1	2024-11-28 21:05:39.216898
489	30	1	11	4	2024-11-28 21:05:39.216902
490	30	1	12	4	2024-11-28 21:05:39.216906
491	30	1	13	4	2024-11-28 21:05:39.21691
492	30	1	14	6	2024-11-28 21:05:39.216913
493	30	1	15	4	2024-11-28 21:05:39.216917
494	30	1	16	2	2024-11-28 21:05:39.216921
495	30	1	17	4	2024-11-28 21:05:39.216925
496	30	1	18	6	2024-11-28 21:05:39.216928
497	31	1	1	6	2024-11-28 21:50:17.792892
498	31	1	4	0	2024-11-28 21:50:17.792908
499	31	1	5	2	2024-11-28 21:50:17.792912
500	31	1	6	4	2024-11-28 21:50:17.792916
501	31	1	7	6	2024-11-28 21:50:17.79292
502	31	1	8	6	2024-11-28 21:50:17.792923
503	31	1	9	0	2024-11-28 21:50:17.792927
504	31	1	10	1	2024-11-28 21:50:17.792931
505	31	1	11	1	2024-11-28 21:50:17.792935
506	31	1	12	2	2024-11-28 21:50:17.792938
507	31	1	13	4	2024-11-28 21:50:17.792942
508	31	1	14	2	2024-11-28 21:50:17.792946
509	31	1	15	6	2024-11-28 21:50:17.792949
510	31	1	16	4	2024-11-28 21:50:17.792953
511	31	1	17	0	2024-11-28 21:50:17.792956
512	31	1	18	2	2024-11-28 21:50:17.79296
513	32	1	1	4	2024-11-28 21:54:38.245486
514	32	1	4	6	2024-11-28 21:54:38.245502
515	32	1	5	0	2024-11-28 21:54:38.245506
516	32	1	6	4	2024-11-28 21:54:38.245511
517	32	1	7	6	2024-11-28 21:54:38.245514
518	32	1	8	2	2024-11-28 21:54:38.245518
519	32	1	9	1	2024-11-28 21:54:38.245522
520	32	1	10	4	2024-11-28 21:54:38.245525
521	32	1	11	6	2024-11-28 21:54:38.245529
522	32	1	12	6	2024-11-28 21:54:38.245533
523	32	1	13	0	2024-11-28 21:54:38.245536
524	32	1	14	1	2024-11-28 21:54:38.24554
525	32	1	15	4	2024-11-28 21:54:38.245543
526	32	1	16	6	2024-11-28 21:54:38.245547
527	32	1	17	2	2024-11-28 21:54:38.245551
528	32	1	18	6	2024-11-28 21:54:38.245554
529	33	1	1	6	2024-11-28 22:48:05.001632
530	33	1	4	1	2024-11-28 22:48:05.001643
531	33	1	5	0	2024-11-28 22:48:05.001646
532	33	1	6	2	2024-11-28 22:48:05.00165
533	33	1	7	0	2024-11-28 22:48:05.001653
534	33	1	8	4	2024-11-28 22:48:05.001656
535	33	1	9	2	2024-11-28 22:48:05.001659
536	33	1	10	0	2024-11-28 22:48:05.001662
537	33	1	11	2	2024-11-28 22:48:05.001665
538	33	1	12	6	2024-11-28 22:48:05.001668
539	33	1	13	0	2024-11-28 22:48:05.001671
540	33	1	14	2	2024-11-28 22:48:05.001674
541	33	1	15	4	2024-11-28 22:48:05.001677
542	33	1	16	6	2024-11-28 22:48:05.00168
543	33	1	17	2	2024-11-28 22:48:05.001683
544	33	1	18	6	2024-11-28 22:48:05.001686
545	34	1	1	4	2024-11-28 22:50:38.617059
546	34	1	4	1	2024-11-28 22:50:38.617067
547	34	1	5	6	2024-11-28 22:50:38.617069
548	34	1	6	4	2024-11-28 22:50:38.617072
549	34	1	7	2	2024-11-28 22:50:38.617074
550	34	1	8	0	2024-11-28 22:50:38.617076
551	34	1	9	1	2024-11-28 22:50:38.617078
552	34	1	10	4	2024-11-28 22:50:38.61708
553	34	1	11	6	2024-11-28 22:50:38.617083
554	34	1	12	2	2024-11-28 22:50:38.617085
555	34	1	13	6	2024-11-28 22:50:38.617087
556	34	1	14	0	2024-11-28 22:50:38.617089
557	34	1	15	2	2024-11-28 22:50:38.617091
558	34	1	16	4	2024-11-28 22:50:38.617093
559	34	1	17	6	2024-11-28 22:50:38.617095
560	34	1	18	6	2024-11-28 22:50:38.617097
561	35	1	1	6	2024-11-28 23:02:43.781887
562	35	1	4	6	2024-11-28 23:02:43.781899
563	35	1	5	2	2024-11-28 23:02:43.781903
564	35	1	6	6	2024-11-28 23:02:43.781907
565	35	1	7	4	2024-11-28 23:02:43.781911
566	35	1	8	2	2024-11-28 23:02:43.781915
567	35	1	9	6	2024-11-28 23:02:43.781919
568	35	1	10	4	2024-11-28 23:02:43.781924
569	35	1	11	0	2024-11-28 23:02:43.781936
570	35	1	12	2	2024-11-28 23:02:43.781941
571	35	1	13	4	2024-11-28 23:02:43.781945
572	35	1	14	6	2024-11-28 23:02:43.781949
573	35	1	15	2	2024-11-28 23:02:43.781953
574	35	1	16	0	2024-11-28 23:02:43.781957
575	35	1	17	2	2024-11-28 23:02:43.78196
576	35	1	18	6	2024-11-28 23:02:43.781965
577	36	1	1	6	2024-11-28 23:05:07.055778
578	36	1	4	4	2024-11-28 23:05:07.055796
579	36	1	5	6	2024-11-28 23:05:07.0558
580	36	1	6	0	2024-11-28 23:05:07.055804
581	36	1	7	2	2024-11-28 23:05:07.055807
582	36	1	8	6	2024-11-28 23:05:07.055811
583	36	1	9	2	2024-11-28 23:05:07.055815
584	36	1	10	0	2024-11-28 23:05:07.055818
585	36	1	11	2	2024-11-28 23:05:07.055822
586	36	1	12	4	2024-11-28 23:05:07.055825
587	36	1	13	6	2024-11-28 23:05:07.055829
588	36	1	14	4	2024-11-28 23:05:07.055832
589	36	1	15	6	2024-11-28 23:05:07.055836
590	36	1	16	2	2024-11-28 23:05:07.055839
591	36	1	17	1	2024-11-28 23:05:07.055843
592	36	1	18	0	2024-11-28 23:05:07.055846
593	37	1	1	6	2024-11-29 10:51:29.881062
594	37	1	4	2	2024-11-29 10:51:29.881073
595	37	1	5	4	2024-11-29 10:51:29.881077
596	37	1	6	0	2024-11-29 10:51:29.881081
597	37	1	7	1	2024-11-29 10:51:29.881083
598	37	1	8	2	2024-11-29 10:51:29.881086
599	37	1	9	4	2024-11-29 10:51:29.88109
600	37	1	10	6	2024-11-29 10:51:29.881092
601	37	1	11	2	2024-11-29 10:51:29.881095
602	37	1	12	0	2024-11-29 10:51:29.881099
603	37	1	13	1	2024-11-29 10:51:29.881102
604	37	1	14	4	2024-11-29 10:51:29.881105
605	37	1	15	6	2024-11-29 10:51:29.881108
606	37	1	16	4	2024-11-29 10:51:29.881111
607	37	1	17	6	2024-11-29 10:51:29.881114
608	37	1	18	0	2024-11-29 10:51:29.881117
609	38	1	1	4	2024-12-01 15:53:14.067943
610	38	1	4	6	2024-12-01 15:53:14.067958
611	38	1	5	0	2024-12-01 15:53:14.067962
612	38	1	6	2	2024-12-01 15:53:14.067966
613	38	1	7	1	2024-12-01 15:53:14.06797
614	38	1	8	6	2024-12-01 15:53:14.067974
615	38	1	9	2	2024-12-01 15:53:14.067978
616	38	1	10	6	2024-12-01 15:53:14.067981
617	38	1	11	0	2024-12-01 15:53:14.067985
618	38	1	12	2	2024-12-01 15:53:14.067989
619	38	1	13	1	2024-12-01 15:53:14.067992
620	38	1	14	4	2024-12-01 15:53:14.067996
621	38	1	15	6	2024-12-01 15:53:14.068
622	38	1	16	1	2024-12-01 15:53:14.068003
623	38	1	17	6	2024-12-01 15:53:14.068007
624	38	1	18	2	2024-12-01 15:53:14.068011
625	39	1	1	2	2024-12-01 16:29:25.335302
626	39	1	4	4	2024-12-01 16:29:25.335317
627	39	1	5	2	2024-12-01 16:29:25.335321
628	39	1	6	6	2024-12-01 16:29:25.335325
629	39	1	7	2	2024-12-01 16:29:25.335328
630	39	1	8	1	2024-12-01 16:29:25.335331
631	39	1	9	2	2024-12-01 16:29:25.335334
632	39	1	10	1	2024-12-01 16:29:25.335337
633	39	1	11	0	2024-12-01 16:29:25.33534
634	39	1	12	4	2024-12-01 16:29:25.335343
635	39	1	13	6	2024-12-01 16:29:25.335346
636	39	1	14	2	2024-12-01 16:29:25.335349
637	39	1	15	0	2024-12-01 16:29:25.335352
638	39	1	16	4	2024-12-01 16:29:25.335355
639	39	1	17	6	2024-12-01 16:29:25.335358
640	39	1	18	4	2024-12-01 16:29:25.335361
641	40	1	1	2	2024-12-01 16:56:35.74617
642	40	1	4	6	2024-12-01 16:56:35.746183
643	40	1	5	2	2024-12-01 16:56:35.746187
644	40	1	6	4	2024-12-01 16:56:35.74619
645	40	1	7	6	2024-12-01 16:56:35.746194
646	40	1	8	1	2024-12-01 16:56:35.746198
647	40	1	9	0	2024-12-01 16:56:35.746202
648	40	1	10	2	2024-12-01 16:56:35.746206
649	40	1	11	6	2024-12-01 16:56:35.74621
650	40	1	12	2	2024-12-01 16:56:35.746213
651	40	1	13	4	2024-12-01 16:56:35.746217
652	40	1	14	6	2024-12-01 16:56:35.746221
653	40	1	15	2	2024-12-01 16:56:35.746224
654	40	1	16	6	2024-12-01 16:56:35.746228
655	40	1	17	1	2024-12-01 16:56:35.746244
656	40	1	18	1	2024-12-01 16:56:35.746248
657	41	1	1	2	2024-12-01 16:58:38.926922
658	41	1	4	1	2024-12-01 16:58:38.926935
659	41	1	5	4	2024-12-01 16:58:38.926938
660	41	1	6	2	2024-12-01 16:58:38.926942
661	41	1	7	1	2024-12-01 16:58:38.926945
662	41	1	8	4	2024-12-01 16:58:38.926948
663	41	1	9	0	2024-12-01 16:58:38.926951
664	41	1	10	2	2024-12-01 16:58:38.926954
665	41	1	11	4	2024-12-01 16:58:38.926957
666	41	1	12	1	2024-12-01 16:58:38.92696
667	41	1	13	4	2024-12-01 16:58:38.926982
668	41	1	14	2	2024-12-01 16:58:38.92701
669	41	1	15	4	2024-12-01 16:58:38.927019
670	41	1	16	1	2024-12-01 16:58:38.927023
671	41	1	17	2	2024-12-01 16:58:38.927027
672	41	1	18	4	2024-12-01 16:58:38.92703
673	42	1	1	4	2024-12-01 17:05:06.066935
674	42	1	4	6	2024-12-01 17:05:06.066954
675	42	1	5	1	2024-12-01 17:05:06.066961
676	42	1	6	2	2024-12-01 17:05:06.066968
677	42	1	7	4	2024-12-01 17:05:06.066974
678	42	1	8	6	2024-12-01 17:05:06.066981
679	42	1	9	1	2024-12-01 17:05:06.066988
680	42	1	10	2	2024-12-01 17:05:06.066997
681	42	1	11	0	2024-12-01 17:05:06.067003
682	42	1	12	0	2024-12-01 17:05:06.06701
683	42	1	13	2	2024-12-01 17:05:06.067016
684	42	1	14	4	2024-12-01 17:05:06.067023
685	42	1	15	6	2024-12-01 17:05:06.067029
686	42	1	16	1	2024-12-01 17:05:06.067036
687	42	1	17	4	2024-12-01 17:05:06.067045
688	42	1	18	6	2024-12-01 17:05:06.067061
689	43	1	1	2	2024-12-04 22:23:17.876451
690	43	1	4	4	2024-12-04 22:23:17.876466
691	43	1	5	6	2024-12-04 22:23:17.876471
692	43	1	6	0	2024-12-04 22:23:17.876475
693	43	1	7	1	2024-12-04 22:23:17.876479
694	43	1	8	4	2024-12-04 22:23:17.876483
695	43	1	9	6	2024-12-04 22:23:17.876487
696	43	1	10	1	2024-12-04 22:23:17.87649
697	43	1	11	2	2024-12-04 22:23:17.876494
698	43	1	12	6	2024-12-04 22:23:17.876497
699	43	1	13	0	2024-12-04 22:23:17.876501
700	43	1	14	2	2024-12-04 22:23:17.876505
701	43	1	15	4	2024-12-04 22:23:17.876508
702	43	1	16	6	2024-12-04 22:23:17.876512
703	43	1	17	1	2024-12-04 22:23:17.876515
704	43	1	18	6	2024-12-04 22:23:17.876519
705	44	1	1	6	2024-12-04 22:37:15.765266
706	44	1	4	4	2024-12-04 22:37:15.765286
707	44	1	5	6	2024-12-04 22:37:15.765289
708	44	1	6	4	2024-12-04 22:37:15.765292
709	44	1	7	6	2024-12-04 22:37:15.765295
710	44	1	8	4	2024-12-04 22:37:15.765298
711	44	1	9	2	2024-12-04 22:37:15.765301
712	44	1	10	2	2024-12-04 22:37:15.765305
713	44	1	11	2	2024-12-04 22:37:15.765308
714	44	1	12	4	2024-12-04 22:37:15.765311
715	44	1	13	2	2024-12-04 22:37:15.765314
716	44	1	14	6	2024-12-04 22:37:15.765317
717	44	1	15	4	2024-12-04 22:37:15.76532
718	44	1	16	6	2024-12-04 22:37:15.765323
719	44	1	17	4	2024-12-04 22:37:15.765326
720	44	1	18	4	2024-12-04 22:37:15.765329
721	45	1	1	4	2024-12-04 22:57:36.356686
722	45	1	4	2	2024-12-04 22:57:36.356704
723	45	1	5	0	2024-12-04 22:57:36.356709
724	45	1	6	1	2024-12-04 22:57:36.356714
725	45	1	7	2	2024-12-04 22:57:36.356719
726	45	1	8	4	2024-12-04 22:57:36.356724
727	45	1	9	6	2024-12-04 22:57:36.356729
728	45	1	10	0	2024-12-04 22:57:36.356733
729	45	1	11	1	2024-12-04 22:57:36.356738
730	45	1	12	4	2024-12-04 22:57:36.356743
731	45	1	13	6	2024-12-04 22:57:36.356748
732	45	1	14	4	2024-12-04 22:57:36.356753
733	45	1	15	2	2024-12-04 22:57:36.356757
734	45	1	16	1	2024-12-04 22:57:36.356762
735	45	1	17	6	2024-12-04 22:57:36.356766
736	45	1	18	0	2024-12-04 22:57:36.356771
737	1	12	1	4	2024-12-05 11:05:32.357542
738	1	12	4	2	2024-12-05 11:05:32.35756
739	1	12	5	2	2024-12-05 11:05:32.357563
740	1	12	6	6	2024-12-05 11:05:32.357567
741	1	12	7	0	2024-12-05 11:05:32.357571
742	1	12	8	1	2024-12-05 11:05:32.357574
743	1	12	9	2	2024-12-05 11:05:32.357577
744	1	12	10	4	2024-12-05 11:05:32.35758
745	1	12	11	6	2024-12-05 11:05:32.357583
746	1	12	12	2	2024-12-05 11:05:32.357586
747	1	12	13	6	2024-12-05 11:05:32.357589
748	1	12	14	1	2024-12-05 11:05:32.357592
749	1	12	15	1	2024-12-05 11:05:32.357596
750	1	12	16	2	2024-12-05 11:05:32.357599
751	1	12	17	2	2024-12-05 11:05:32.357602
752	1	12	18	6	2024-12-05 11:05:32.357605
753	46	3	1	2	2024-12-05 11:17:44.369614
754	46	3	4	0	2024-12-05 11:17:44.369624
755	46	3	5	4	2024-12-05 11:17:44.369629
756	46	3	6	6	2024-12-05 11:17:44.369633
757	46	3	7	0	2024-12-05 11:17:44.369637
758	46	3	8	1	2024-12-05 11:17:44.36964
759	46	3	9	4	2024-12-05 11:17:44.369644
760	46	3	10	6	2024-12-05 11:17:44.369647
761	46	3	11	2	2024-12-05 11:17:44.369651
762	46	3	12	1	2024-12-05 11:17:44.369655
763	46	3	13	2	2024-12-05 11:17:44.369658
764	46	3	14	6	2024-12-05 11:17:44.369662
765	46	3	15	2	2024-12-05 11:17:44.369665
766	46	3	16	0	2024-12-05 11:17:44.369669
767	46	3	17	2	2024-12-05 11:17:44.369673
768	46	3	18	4	2024-12-05 11:17:44.369688
769	47	3	1	4	2024-12-05 11:33:49.415908
770	47	3	4	6	2024-12-05 11:33:49.415929
771	47	3	5	1	2024-12-05 11:33:49.415933
772	47	3	6	0	2024-12-05 11:33:49.415937
773	47	3	7	2	2024-12-05 11:33:49.415941
774	47	3	8	6	2024-12-05 11:33:49.415945
775	47	3	9	4	2024-12-05 11:33:49.415948
776	47	3	10	1	2024-12-05 11:33:49.415953
777	47	3	11	4	2024-12-05 11:33:49.415957
778	47	3	12	6	2024-12-05 11:33:49.41596
779	47	3	13	2	2024-12-05 11:33:49.415964
780	47	3	14	2	2024-12-05 11:33:49.415968
781	47	3	15	6	2024-12-05 11:33:49.415971
782	47	3	16	4	2024-12-05 11:33:49.415975
783	47	3	17	2	2024-12-05 11:33:49.415978
784	47	3	18	6	2024-12-05 11:33:49.415982
785	48	12	1	4	2024-12-05 11:38:35.362655
786	48	12	4	6	2024-12-05 11:38:35.362662
787	48	12	5	2	2024-12-05 11:38:35.362664
788	48	12	6	1	2024-12-05 11:38:35.362666
789	48	12	7	4	2024-12-05 11:38:35.362668
790	48	12	8	6	2024-12-05 11:38:35.36267
791	48	12	9	2	2024-12-05 11:38:35.362672
792	48	12	10	4	2024-12-05 11:38:35.362674
793	48	12	11	6	2024-12-05 11:38:35.362675
794	48	12	12	2	2024-12-05 11:38:35.362677
795	48	12	13	4	2024-12-05 11:38:35.362679
796	48	12	14	6	2024-12-05 11:38:35.362681
797	48	12	15	4	2024-12-05 11:38:35.362683
798	48	12	16	4	2024-12-05 11:38:35.362684
799	48	12	17	6	2024-12-05 11:38:35.362686
800	48	12	18	4	2024-12-05 11:38:35.362688
801	49	1	1	4	2024-12-05 11:40:14.539457
802	49	1	4	2	2024-12-05 11:40:14.53948
803	49	1	5	6	2024-12-05 11:40:14.539489
804	49	1	6	2	2024-12-05 11:40:14.539496
805	49	1	7	1	2024-12-05 11:40:14.539502
806	49	1	8	6	2024-12-05 11:40:14.539508
807	49	1	9	0	2024-12-05 11:40:14.539515
808	49	1	10	2	2024-12-05 11:40:14.539521
809	49	1	11	1	2024-12-05 11:40:14.539527
810	49	1	12	4	2024-12-05 11:40:14.539534
811	49	1	13	6	2024-12-05 11:40:14.53954
812	49	1	14	2	2024-12-05 11:40:14.539546
813	49	1	15	4	2024-12-05 11:40:14.539552
814	49	1	16	6	2024-12-05 11:40:14.539559
815	49	1	17	2	2024-12-05 11:40:14.539565
816	49	1	18	1	2024-12-05 11:40:14.539571
817	50	1	1	4	2024-12-05 15:09:18.092158
818	50	1	4	6	2024-12-05 15:09:18.092167
819	50	1	5	2	2024-12-05 15:09:18.09217
820	50	1	6	6	2024-12-05 15:09:18.092172
821	50	1	7	2	2024-12-05 15:09:18.092175
822	50	1	8	6	2024-12-05 15:09:18.092177
823	50	1	9	4	2024-12-05 15:09:18.09218
824	50	1	10	2	2024-12-05 15:09:18.092183
825	50	1	11	6	2024-12-05 15:09:18.092185
826	50	1	12	1	2024-12-05 15:09:18.092188
827	50	1	13	0	2024-12-05 15:09:18.09219
828	50	1	14	2	2024-12-05 15:09:18.092193
829	50	1	15	1	2024-12-05 15:09:18.092195
830	50	1	16	4	2024-12-05 15:09:18.092197
831	50	1	17	6	2024-12-05 15:09:18.0922
832	50	1	18	2	2024-12-05 15:09:18.092202
833	51	1	1	4	2024-12-12 10:11:12.590016
834	51	1	4	6	2024-12-12 10:11:12.590025
835	51	1	5	2	2024-12-12 10:11:12.590028
836	51	1	6	0	2024-12-12 10:11:12.590031
837	51	1	7	2	2024-12-12 10:11:12.590034
838	51	1	8	4	2024-12-12 10:11:12.590037
839	51	1	9	6	2024-12-12 10:11:12.59004
840	51	1	10	6	2024-12-12 10:11:12.590043
841	51	1	11	4	2024-12-12 10:11:12.590046
842	51	1	12	2	2024-12-12 10:11:12.590049
843	51	1	13	0	2024-12-12 10:11:12.590052
844	51	1	14	4	2024-12-12 10:11:12.590055
845	51	1	15	2	2024-12-12 10:11:12.590058
846	51	1	16	1	2024-12-12 10:11:12.590061
847	51	1	17	4	2024-12-12 10:11:12.590064
848	51	1	18	6	2024-12-12 10:11:12.590067
849	52	1	1	2	2024-12-30 17:40:59.630605
850	52	1	4	4	2024-12-30 17:40:59.630613
851	52	1	5	6	2024-12-30 17:40:59.630617
852	52	1	6	6	2024-12-30 17:40:59.630621
853	52	1	7	4	2024-12-30 17:40:59.630624
854	52	1	8	6	2024-12-30 17:40:59.630627
855	52	1	9	0	2024-12-30 17:40:59.63063
856	52	1	10	4	2024-12-30 17:40:59.630633
857	52	1	11	6	2024-12-30 17:40:59.630636
858	52	1	12	2	2024-12-30 17:40:59.630639
859	52	1	13	6	2024-12-30 17:40:59.630642
860	52	1	14	6	2024-12-30 17:40:59.630645
861	52	1	15	2	2024-12-30 17:40:59.630648
862	52	1	16	4	2024-12-30 17:40:59.630651
863	52	1	17	6	2024-12-30 17:40:59.630654
864	52	1	18	0	2024-12-30 17:40:59.630657
865	53	1	1	2	2024-12-30 17:59:09.667168
866	53	1	4	4	2024-12-30 17:59:09.667188
867	53	1	5	6	2024-12-30 17:59:09.667193
868	53	1	6	1	2024-12-30 17:59:09.667198
869	53	1	7	0	2024-12-30 17:59:09.667202
870	53	1	8	2	2024-12-30 17:59:09.667207
871	53	1	9	1	2024-12-30 17:59:09.667211
872	53	1	10	6	2024-12-30 17:59:09.667219
873	53	1	11	4	2024-12-30 17:59:09.667223
874	53	1	12	2	2024-12-30 17:59:09.667228
875	53	1	13	1	2024-12-30 17:59:09.667233
876	53	1	14	1	2024-12-30 17:59:09.667237
877	53	1	15	6	2024-12-30 17:59:09.667242
878	53	1	16	0	2024-12-30 17:59:09.667246
879	53	1	17	0	2024-12-30 17:59:09.667251
880	53	1	18	1	2024-12-30 17:59:09.667255
881	54	1	1	2	2024-12-30 18:11:22.115968
882	54	1	4	4	2024-12-30 18:11:22.115979
883	54	1	5	6	2024-12-30 18:11:22.115983
884	54	1	6	1	2024-12-30 18:11:22.115986
885	54	1	7	0	2024-12-30 18:11:22.115989
886	54	1	8	2	2024-12-30 18:11:22.115992
887	54	1	9	1	2024-12-30 18:11:22.115995
888	54	1	10	6	2024-12-30 18:11:22.115998
889	54	1	11	4	2024-12-30 18:11:22.116001
890	54	1	12	2	2024-12-30 18:11:22.116004
891	54	1	13	1	2024-12-30 18:11:22.116008
892	54	1	14	1	2024-12-30 18:11:22.116011
893	54	1	15	6	2024-12-30 18:11:22.116014
894	54	1	16	0	2024-12-30 18:11:22.116017
895	54	1	17	0	2024-12-30 18:11:22.11602
896	54	1	18	1	2024-12-30 18:11:22.116023
897	55	1	1	2	2024-12-30 18:42:44.823752
898	55	1	4	4	2024-12-30 18:42:44.823762
899	55	1	5	6	2024-12-30 18:42:44.823767
900	55	1	6	1	2024-12-30 18:42:44.823771
901	55	1	7	0	2024-12-30 18:42:44.823774
902	55	1	8	2	2024-12-30 18:42:44.823778
903	55	1	9	1	2024-12-30 18:42:44.823782
904	55	1	10	6	2024-12-30 18:42:44.823785
905	55	1	11	4	2024-12-30 18:42:44.823789
906	55	1	12	2	2024-12-30 18:42:44.823793
907	55	1	13	1	2024-12-30 18:42:44.823796
908	55	1	14	1	2024-12-30 18:42:44.8238
909	55	1	15	6	2024-12-30 18:42:44.823803
910	55	1	16	0	2024-12-30 18:42:44.823807
911	55	1	17	0	2024-12-30 18:42:44.823811
912	55	1	18	1	2024-12-30 18:42:44.823814
913	56	1	1	2	2024-12-30 19:00:57.736014
914	56	1	4	4	2024-12-30 19:00:57.736025
915	56	1	5	6	2024-12-30 19:00:57.736029
916	56	1	6	1	2024-12-30 19:00:57.736033
917	56	1	7	0	2024-12-30 19:00:57.736036
918	56	1	8	2	2024-12-30 19:00:57.73604
919	56	1	9	1	2024-12-30 19:00:57.736044
920	56	1	10	6	2024-12-30 19:00:57.736047
921	56	1	11	4	2024-12-30 19:00:57.736051
922	56	1	12	2	2024-12-30 19:00:57.736054
923	56	1	13	1	2024-12-30 19:00:57.736058
924	56	1	14	1	2024-12-30 19:00:57.736061
925	56	1	15	6	2024-12-30 19:00:57.736065
926	56	1	16	0	2024-12-30 19:00:57.736069
927	56	1	17	0	2024-12-30 19:00:57.736072
928	56	1	18	1	2024-12-30 19:00:57.736076
929	57	1	1	2	2024-12-30 19:07:52.782285
930	57	1	4	4	2024-12-30 19:07:52.782297
931	57	1	5	6	2024-12-30 19:07:52.782301
932	57	1	6	1	2024-12-30 19:07:52.782304
933	57	1	7	0	2024-12-30 19:07:52.782307
934	57	1	8	2	2024-12-30 19:07:52.78231
935	57	1	9	1	2024-12-30 19:07:52.782313
936	57	1	10	6	2024-12-30 19:07:52.782316
937	57	1	11	4	2024-12-30 19:07:52.782319
938	57	1	12	2	2024-12-30 19:07:52.782322
939	57	1	13	1	2024-12-30 19:07:52.782325
940	57	1	14	1	2024-12-30 19:07:52.782327
941	57	1	15	6	2024-12-30 19:07:52.782331
942	57	1	16	0	2024-12-30 19:07:52.782334
943	57	1	17	0	2024-12-30 19:07:52.782337
944	57	1	18	1	2024-12-30 19:07:52.78234
945	58	1	1	2	2024-12-30 23:22:01.102004
946	58	1	4	4	2024-12-30 23:22:01.102021
947	58	1	5	6	2024-12-30 23:22:01.102025
948	58	1	6	1	2024-12-30 23:22:01.102029
949	58	1	7	0	2024-12-30 23:22:01.102034
950	58	1	8	2	2024-12-30 23:22:01.102038
951	58	1	9	1	2024-12-30 23:22:01.102041
952	58	1	10	6	2024-12-30 23:22:01.102045
953	58	1	11	4	2024-12-30 23:22:01.102049
954	58	1	12	2	2024-12-30 23:22:01.102053
955	58	1	13	1	2024-12-30 23:22:01.102057
956	58	1	14	1	2024-12-30 23:22:01.102062
957	58	1	15	6	2024-12-30 23:22:01.102065
958	58	1	16	0	2024-12-30 23:22:01.102069
959	58	1	17	0	2024-12-30 23:22:01.102073
960	58	1	18	1	2024-12-30 23:22:01.102076
961	59	1	1	2	2024-12-30 23:36:32.221714
962	59	1	4	4	2024-12-30 23:36:32.221728
963	59	1	5	6	2024-12-30 23:36:32.221732
964	59	1	6	1	2024-12-30 23:36:32.221736
965	59	1	7	0	2024-12-30 23:36:32.221739
966	59	1	8	2	2024-12-30 23:36:32.221743
967	59	1	9	1	2024-12-30 23:36:32.221747
968	59	1	10	6	2024-12-30 23:36:32.22175
969	59	1	11	4	2024-12-30 23:36:32.221754
970	59	1	12	2	2024-12-30 23:36:32.221758
971	59	1	13	1	2024-12-30 23:36:32.221761
972	59	1	14	1	2024-12-30 23:36:32.221765
973	59	1	15	6	2024-12-30 23:36:32.221768
974	59	1	16	0	2024-12-30 23:36:32.221772
975	59	1	17	0	2024-12-30 23:36:32.221776
976	59	1	18	1	2024-12-30 23:36:32.221779
977	60	1	1	1	2024-12-30 23:42:37.640474
978	60	1	4	2	2024-12-30 23:42:37.640489
979	60	1	5	4	2024-12-30 23:42:37.640492
980	60	1	6	6	2024-12-30 23:42:37.640496
981	60	1	7	0	2024-12-30 23:42:37.640499
982	60	1	8	0	2024-12-30 23:42:37.640502
983	60	1	9	6	2024-12-30 23:42:37.640504
984	60	1	10	4	2024-12-30 23:42:37.640507
985	60	1	11	2	2024-12-30 23:42:37.64051
986	60	1	12	1	2024-12-30 23:42:37.640513
987	60	1	13	4	2024-12-30 23:42:37.640516
988	60	1	14	2	2024-12-30 23:42:37.640519
989	60	1	15	6	2024-12-30 23:42:37.640522
990	60	1	16	0	2024-12-30 23:42:37.640525
991	60	1	17	2	2024-12-30 23:42:37.640528
992	60	1	18	6	2024-12-30 23:42:37.640531
993	61	1	1	1	2024-12-30 23:55:18.245593
994	61	1	4	2	2024-12-30 23:55:18.245611
995	61	1	5	4	2024-12-30 23:55:18.245616
996	61	1	6	6	2024-12-30 23:55:18.24562
997	61	1	7	0	2024-12-30 23:55:18.245625
998	61	1	8	0	2024-12-30 23:55:18.24563
999	61	1	9	6	2024-12-30 23:55:18.245634
1000	61	1	10	4	2024-12-30 23:55:18.245639
1001	61	1	11	2	2024-12-30 23:55:18.245644
1002	61	1	12	1	2024-12-30 23:55:18.245648
1003	61	1	13	4	2024-12-30 23:55:18.245653
1004	61	1	14	2	2024-12-30 23:55:18.245658
1005	61	1	15	6	2024-12-30 23:55:18.245662
1006	61	1	16	0	2024-12-30 23:55:18.245667
1007	61	1	17	2	2024-12-30 23:55:18.245671
1008	61	1	18	6	2024-12-30 23:55:18.245676
1009	62	1	1	1	2024-12-31 00:00:35.457428
1010	62	1	4	2	2024-12-31 00:00:35.457442
1011	62	1	5	4	2024-12-31 00:00:35.457445
1012	62	1	6	6	2024-12-31 00:00:35.457449
1013	62	1	7	0	2024-12-31 00:00:35.457452
1014	62	1	8	0	2024-12-31 00:00:35.457455
1015	62	1	9	6	2024-12-31 00:00:35.457458
1016	62	1	10	4	2024-12-31 00:00:35.457461
1017	62	1	11	2	2024-12-31 00:00:35.457464
1018	62	1	12	1	2024-12-31 00:00:35.457467
1019	62	1	13	4	2024-12-31 00:00:35.45747
1020	62	1	14	2	2024-12-31 00:00:35.457473
1021	62	1	15	6	2024-12-31 00:00:35.457476
1022	62	1	16	0	2024-12-31 00:00:35.457479
1023	62	1	17	2	2024-12-31 00:00:35.457482
1024	62	1	18	6	2024-12-31 00:00:35.457485
1025	63	1	1	2	2024-12-31 12:07:08.837132
1026	63	1	4	4	2024-12-31 12:07:08.837149
1027	63	1	5	6	2024-12-31 12:07:08.837154
1028	63	1	6	1	2024-12-31 12:07:08.837158
1029	63	1	7	0	2024-12-31 12:07:08.837162
1030	63	1	8	0	2024-12-31 12:07:08.837166
1031	63	1	9	0	2024-12-31 12:07:08.83717
1032	63	1	10	1	2024-12-31 12:07:08.837174
1033	63	1	11	2	2024-12-31 12:07:08.837178
1034	63	1	12	4	2024-12-31 12:07:08.837182
1035	63	1	13	6	2024-12-31 12:07:08.837186
1036	63	1	14	4	2024-12-31 12:07:08.837189
1037	63	1	15	4	2024-12-31 12:07:08.837193
1038	63	1	16	6	2024-12-31 12:07:08.837197
1039	63	1	17	2	2024-12-31 12:07:08.837201
1040	63	1	18	0	2024-12-31 12:07:08.837204
1041	64	1	1	4	2024-12-31 17:40:59.719332
1042	64	1	4	6	2024-12-31 17:40:59.719338
1043	64	1	5	0	2024-12-31 17:40:59.71934
1044	64	1	6	1	2024-12-31 17:40:59.719341
1045	64	1	7	1	2024-12-31 17:40:59.719343
1046	64	1	8	2	2024-12-31 17:40:59.719344
1047	64	1	9	4	2024-12-31 17:40:59.719345
1048	64	1	10	6	2024-12-31 17:40:59.719347
1049	64	1	11	1	2024-12-31 17:40:59.719348
1050	64	1	12	0	2024-12-31 17:40:59.719349
1051	64	1	13	6	2024-12-31 17:40:59.719351
1052	64	1	14	2	2024-12-31 17:40:59.719352
1053	64	1	15	1	2024-12-31 17:40:59.719354
1054	64	1	16	6	2024-12-31 17:40:59.719355
1055	64	1	17	4	2024-12-31 17:40:59.719356
1056	64	1	18	2	2024-12-31 17:40:59.719358
1057	65	1	1	2	2024-12-31 18:11:52.046696
1058	65	1	4	6	2024-12-31 18:11:52.046713
1059	65	1	5	0	2024-12-31 18:11:52.046718
1060	65	1	6	2	2024-12-31 18:11:52.046722
1061	65	1	7	1	2024-12-31 18:11:52.046725
1062	65	1	8	6	2024-12-31 18:11:52.046729
1063	65	1	9	4	2024-12-31 18:11:52.046733
1064	65	1	10	0	2024-12-31 18:11:52.046737
1065	65	1	11	2	2024-12-31 18:11:52.046741
1066	65	1	12	4	2024-12-31 18:11:52.046744
1067	65	1	13	6	2024-12-31 18:11:52.046748
1068	65	1	14	4	2024-12-31 18:11:52.046752
1069	65	1	15	2	2024-12-31 18:11:52.046755
1070	65	1	16	6	2024-12-31 18:11:52.046759
1071	65	1	17	2	2024-12-31 18:11:52.046762
1072	65	1	18	2	2024-12-31 18:11:52.046766
1073	66	1	1	2	2025-01-03 20:10:34.422444
1074	66	1	4	6	2025-01-03 20:10:34.422456
1075	66	1	5	4	2025-01-03 20:10:34.422462
1076	66	1	6	4	2025-01-03 20:10:34.422466
1077	66	1	7	2	2025-01-03 20:10:34.42247
1078	66	1	8	1	2025-01-03 20:10:34.422473
1079	66	1	9	6	2025-01-03 20:10:34.422477
1080	66	1	10	0	2025-01-03 20:10:34.422481
1081	66	1	11	2	2025-01-03 20:10:34.422485
1082	66	1	12	6	2025-01-03 20:10:34.422489
1083	66	1	13	1	2025-01-03 20:10:34.422492
1084	66	1	14	4	2025-01-03 20:10:34.422496
1085	66	1	15	6	2025-01-03 20:10:34.4225
1086	66	1	16	0	2025-01-03 20:10:34.422503
1087	66	1	17	2	2025-01-03 20:10:34.422507
1088	66	1	18	1	2025-01-03 20:10:34.422511
1089	67	1	1	4	2025-01-03 20:22:39.113432
1090	67	1	4	2	2025-01-03 20:22:39.113446
1091	67	1	5	6	2025-01-03 20:22:39.11345
1092	67	1	6	1	2025-01-03 20:22:39.113453
1093	67	1	7	2	2025-01-03 20:22:39.113456
1094	67	1	8	6	2025-01-03 20:22:39.113459
1095	67	1	9	1	2025-01-03 20:22:39.113462
1096	67	1	10	2	2025-01-03 20:22:39.113465
1097	67	1	11	4	2025-01-03 20:22:39.113468
1098	67	1	12	6	2025-01-03 20:22:39.113471
1099	67	1	13	1	2025-01-03 20:22:39.113474
1100	67	1	14	2	2025-01-03 20:22:39.113478
1101	67	1	15	6	2025-01-03 20:22:39.113481
1102	67	1	16	0	2025-01-03 20:22:39.113484
1103	67	1	17	1	2025-01-03 20:22:39.113487
1104	67	1	18	6	2025-01-03 20:22:39.11349
1105	68	1	1	2	2025-01-05 13:29:26.656375
1106	68	1	4	6	2025-01-05 13:29:26.656393
1107	68	1	5	0	2025-01-05 13:29:26.656399
1108	68	1	6	1	2025-01-05 13:29:26.656404
1109	68	1	7	2	2025-01-05 13:29:26.656409
1110	68	1	8	6	2025-01-05 13:29:26.656413
1111	68	1	9	4	2025-01-05 13:29:26.656418
1112	68	1	10	6	2025-01-05 13:29:26.656423
1113	68	1	11	0	2025-01-05 13:29:26.656427
1114	68	1	12	2	2025-01-05 13:29:26.656432
1115	68	1	13	4	2025-01-05 13:29:26.656437
1116	68	1	14	6	2025-01-05 13:29:26.656441
1117	68	1	15	0	2025-01-05 13:29:26.656446
1118	68	1	16	2	2025-01-05 13:29:26.656449
1119	68	1	17	1	2025-01-05 13:29:26.656453
1120	68	1	18	2	2025-01-05 13:29:26.656456
1121	69	1	1	2	2025-01-14 19:52:05.656575
1122	69	1	4	6	2025-01-14 19:52:05.656598
1123	69	1	5	2	2025-01-14 19:52:05.656606
1124	69	1	6	0	2025-01-14 19:52:05.656613
1125	69	1	7	1	2025-01-14 19:52:05.65662
1126	69	1	8	4	2025-01-14 19:52:05.656626
1127	69	1	9	6	2025-01-14 19:52:05.656632
1128	69	1	10	2	2025-01-14 19:52:05.656639
1129	69	1	11	6	2025-01-14 19:52:05.656645
1130	69	1	12	0	2025-01-14 19:52:05.656651
1131	69	1	13	2	2025-01-14 19:52:05.656658
1132	69	1	14	6	2025-01-14 19:52:05.656664
1133	69	1	15	2	2025-01-14 19:52:05.65667
1134	69	1	16	1	2025-01-14 19:52:05.656677
1135	69	1	17	6	2025-01-14 19:52:05.656683
1136	69	1	18	0	2025-01-14 19:52:05.656689
1137	70	1	1	2	2025-01-14 20:06:35.344987
1138	70	1	4	6	2025-01-14 20:06:35.344995
1139	70	1	5	4	2025-01-14 20:06:35.344996
1140	70	1	6	0	2025-01-14 20:06:35.344997
1141	70	1	7	4	2025-01-14 20:06:35.344998
1142	70	1	8	6	2025-01-14 20:06:35.344999
1143	70	1	9	2	2025-01-14 20:06:35.344999
1144	70	1	10	6	2025-01-14 20:06:35.345
1145	70	1	11	2	2025-01-14 20:06:35.345001
1146	70	1	12	6	2025-01-14 20:06:35.345002
1147	70	1	13	2	2025-01-14 20:06:35.345002
1148	70	1	14	6	2025-01-14 20:06:35.345003
1149	70	1	15	2	2025-01-14 20:06:35.345004
1150	70	1	16	6	2025-01-14 20:06:35.345004
1151	70	1	17	2	2025-01-14 20:06:35.345005
1152	70	1	18	6	2025-01-14 20:06:35.345006
1153	71	1	1	2	2025-01-15 18:54:08.463611
1154	71	1	4	4	2025-01-15 18:54:08.463616
1155	71	1	5	6	2025-01-15 18:54:08.463617
1156	71	1	6	2	2025-01-15 18:54:08.463617
1157	71	1	7	0	2025-01-15 18:54:08.463618
1158	71	1	8	6	2025-01-15 18:54:08.463619
1159	71	1	9	1	2025-01-15 18:54:08.463619
1160	71	1	10	6	2025-01-15 18:54:08.463619
1161	71	1	11	0	2025-01-15 18:54:08.46362
1162	71	1	12	2	2025-01-15 18:54:08.46362
1163	71	1	13	6	2025-01-15 18:54:08.463621
1164	71	1	14	6	2025-01-15 18:54:08.463621
1165	71	1	15	2	2025-01-15 18:54:08.463621
1166	71	1	16	0	2025-01-15 18:54:08.463622
1167	71	1	17	2	2025-01-15 18:54:08.463622
1168	71	1	18	4	2025-01-15 18:54:08.463622
1169	72	1	1	4	2025-01-15 18:56:47.351309
1170	72	1	4	6	2025-01-15 18:56:47.351313
1171	72	1	5	1	2025-01-15 18:56:47.351313
1172	72	1	6	2	2025-01-15 18:56:47.351313
1173	72	1	7	0	2025-01-15 18:56:47.351314
1174	72	1	8	2	2025-01-15 18:56:47.351314
1175	72	1	9	6	2025-01-15 18:56:47.351315
1176	72	1	10	0	2025-01-15 18:56:47.351315
1177	72	1	11	1	2025-01-15 18:56:47.351315
1178	72	1	12	4	2025-01-15 18:56:47.351316
1179	72	1	13	2	2025-01-15 18:56:47.351316
1180	72	1	14	6	2025-01-15 18:56:47.351317
1181	72	1	15	0	2025-01-15 18:56:47.351317
1182	72	1	16	1	2025-01-15 18:56:47.351318
1183	72	1	17	4	2025-01-15 18:56:47.351318
1184	72	1	18	6	2025-01-15 18:56:47.351318
1185	73	1	1	4	2025-01-15 20:00:53.66905
1186	73	1	4	6	2025-01-15 20:00:53.669053
1187	73	1	5	2	2025-01-15 20:00:53.669053
1188	73	1	6	0	2025-01-15 20:00:53.669054
1189	73	1	7	1	2025-01-15 20:00:53.669054
1190	73	1	8	2	2025-01-15 20:00:53.669055
1191	73	1	9	6	2025-01-15 20:00:53.669055
1192	73	1	10	0	2025-01-15 20:00:53.669055
1193	73	1	11	2	2025-01-15 20:00:53.669056
1194	73	1	12	4	2025-01-15 20:00:53.669056
1195	73	1	13	6	2025-01-15 20:00:53.669057
1196	73	1	14	0	2025-01-15 20:00:53.669057
1197	73	1	15	2	2025-01-15 20:00:53.669057
1198	73	1	16	6	2025-01-15 20:00:53.669058
1199	73	1	17	2	2025-01-15 20:00:53.669058
1200	73	1	18	6	2025-01-15 20:00:53.669058
1201	74	1	1	2	2025-01-16 02:33:31.845968
1202	74	1	4	6	2025-01-16 02:33:31.845974
1203	74	1	5	6	2025-01-16 02:33:31.845974
1204	74	1	6	6	2025-01-16 02:33:31.845975
1205	74	1	7	6	2025-01-16 02:33:31.845975
1206	74	1	8	0	2025-01-16 02:33:31.845976
1207	74	1	9	6	2025-01-16 02:33:31.845977
1208	74	1	10	6	2025-01-16 02:33:31.845977
1209	74	1	11	6	2025-01-16 02:33:31.845977
1210	74	1	12	4	2025-01-16 02:33:31.845978
1211	74	1	13	6	2025-01-16 02:33:31.845978
1212	74	1	14	6	2025-01-16 02:33:31.845978
1213	74	1	15	6	2025-01-16 02:33:31.845979
1214	74	1	16	6	2025-01-16 02:33:31.845979
1215	74	1	17	6	2025-01-16 02:33:31.84598
1216	74	1	18	6	2025-01-16 02:33:31.84598
1217	75	1	1	4	2025-01-16 10:22:01.864818
1218	75	1	4	6	2025-01-16 10:22:01.864821
1219	75	1	5	2	2025-01-16 10:22:01.864822
1220	75	1	6	0	2025-01-16 10:22:01.864822
1221	75	1	7	1	2025-01-16 10:22:01.864822
1222	75	1	8	4	2025-01-16 10:22:01.864823
1223	75	1	9	6	2025-01-16 10:22:01.864823
1224	75	1	10	0	2025-01-16 10:22:01.864824
1225	75	1	11	2	2025-01-16 10:22:01.864824
1226	75	1	12	6	2025-01-16 10:22:01.864824
1227	75	1	13	2	2025-01-16 10:22:01.864825
1228	75	1	14	0	2025-01-16 10:22:01.864825
1229	75	1	15	2	2025-01-16 10:22:01.864826
1230	75	1	16	0	2025-01-16 10:22:01.864826
1231	75	1	17	2	2025-01-16 10:22:01.864826
1232	75	1	18	6	2025-01-16 10:22:01.864827
1265	78	1	1	4	2025-02-17 23:29:41.670634
1266	78	1	4	6	2025-02-17 23:29:41.670638
1267	78	1	5	0	2025-02-17 23:29:41.670638
1268	78	1	6	2	2025-02-17 23:29:41.670639
1269	78	1	7	4	2025-02-17 23:29:41.670639
1270	78	1	8	6	2025-02-17 23:29:41.67064
1271	78	1	9	2	2025-02-17 23:29:41.67064
1272	78	1	10	6	2025-02-17 23:29:41.67064
1273	78	1	11	2	2025-02-17 23:29:41.670641
1274	78	1	12	0	2025-02-17 23:29:41.670641
1275	78	1	13	2	2025-02-17 23:29:41.670641
1276	78	1	14	1	2025-02-17 23:29:41.670642
1277	78	1	15	6	2025-02-17 23:29:41.670642
1278	78	1	16	4	2025-02-17 23:29:41.670643
1279	78	1	17	2	2025-02-17 23:29:41.670643
1280	78	1	18	6	2025-02-17 23:29:41.670643
1281	79	1	1	2	2025-02-17 23:34:16.899112
1282	79	1	4	1	2025-02-17 23:34:16.899116
1283	79	1	5	4	2025-02-17 23:34:16.899116
1284	79	1	6	6	2025-02-17 23:34:16.899117
1285	79	1	7	1	2025-02-17 23:34:16.899117
1286	79	1	8	2	2025-02-17 23:34:16.899117
1287	79	1	9	1	2025-02-17 23:34:16.899118
1288	79	1	10	4	2025-02-17 23:34:16.899118
1289	79	1	11	2	2025-02-17 23:34:16.899119
1290	79	1	12	6	2025-02-17 23:34:16.899119
1291	79	1	13	1	2025-02-17 23:34:16.899119
1292	79	1	14	6	2025-02-17 23:34:16.89912
1293	79	1	15	2	2025-02-17 23:34:16.89912
1294	79	1	16	0	2025-02-17 23:34:16.899121
1295	79	1	17	2	2025-02-17 23:34:16.899121
1296	79	1	18	1	2025-02-17 23:34:16.899121
1297	80	1	1	4	2025-02-17 23:36:06.07438
1298	80	1	4	0	2025-02-17 23:36:06.074383
1299	80	1	5	1	2025-02-17 23:36:06.074384
1300	80	1	6	2	2025-02-17 23:36:06.074384
1301	80	1	7	6	2025-02-17 23:36:06.074385
1302	80	1	8	4	2025-02-17 23:36:06.074385
1303	80	1	9	0	2025-02-17 23:36:06.074385
1304	80	1	10	1	2025-02-17 23:36:06.074386
1305	80	1	11	2	2025-02-17 23:36:06.074386
1306	80	1	12	6	2025-02-17 23:36:06.074386
1307	80	1	13	2	2025-02-17 23:36:06.074387
1308	80	1	14	6	2025-02-17 23:36:06.074387
1309	80	1	15	2	2025-02-17 23:36:06.074387
1310	80	1	16	6	2025-02-17 23:36:06.074388
1311	80	1	17	2	2025-02-17 23:36:06.074388
1312	80	1	18	6	2025-02-17 23:36:06.074389
1313	81	1	1	2	2025-02-24 18:28:09.517917
1314	81	1	4	4	2025-02-24 18:28:09.51792
1315	81	1	5	6	2025-02-24 18:28:09.51792
1316	81	1	6	2	2025-02-24 18:28:09.517921
1317	81	1	7	4	2025-02-24 18:28:09.517921
1318	81	1	8	4	2025-02-24 18:28:09.517921
1319	81	1	9	2	2025-02-24 18:28:09.517922
1320	81	1	10	4	2025-02-24 18:28:09.517922
1321	81	1	11	6	2025-02-24 18:28:09.517923
1322	81	1	12	6	2025-02-24 18:28:09.517923
1323	81	1	13	0	2025-02-24 18:28:09.517923
1324	81	1	14	2	2025-02-24 18:28:09.517924
1325	81	1	15	6	2025-02-24 18:28:09.517924
1326	81	1	16	4	2025-02-24 18:28:09.517925
1327	81	1	17	4	2025-02-24 18:28:09.517925
1328	81	1	18	2	2025-02-24 18:28:09.517925
1329	82	1	1	4	2025-03-01 11:06:27.349494
1330	82	1	4	0	2025-03-01 11:06:27.349498
1331	82	1	5	2	2025-03-01 11:06:27.349498
1332	82	1	6	1	2025-03-01 11:06:27.349499
1333	82	1	7	4	2025-03-01 11:06:27.349499
1334	82	1	8	1	2025-03-01 11:06:27.349499
1335	82	1	9	6	2025-03-01 11:06:27.3495
1336	82	1	10	4	2025-03-01 11:06:27.3495
1337	82	1	11	2	2025-03-01 11:06:27.349501
1338	82	1	12	1	2025-03-01 11:06:27.349501
1339	82	1	13	6	2025-03-01 11:06:27.349501
1340	82	1	14	0	2025-03-01 11:06:27.349502
1341	82	1	15	2	2025-03-01 11:06:27.349502
1342	82	1	16	4	2025-03-01 11:06:27.349502
1343	82	1	17	2	2025-03-01 11:06:27.349503
1344	82	1	18	1	2025-03-01 11:06:27.349503
1345	83	1	1	1	2025-03-03 13:41:32.377551
1346	83	1	4	0	2025-03-03 13:41:32.377555
1347	83	1	5	0	2025-03-03 13:41:32.377555
1348	83	1	6	6	2025-03-03 13:41:32.377556
1349	83	1	7	4	2025-03-03 13:41:32.377556
1350	83	1	8	4	2025-03-03 13:41:32.377557
1351	83	1	9	6	2025-03-03 13:41:32.377557
1352	83	1	10	1	2025-03-03 13:41:32.377558
1353	83	1	11	6	2025-03-03 13:41:32.377558
1354	83	1	12	1	2025-03-03 13:41:32.377558
1355	83	1	13	0	2025-03-03 13:41:32.377559
1356	83	1	14	6	2025-03-03 13:41:32.377559
1357	83	1	15	4	2025-03-03 13:41:32.37756
1358	83	1	16	4	2025-03-03 13:41:32.37756
1359	83	1	17	4	2025-03-03 13:41:32.377561
1360	83	1	18	2	2025-03-03 13:41:32.377561
1361	84	1	1	2	2025-03-05 15:35:46.250688
1362	84	1	4	1	2025-03-05 15:35:46.250691
1363	84	1	5	2	2025-03-05 15:35:46.250691
1364	84	1	6	4	2025-03-05 15:35:46.250692
1365	84	1	7	4	2025-03-05 15:35:46.250692
1366	84	1	8	0	2025-03-05 15:35:46.250693
1367	84	1	9	6	2025-03-05 15:35:46.250693
1368	84	1	10	4	2025-03-05 15:35:46.250694
1369	84	1	11	4	2025-03-05 15:35:46.250694
1370	84	1	12	0	2025-03-05 15:35:46.250695
1371	84	1	13	1	2025-03-05 15:35:46.250695
1372	84	1	14	2	2025-03-05 15:35:46.250696
1373	84	1	15	1	2025-03-05 15:35:46.250696
1374	84	1	16	2	2025-03-05 15:35:46.250697
1375	84	1	17	0	2025-03-05 15:35:46.250697
1376	84	1	18	1	2025-03-05 15:35:46.250698
1377	85	1	1	2	2025-03-06 09:41:20.728452
1378	85	1	4	4	2025-03-06 09:41:20.728464
1379	85	1	5	6	2025-03-06 09:41:20.728468
1380	85	1	6	2	2025-03-06 09:41:20.728472
1381	85	1	7	0	2025-03-06 09:41:20.728475
1382	85	1	8	1	2025-03-06 09:41:20.728479
1383	85	1	9	2	2025-03-06 09:41:20.728483
1384	85	1	10	6	2025-03-06 09:41:20.728486
1385	85	1	11	0	2025-03-06 09:41:20.72849
1386	85	1	12	2	2025-03-06 09:41:20.728493
1387	85	1	13	6	2025-03-06 09:41:20.728497
1388	85	1	14	4	2025-03-06 09:41:20.728501
1389	85	1	15	1	2025-03-06 09:41:20.728504
1390	85	1	16	6	2025-03-06 09:41:20.728508
1391	85	1	17	0	2025-03-06 09:41:20.728512
1392	85	1	18	4	2025-03-06 09:41:20.728515
1393	86	1	1	4	2025-03-06 10:26:32.837354
1394	86	1	4	6	2025-03-06 10:26:32.837364
1395	86	1	5	0	2025-03-06 10:26:32.837368
1396	86	1	6	2	2025-03-06 10:26:32.837371
1397	86	1	7	6	2025-03-06 10:26:32.837374
1398	86	1	8	0	2025-03-06 10:26:32.837377
1399	86	1	9	2	2025-03-06 10:26:32.83738
1400	86	1	10	4	2025-03-06 10:26:32.837384
1401	86	1	11	0	2025-03-06 10:26:32.837387
1402	86	1	12	1	2025-03-06 10:26:32.83739
1403	86	1	13	6	2025-03-06 10:26:32.837393
1404	86	1	14	0	2025-03-06 10:26:32.837396
1405	86	1	15	2	2025-03-06 10:26:32.837399
1406	86	1	16	6	2025-03-06 10:26:32.837402
1407	86	1	17	0	2025-03-06 10:26:32.837405
1408	86	1	18	2	2025-03-06 10:26:32.837408
1409	87	1	1	4	2025-03-06 14:21:36.940889
1410	87	1	4	0	2025-03-06 14:21:36.940905
1411	87	1	5	1	2025-03-06 14:21:36.940912
1412	87	1	6	2	2025-03-06 14:21:36.940919
1413	87	1	7	4	2025-03-06 14:21:36.940926
1414	87	1	8	6	2025-03-06 14:21:36.940932
1415	87	1	9	0	2025-03-06 14:21:36.940939
1416	87	1	10	1	2025-03-06 14:21:36.940945
1417	87	1	11	4	2025-03-06 14:21:36.940951
1418	87	1	12	6	2025-03-06 14:21:36.940958
1419	87	1	13	2	2025-03-06 14:21:36.940964
1420	87	1	14	0	2025-03-06 14:21:36.94097
1421	87	1	15	4	2025-03-06 14:21:36.940977
1422	87	1	16	2	2025-03-06 14:21:36.940983
1423	87	1	17	1	2025-03-06 14:21:36.940989
1424	87	1	18	6	2025-03-06 14:21:36.941071
1425	88	1	1	4	2025-03-06 14:22:48.922641
1426	88	1	4	6	2025-03-06 14:22:48.922658
1427	88	1	5	0	2025-03-06 14:22:48.922664
1428	88	1	6	2	2025-03-06 14:22:48.922668
1429	88	1	7	6	2025-03-06 14:22:48.922685
1430	88	1	8	0	2025-03-06 14:22:48.92269
1431	88	1	9	2	2025-03-06 14:22:48.922695
1432	88	1	10	6	2025-03-06 14:22:48.922729
1433	88	1	11	4	2025-03-06 14:22:48.922734
1434	88	1	12	2	2025-03-06 14:22:48.922738
1435	88	1	13	6	2025-03-06 14:22:48.922743
1436	88	1	14	2	2025-03-06 14:22:48.922748
1437	88	1	15	6	2025-03-06 14:22:48.922752
1438	88	1	16	0	2025-03-06 14:22:48.922757
1439	88	1	17	2	2025-03-06 14:22:48.922762
1440	88	1	18	6	2025-03-06 14:22:48.922768
1441	89	1	1	2	2025-03-06 14:46:06.427465
1442	89	1	4	6	2025-03-06 14:46:06.427471
1443	89	1	5	2	2025-03-06 14:46:06.427473
1444	89	1	6	0	2025-03-06 14:46:06.427474
1445	89	1	7	1	2025-03-06 14:46:06.427475
1446	89	1	8	4	2025-03-06 14:46:06.427476
1447	89	1	9	0	2025-03-06 14:46:06.427477
1448	89	1	10	1	2025-03-06 14:46:06.427478
1449	89	1	11	2	2025-03-06 14:46:06.427479
1450	89	1	12	4	2025-03-06 14:46:06.42748
1451	89	1	13	6	2025-03-06 14:46:06.427481
1452	89	1	14	0	2025-03-06 14:46:06.427482
1453	89	1	15	1	2025-03-06 14:46:06.427483
1454	89	1	16	2	2025-03-06 14:46:06.427485
1455	89	1	17	4	2025-03-06 14:46:06.427486
1456	89	1	18	6	2025-03-06 14:46:06.427487
1457	90	1	1	1	2025-03-06 14:54:17.129736
1458	90	1	4	2	2025-03-06 14:54:17.129745
1459	90	1	5	1	2025-03-06 14:54:17.129749
1460	90	1	6	1	2025-03-06 14:54:17.129753
1461	90	1	7	0	2025-03-06 14:54:17.129756
1462	90	1	8	0	2025-03-06 14:54:17.129759
1463	90	1	9	1	2025-03-06 14:54:17.129762
1464	90	1	10	2	2025-03-06 14:54:17.129765
1465	90	1	11	4	2025-03-06 14:54:17.129768
1466	90	1	12	0	2025-03-06 14:54:17.129771
1467	90	1	13	0	2025-03-06 14:54:17.129774
1468	90	1	14	0	2025-03-06 14:54:17.129777
1469	90	1	15	1	2025-03-06 14:54:17.12978
1470	90	1	16	0	2025-03-06 14:54:17.129783
1471	90	1	17	2	2025-03-06 14:54:17.129786
1472	90	1	18	4	2025-03-06 14:54:17.129789
1473	91	1	1	4	2025-03-07 14:09:28.360493
1474	91	1	4	2	2025-03-07 14:09:28.360515
1475	91	1	5	6	2025-03-07 14:09:28.360523
1476	91	1	6	0	2025-03-07 14:09:28.36053
1477	91	1	7	1	2025-03-07 14:09:28.360537
1478	91	1	8	4	2025-03-07 14:09:28.360544
1479	91	1	9	2	2025-03-07 14:09:28.360551
1480	91	1	10	0	2025-03-07 14:09:28.360557
1481	91	1	11	1	2025-03-07 14:09:28.360564
1482	91	1	12	6	2025-03-07 14:09:28.360571
1483	91	1	13	1	2025-03-07 14:09:28.360577
1484	91	1	14	4	2025-03-07 14:09:28.360584
1485	91	1	15	2	2025-03-07 14:09:28.36059
1486	91	1	16	6	2025-03-07 14:09:28.360596
1487	91	1	17	2	2025-03-07 14:09:28.360603
1488	91	1	18	4	2025-03-07 14:09:28.360609
1489	92	1	1	2	2025-03-08 10:14:05.311868
1490	92	1	4	6	2025-03-08 10:14:05.311871
1491	92	1	5	4	2025-03-08 10:14:05.311872
1492	92	1	6	2	2025-03-08 10:14:05.311872
1493	92	1	7	2	2025-03-08 10:14:05.311872
1494	92	1	8	4	2025-03-08 10:14:05.311873
1495	92	1	9	2	2025-03-08 10:14:05.311873
1496	92	1	10	2	2025-03-08 10:14:05.311874
1497	92	1	11	2	2025-03-08 10:14:05.311874
1498	92	1	12	1	2025-03-08 10:14:05.311874
1499	92	1	13	1	2025-03-08 10:14:05.311875
1500	92	1	14	4	2025-03-08 10:14:05.311875
1501	92	1	15	4	2025-03-08 10:14:05.311875
1502	92	1	16	4	2025-03-08 10:14:05.311876
1503	92	1	17	2	2025-03-08 10:14:05.311876
1504	92	1	18	1	2025-03-08 10:14:05.311876
1505	93	1	1	1	2025-03-12 18:18:08.63934
1506	93	1	4	4	2025-03-12 18:18:08.639362
1507	93	1	5	6	2025-03-12 18:18:08.63937
1508	93	1	6	2	2025-03-12 18:18:08.639377
1509	93	1	7	0	2025-03-12 18:18:08.639383
1510	93	1	8	1	2025-03-12 18:18:08.63939
1511	93	1	9	2	2025-03-12 18:18:08.639396
1512	93	1	10	6	2025-03-12 18:18:08.639402
1513	93	1	11	4	2025-03-12 18:18:08.639408
1514	93	1	12	0	2025-03-12 18:18:08.639415
1515	93	1	13	2	2025-03-12 18:18:08.639421
1516	93	1	14	4	2025-03-12 18:18:08.639427
1517	93	1	15	0	2025-03-12 18:18:08.639433
1518	93	1	16	1	2025-03-12 18:18:08.639439
1519	93	1	17	6	2025-03-12 18:18:08.639445
1520	93	1	18	0	2025-03-12 18:18:08.639452
1521	94	1	1	4	2025-03-12 19:19:42.849428
1522	94	1	4	1	2025-03-12 19:19:42.849453
1523	94	1	5	2	2025-03-12 19:19:42.849461
1524	94	1	6	1	2025-03-12 19:19:42.849469
1525	94	1	7	2	2025-03-12 19:19:42.849475
1526	94	1	8	6	2025-03-12 19:19:42.849482
1527	94	1	9	2	2025-03-12 19:19:42.849488
1528	94	1	10	1	2025-03-12 19:19:42.849495
1529	94	1	11	2	2025-03-12 19:19:42.849501
1530	94	1	12	4	2025-03-12 19:19:42.849567
1531	94	1	13	0	2025-03-12 19:19:42.849579
1532	94	1	14	1	2025-03-12 19:19:42.849587
1533	94	1	15	2	2025-03-12 19:19:42.849593
1534	94	1	16	4	2025-03-12 19:19:42.8496
1535	94	1	17	6	2025-03-12 19:19:42.849606
1536	94	1	18	0	2025-03-12 19:19:42.849613
1537	95	1	1	4	2025-03-12 19:33:54.504997
1538	95	1	4	6	2025-03-12 19:33:54.50502
1539	95	1	5	1	2025-03-12 19:33:54.505027
1540	95	1	6	2	2025-03-12 19:33:54.505034
1541	95	1	7	0	2025-03-12 19:33:54.505041
1542	95	1	8	2	2025-03-12 19:33:54.505047
1543	95	1	9	4	2025-03-12 19:33:54.505054
1544	95	1	10	6	2025-03-12 19:33:54.50506
1545	95	1	11	0	2025-03-12 19:33:54.505066
1546	95	1	12	4	2025-03-12 19:33:54.505073
1547	95	1	13	2	2025-03-12 19:33:54.50508
1548	95	1	14	6	2025-03-12 19:33:54.505086
1549	95	1	15	4	2025-03-12 19:33:54.505092
1550	95	1	16	6	2025-03-12 19:33:54.505098
1551	95	1	17	4	2025-03-12 19:33:54.505105
1552	95	1	18	6	2025-03-12 19:33:54.505111
1553	96	1	1	4	2025-03-12 20:28:39.669665
1554	96	1	4	0	2025-03-12 20:28:39.669684
1555	96	1	5	0	2025-03-12 20:28:39.669692
1556	96	1	6	1	2025-03-12 20:28:39.669699
1557	96	1	7	4	2025-03-12 20:28:39.669705
1558	96	1	8	6	2025-03-12 20:28:39.669712
1559	96	1	9	2	2025-03-12 20:28:39.669718
1560	96	1	10	0	2025-03-12 20:28:39.669725
1561	96	1	11	4	2025-03-12 20:28:39.669731
1562	96	1	12	6	2025-03-12 20:28:39.669738
1563	96	1	13	2	2025-03-12 20:28:39.669744
1564	96	1	14	6	2025-03-12 20:28:39.66975
1565	96	1	15	0	2025-03-12 20:28:39.669767
1566	96	1	16	1	2025-03-12 20:28:39.669773
1567	96	1	17	1	2025-03-12 20:28:39.66978
1568	96	1	18	1	2025-03-12 20:28:39.669786
1569	97	1	1	2	2025-03-12 21:22:31.272776
1570	97	1	4	6	2025-03-12 21:22:31.272799
1571	97	1	5	0	2025-03-12 21:22:31.272807
1572	97	1	6	6	2025-03-12 21:22:31.272814
1573	97	1	7	2	2025-03-12 21:22:31.27282
1574	97	1	8	0	2025-03-12 21:22:31.272827
1575	97	1	9	4	2025-03-12 21:22:31.272833
1576	97	1	10	2	2025-03-12 21:22:31.27284
1577	97	1	11	1	2025-03-12 21:22:31.272846
1578	97	1	12	6	2025-03-12 21:22:31.272852
1579	97	1	13	0	2025-03-12 21:22:31.272858
1580	97	1	14	4	2025-03-12 21:22:31.272865
1581	97	1	15	4	2025-03-12 21:22:31.272871
1582	97	1	16	2	2025-03-12 21:22:31.272877
1583	97	1	17	0	2025-03-12 21:22:31.272883
1584	97	1	18	1	2025-03-12 21:22:31.272889
\.


--
-- Data for Name: user_survey_type; Type: TABLE DATA; Schema: public; Owner: adminderik
--

COPY public.user_survey_type (id, user_id, created_at, survey_type) FROM stdin;
1	26	2024-11-18 12:21:40.315556	known_roles
2	27	2024-11-18 12:29:38.55615	known_roles
3	28	2024-11-28 17:23:14.969256	known_roles
4	29	2024-11-28 20:55:20.1611	unknown_roles
5	30	2024-11-28 21:05:38.907098	unknown_roles
6	31	2024-11-28 21:50:17.509405	unknown_roles
7	32	2024-11-28 21:54:37.977203	unknown_roles
8	33	2024-11-28 22:48:04.685242	known_roles
9	34	2024-11-28 22:50:38.3029	known_roles
10	35	2024-11-28 23:02:43.45587	known_roles
11	36	2024-11-28 23:05:06.730727	known_roles
12	37	2024-11-29 10:51:29.63166	unknown_roles
13	38	2024-12-01 15:53:13.81414	all_roles
14	39	2024-12-01 16:29:25.059679	all_roles
15	40	2024-12-01 16:56:35.472181	all_roles
16	41	2024-12-01 16:58:38.669849	all_roles
17	42	2024-12-01 17:05:05.794601	all_roles
18	43	2024-12-04 22:23:17.597503	all_roles
19	44	2024-12-04 22:37:15.489208	all_roles
20	45	2024-12-04 22:57:36.057534	all_roles
21	46	2024-12-05 11:17:44.063588	known_roles
22	47	2024-12-05 11:33:49.103542	all_roles
23	48	2024-12-05 11:38:35.078614	known_roles
24	49	2024-12-05 11:40:14.238714	all_roles
25	50	2024-12-05 15:09:17.750518	all_roles
26	51	2024-12-12 10:11:12.221694	known_roles
27	52	2024-12-30 17:40:59.329155	all_roles
28	53	2024-12-30 17:59:09.394537	all_roles
29	54	2024-12-30 18:11:21.833346	all_roles
30	55	2024-12-30 18:42:44.543996	all_roles
31	56	2024-12-30 19:00:57.460706	all_roles
32	57	2024-12-30 19:07:52.502989	all_roles
33	58	2024-12-30 23:22:00.817176	all_roles
34	59	2024-12-30 23:36:31.929232	all_roles
35	60	2024-12-30 23:42:37.341559	known_roles
36	61	2024-12-30 23:55:17.956334	known_roles
37	62	2024-12-31 00:00:35.149986	all_roles
38	63	2024-12-31 12:07:08.558251	known_roles
39	64	2024-12-31 17:40:59.410277	unknown_roles
40	65	2024-12-31 18:11:51.738398	unknown_roles
41	66	2025-01-03 20:10:34.123986	all_roles
42	67	2025-01-03 20:22:38.822202	known_roles
43	68	2025-01-05 13:29:26.382121	all_roles
44	69	2025-01-14 19:52:03.03306	known_roles
45	70	2025-01-14 20:06:32.729947	all_roles
46	71	2025-01-15 18:54:08.313623	known_roles
47	72	2025-01-15 18:56:47.210292	all_roles
48	73	2025-01-15 20:00:53.528723	unknown_roles
49	74	2025-01-16 02:33:31.703681	all_roles
50	75	2025-01-16 10:22:01.729348	known_roles
51	76	2025-01-16 14:57:49.863536	all_roles
52	77	2025-02-04 19:06:31.291007	known_roles
53	78	2025-02-17 23:29:41.547655	all_roles
54	79	2025-02-17 23:34:16.77913	known_roles
55	80	2025-02-17 23:36:05.959352	known_roles
56	81	2025-02-24 18:28:09.334252	all_roles
57	82	2025-03-01 11:06:27.225742	unknown_roles
58	83	2025-03-03 13:41:32.265202	all_roles
59	84	2025-03-05 15:35:46.139081	unknown_roles
60	85	2025-03-06 09:41:20.455208	known_roles
61	86	2025-03-06 10:26:32.567876	unknown_roles
62	87	2025-03-06 14:21:36.666705	unknown_roles
63	88	2025-03-06 14:22:48.678272	unknown_roles
64	89	2025-03-06 14:46:06.161087	known_roles
65	90	2025-03-06 14:54:16.928084	known_roles
66	91	2025-03-07 14:09:28.169455	unknown_roles
67	92	2025-03-08 10:14:05.19248	all_roles
68	93	2025-03-12 18:18:08.354648	all_roles
69	94	2025-03-12 19:19:42.579648	known_roles
70	95	2025-03-12 19:33:54.259386	unknown_roles
71	96	2025-03-12 20:28:39.240548	unknown_roles
72	97	2025-03-12 21:22:30.244436	all_roles
\.


--
-- Name: admin_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: adminderik
--

SELECT pg_catalog.setval('public.admin_user_id_seq', 1, true);


--
-- Name: app_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: adminderik
--

SELECT pg_catalog.setval('public.app_user_id_seq', 97, true);


--
-- Name: competency_id_seq; Type: SEQUENCE SET; Schema: public; Owner: adminderik
--

SELECT pg_catalog.setval('public.competency_id_seq', 18, true);


--
-- Name: competency_indicators_id_seq; Type: SEQUENCE SET; Schema: public; Owner: adminderik
--

SELECT pg_catalog.setval('public.competency_indicators_id_seq', 85, true);


--
-- Name: iso_activities_id_seq; Type: SEQUENCE SET; Schema: public; Owner: adminderik
--

SELECT pg_catalog.setval('public.iso_activities_id_seq', 109, true);


--
-- Name: iso_processes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: adminderik
--

SELECT pg_catalog.setval('public.iso_processes_id_seq', 30, true);


--
-- Name: iso_system_life_cycle_processes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: adminderik
--

SELECT pg_catalog.setval('public.iso_system_life_cycle_processes_id_seq', 4, true);


--
-- Name: iso_tasks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: adminderik
--

SELECT pg_catalog.setval('public.iso_tasks_id_seq', 459, true);


--
-- Name: new_survey_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: adminderik
--

SELECT pg_catalog.setval('public.new_survey_user_id_seq', 83, true);


--
-- Name: organization_id_seq; Type: SEQUENCE SET; Schema: public; Owner: adminderik
--

SELECT pg_catalog.setval('public.organization_id_seq', 12, true);


--
-- Name: process_competency_matrix_id_seq; Type: SEQUENCE SET; Schema: public; Owner: adminderik
--

SELECT pg_catalog.setval('public.process_competency_matrix_id_seq', 480, true);


--
-- Name: role_cluster_id_seq; Type: SEQUENCE SET; Schema: public; Owner: adminderik
--

SELECT pg_catalog.setval('public.role_cluster_id_seq', 14, true);


--
-- Name: role_competency_matrix_id_seq; Type: SEQUENCE SET; Schema: public; Owner: adminderik
--

SELECT pg_catalog.setval('public.role_competency_matrix_id_seq', 2912, true);


--
-- Name: role_process_matrix_id_seq; Type: SEQUENCE SET; Schema: public; Owner: adminderik
--

SELECT pg_catalog.setval('public.role_process_matrix_id_seq', 2100, true);


--
-- Name: unknown_role_competency_matrix_id_seq; Type: SEQUENCE SET; Schema: public; Owner: adminderik
--

SELECT pg_catalog.setval('public.unknown_role_competency_matrix_id_seq', 944, true);


--
-- Name: unknown_role_process_matrix_id_seq; Type: SEQUENCE SET; Schema: public; Owner: adminderik
--

SELECT pg_catalog.setval('public.unknown_role_process_matrix_id_seq', 1834, true);


--
-- Name: user_competency_survey_feedback_id_seq; Type: SEQUENCE SET; Schema: public; Owner: adminderik
--

SELECT pg_catalog.setval('public.user_competency_survey_feedback_id_seq', 76, true);


--
-- Name: user_se_competency_survey_results_id_seq; Type: SEQUENCE SET; Schema: public; Owner: adminderik
--

SELECT pg_catalog.setval('public.user_se_competency_survey_results_id_seq', 1584, true);


--
-- Name: user_survey_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: adminderik
--

SELECT pg_catalog.setval('public.user_survey_type_id_seq', 72, true);


--
-- Name: admin_user admin_user_pkey; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.admin_user
    ADD CONSTRAINT admin_user_pkey PRIMARY KEY (id);


--
-- Name: admin_user admin_user_username_key; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.admin_user
    ADD CONSTRAINT admin_user_username_key UNIQUE (username);


--
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: app_user app_user_pkey; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT app_user_pkey PRIMARY KEY (id);


--
-- Name: app_user app_user_username_key; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT app_user_username_key UNIQUE (username);


--
-- Name: competency_indicators competency_indicators_pkey; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.competency_indicators
    ADD CONSTRAINT competency_indicators_pkey PRIMARY KEY (id);


--
-- Name: competency competency_pkey; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.competency
    ADD CONSTRAINT competency_pkey PRIMARY KEY (id);


--
-- Name: iso_activities iso_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.iso_activities
    ADD CONSTRAINT iso_activities_pkey PRIMARY KEY (id);


--
-- Name: iso_processes iso_processes_pkey; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.iso_processes
    ADD CONSTRAINT iso_processes_pkey PRIMARY KEY (id);


--
-- Name: iso_system_life_cycle_processes iso_system_life_cycle_processes_pkey; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.iso_system_life_cycle_processes
    ADD CONSTRAINT iso_system_life_cycle_processes_pkey PRIMARY KEY (id);


--
-- Name: iso_tasks iso_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.iso_tasks
    ADD CONSTRAINT iso_tasks_pkey PRIMARY KEY (id);


--
-- Name: new_survey_user new_survey_user_pkey; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.new_survey_user
    ADD CONSTRAINT new_survey_user_pkey PRIMARY KEY (id);


--
-- Name: new_survey_user new_survey_user_username_key; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.new_survey_user
    ADD CONSTRAINT new_survey_user_username_key UNIQUE (username);


--
-- Name: organization organization_organization_name_key; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.organization
    ADD CONSTRAINT organization_organization_name_key UNIQUE (organization_name);


--
-- Name: organization organization_pkey; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.organization
    ADD CONSTRAINT organization_pkey PRIMARY KEY (id);


--
-- Name: organization organization_public_key_unique; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.organization
    ADD CONSTRAINT organization_public_key_unique UNIQUE (organization_public_key);


--
-- Name: process_competency_matrix process_competency_matrix_pkey; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.process_competency_matrix
    ADD CONSTRAINT process_competency_matrix_pkey PRIMARY KEY (id);


--
-- Name: process_competency_matrix process_competency_matrix_unique; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.process_competency_matrix
    ADD CONSTRAINT process_competency_matrix_unique UNIQUE (iso_process_id, competency_id);


--
-- Name: role_cluster role_cluster_pkey; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.role_cluster
    ADD CONSTRAINT role_cluster_pkey PRIMARY KEY (id);


--
-- Name: role_cluster role_cluster_role_cluster_name_key; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.role_cluster
    ADD CONSTRAINT role_cluster_role_cluster_name_key UNIQUE (role_cluster_name);


--
-- Name: role_competency_matrix role_competency_matrix_pkey; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.role_competency_matrix
    ADD CONSTRAINT role_competency_matrix_pkey PRIMARY KEY (id);


--
-- Name: role_competency_matrix role_competency_matrix_unique; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.role_competency_matrix
    ADD CONSTRAINT role_competency_matrix_unique UNIQUE (organization_id, role_cluster_id, competency_id);


--
-- Name: role_process_matrix role_process_matrix_pkey; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.role_process_matrix
    ADD CONSTRAINT role_process_matrix_pkey PRIMARY KEY (id);


--
-- Name: role_process_matrix role_process_matrix_unique; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.role_process_matrix
    ADD CONSTRAINT role_process_matrix_unique UNIQUE (organization_id, role_cluster_id, iso_process_id);


--
-- Name: competency unique_competency; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.competency
    ADD CONSTRAINT unique_competency UNIQUE (competency_area, competency_name);


--
-- Name: unknown_role_competency_matrix unknown_role_competency_matrix_pkey; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.unknown_role_competency_matrix
    ADD CONSTRAINT unknown_role_competency_matrix_pkey PRIMARY KEY (id);


--
-- Name: unknown_role_competency_matrix unknown_role_competency_matrix_unique; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.unknown_role_competency_matrix
    ADD CONSTRAINT unknown_role_competency_matrix_unique UNIQUE (organization_id, user_name, competency_id);


--
-- Name: unknown_role_process_matrix unknown_role_process_matrix_pkey; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.unknown_role_process_matrix
    ADD CONSTRAINT unknown_role_process_matrix_pkey PRIMARY KEY (id);


--
-- Name: unknown_role_process_matrix unknown_role_process_matrix_unique; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.unknown_role_process_matrix
    ADD CONSTRAINT unknown_role_process_matrix_unique UNIQUE (organization_id, iso_process_id, user_name);


--
-- Name: user_competency_survey_feedback user_competency_survey_feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.user_competency_survey_feedback
    ADD CONSTRAINT user_competency_survey_feedback_pkey PRIMARY KEY (id);


--
-- Name: user_role_cluster user_role_cluster_pkey; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.user_role_cluster
    ADD CONSTRAINT user_role_cluster_pkey PRIMARY KEY (user_id, role_cluster_id);


--
-- Name: user_se_competency_survey_results user_se_competency_survey_results_pkey; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.user_se_competency_survey_results
    ADD CONSTRAINT user_se_competency_survey_results_pkey PRIMARY KEY (id);


--
-- Name: user_survey_type user_survey_type_pkey; Type: CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.user_survey_type
    ADD CONSTRAINT user_survey_type_pkey PRIMARY KEY (id);


--
-- Name: new_survey_user before_insert_new_survey_user; Type: TRIGGER; Schema: public; Owner: adminderik
--

CREATE TRIGGER before_insert_new_survey_user BEFORE INSERT ON public.new_survey_user FOR EACH ROW EXECUTE FUNCTION public.set_username();


--
-- Name: app_user app_user_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT app_user_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(id);


--
-- Name: competency_indicators competency_indicators_competency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.competency_indicators
    ADD CONSTRAINT competency_indicators_competency_id_fkey FOREIGN KEY (competency_id) REFERENCES public.competency(id) ON DELETE CASCADE;


--
-- Name: iso_activities iso_activities_process_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.iso_activities
    ADD CONSTRAINT iso_activities_process_id_fkey FOREIGN KEY (process_id) REFERENCES public.iso_processes(id);


--
-- Name: iso_processes iso_processes_life_cycle_process_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.iso_processes
    ADD CONSTRAINT iso_processes_life_cycle_process_id_fkey FOREIGN KEY (life_cycle_process_id) REFERENCES public.iso_system_life_cycle_processes(id);


--
-- Name: iso_tasks iso_tasks_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.iso_tasks
    ADD CONSTRAINT iso_tasks_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.iso_activities(id);


--
-- Name: process_competency_matrix process_competency_matrix_competency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.process_competency_matrix
    ADD CONSTRAINT process_competency_matrix_competency_id_fkey FOREIGN KEY (competency_id) REFERENCES public.competency(id) ON DELETE CASCADE;


--
-- Name: process_competency_matrix process_competency_matrix_iso_process_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.process_competency_matrix
    ADD CONSTRAINT process_competency_matrix_iso_process_id_fkey FOREIGN KEY (iso_process_id) REFERENCES public.iso_processes(id) ON DELETE CASCADE;


--
-- Name: role_competency_matrix role_competency_matrix_competency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.role_competency_matrix
    ADD CONSTRAINT role_competency_matrix_competency_id_fkey FOREIGN KEY (competency_id) REFERENCES public.competency(id);


--
-- Name: role_competency_matrix role_competency_matrix_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.role_competency_matrix
    ADD CONSTRAINT role_competency_matrix_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: role_competency_matrix role_competency_matrix_role_cluster_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.role_competency_matrix
    ADD CONSTRAINT role_competency_matrix_role_cluster_id_fkey FOREIGN KEY (role_cluster_id) REFERENCES public.role_cluster(id);


--
-- Name: role_process_matrix role_process_matrix_iso_process_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.role_process_matrix
    ADD CONSTRAINT role_process_matrix_iso_process_id_fkey FOREIGN KEY (iso_process_id) REFERENCES public.iso_processes(id) ON DELETE CASCADE;


--
-- Name: role_process_matrix role_process_matrix_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.role_process_matrix
    ADD CONSTRAINT role_process_matrix_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: role_process_matrix role_process_matrix_role_cluster_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.role_process_matrix
    ADD CONSTRAINT role_process_matrix_role_cluster_id_fkey FOREIGN KEY (role_cluster_id) REFERENCES public.role_cluster(id) ON DELETE CASCADE;


--
-- Name: unknown_role_competency_matrix unknown_role_competency_matrix_competency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.unknown_role_competency_matrix
    ADD CONSTRAINT unknown_role_competency_matrix_competency_id_fkey FOREIGN KEY (competency_id) REFERENCES public.competency(id);


--
-- Name: unknown_role_competency_matrix unknown_role_competency_matrix_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.unknown_role_competency_matrix
    ADD CONSTRAINT unknown_role_competency_matrix_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: unknown_role_process_matrix unknown_role_process_matrix_iso_process_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.unknown_role_process_matrix
    ADD CONSTRAINT unknown_role_process_matrix_iso_process_id_fkey FOREIGN KEY (iso_process_id) REFERENCES public.iso_processes(id) ON DELETE CASCADE;


--
-- Name: unknown_role_process_matrix unknown_role_process_matrix_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.unknown_role_process_matrix
    ADD CONSTRAINT unknown_role_process_matrix_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: user_competency_survey_feedback user_competency_survey_feedback_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.user_competency_survey_feedback
    ADD CONSTRAINT user_competency_survey_feedback_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: user_competency_survey_feedback user_competency_survey_feedback_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.user_competency_survey_feedback
    ADD CONSTRAINT user_competency_survey_feedback_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.app_user(id) ON DELETE CASCADE;


--
-- Name: user_role_cluster user_role_cluster_role_cluster_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.user_role_cluster
    ADD CONSTRAINT user_role_cluster_role_cluster_id_fkey FOREIGN KEY (role_cluster_id) REFERENCES public.role_cluster(id) ON DELETE CASCADE;


--
-- Name: user_role_cluster user_role_cluster_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.user_role_cluster
    ADD CONSTRAINT user_role_cluster_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.app_user(id) ON DELETE CASCADE;


--
-- Name: user_se_competency_survey_results user_se_competency_survey_results_competency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.user_se_competency_survey_results
    ADD CONSTRAINT user_se_competency_survey_results_competency_id_fkey FOREIGN KEY (competency_id) REFERENCES public.competency(id) ON DELETE CASCADE;


--
-- Name: user_se_competency_survey_results user_se_competency_survey_results_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.user_se_competency_survey_results
    ADD CONSTRAINT user_se_competency_survey_results_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: user_se_competency_survey_results user_se_competency_survey_results_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.user_se_competency_survey_results
    ADD CONSTRAINT user_se_competency_survey_results_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.app_user(id) ON DELETE CASCADE;


--
-- Name: user_survey_type user_survey_metadata_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: adminderik
--

ALTER TABLE ONLY public.user_survey_type
    ADD CONSTRAINT user_survey_metadata_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.app_user(id) ON DELETE CASCADE;


--
-- Name: FUNCTION pg_replication_origin_advance(text, pg_lsn); Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: FUNCTION pg_replication_origin_create(text); Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: FUNCTION pg_replication_origin_drop(text); Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: FUNCTION pg_replication_origin_oid(text); Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: FUNCTION pg_replication_origin_progress(text, boolean); Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: FUNCTION pg_replication_origin_session_is_setup(); Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: FUNCTION pg_replication_origin_session_progress(boolean); Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: FUNCTION pg_replication_origin_session_reset(); Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: FUNCTION pg_replication_origin_session_setup(text); Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: FUNCTION pg_replication_origin_xact_reset(); Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: FUNCTION pg_replication_origin_xact_setup(pg_lsn, timestamp with time zone); Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: FUNCTION pg_show_replication_origin_status(OUT local_id oid, OUT external_id text, OUT remote_lsn pg_lsn, OUT local_lsn pg_lsn); Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: FUNCTION pg_stat_reset(); Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: FUNCTION pg_stat_reset_shared(text); Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: FUNCTION pg_stat_reset_single_function_counters(oid); Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: FUNCTION pg_stat_reset_single_table_counters(oid); Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_config.name; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_config.setting; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_hba_file_rules.line_number; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_hba_file_rules.type; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_hba_file_rules.database; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_hba_file_rules.user_name; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_hba_file_rules.address; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_hba_file_rules.netmask; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_hba_file_rules.auth_method; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_hba_file_rules.options; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_hba_file_rules.error; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_replication_origin_status.local_id; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_replication_origin_status.external_id; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_replication_origin_status.remote_lsn; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_replication_origin_status.local_lsn; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_shmem_allocations.name; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_shmem_allocations.off; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_shmem_allocations.size; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_shmem_allocations.allocated_size; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.starelid; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.staattnum; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.stainherit; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.stanullfrac; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.stawidth; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.stadistinct; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.stakind1; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.stakind2; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.stakind3; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.stakind4; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.stakind5; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.staop1; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.staop2; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.staop3; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.staop4; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.staop5; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.stacoll1; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.stacoll2; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.stacoll3; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.stacoll4; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.stacoll5; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.stanumbers1; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.stanumbers2; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.stanumbers3; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.stanumbers4; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.stanumbers5; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.stavalues1; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.stavalues2; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.stavalues3; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.stavalues4; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_statistic.stavalues5; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_subscription.oid; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_subscription.subdbid; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_subscription.subname; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_subscription.subowner; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_subscription.subenabled; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_subscription.subconninfo; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_subscription.subslotname; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_subscription.subsynccommit; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- Name: COLUMN pg_subscription.subpublications; Type: ACL; Schema: pg_catalog; Owner: azuresu
--



--
-- PostgreSQL database dump complete
--

