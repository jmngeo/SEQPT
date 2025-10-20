select * from role_cluster rc 
INSERT INTO role_cluster (role_cluster_name, role_cluster_description) VALUES 
('Customer', 'Represents the party that orders or uses a service (e.g., development order). The customer has influence on the design/technical execution of the system.');


INSERT INTO role_cluster (role_cluster_name, role_cluster_description) VALUES 
('Customer', 'Represents the party that orders or uses a service (e.g., development order). The customer has influence on the design/technical execution of the system.');

INSERT INTO role_cluster (role_cluster_name, role_cluster_description) VALUES 
('Customer Representative', 'Forms the interface between the customer and the company. The roles in this cluster form the voice for all customer-relevant information required for the project.');

INSERT INTO role_cluster (role_cluster_name, role_cluster_description) VALUES 
('Project Manager', 'Is responsible for the planning and coordination on the project side. The roles assume responsibility for achieving the project goals and monitoring the resources (time, costs, personnel) within a time-limited framework and also have a moderating role in conflicts and disputes.');

INSERT INTO role_cluster (role_cluster_name, role_cluster_description) VALUES 
('System Developer', 'Has the overview from requirements to the decomposition of the system to the interfaces and the associated system elements (external to the system environment and internal between the elements). The system developer is responsible for integration planning and consults with the appropriate subject matter experts.');

INSERT INTO role_cluster (role_cluster_name, role_cluster_description) VALUES 
('Specialist Developer', 'Includes the various specialist areas, e.g., software, hardware, etc. They develop new technologies or realize the product/system on the basis of specifications from the system developer cluster.');

INSERT INTO role_cluster (role_cluster_name, role_cluster_description) VALUES 
('Production Planner/Coordinator', 'Takes on the preparation of the product realization and the transfer to the customer.');

INSERT INTO role_cluster (role_cluster_name, role_cluster_description) VALUES 
('Production Employee', 'Comprises the processes that are to be assigned to the implementation, assembly, and manufacture of the product through to goods issue and shipping. The individual system components are integrated into the overall system and verified with regard to their functionality.');

INSERT INTO role_cluster (role_cluster_name, role_cluster_description) VALUES 
('Quality Engineer/Manager', 'Ensures that the company''s quality standards are maintained in order to keep customer satisfaction high and ensure long-term competitiveness in the market. Close cooperation with the V&V operator, e.g., for the analysis of customer complaints and identification of the cause.');

INSERT INTO role_cluster (role_cluster_name, role_cluster_description) VALUES 
('Verification and Validation (V&V) Operator', 'Covers the topics of system verification & validation. The involvement of this role cluster in the early phases of system development can ensure that the system is verifiable and validatable.');

INSERT INTO role_cluster (role_cluster_name, role_cluster_description) VALUES 
('Service Technician', 'Deals with all service-related tasks at the customer''s site, i.e., installation, commissioning, professional training of users, as well as classic service tasks such as maintenance and repairs, or the area of after-sales.');

INSERT INTO role_cluster (role_cluster_name, role_cluster_description) VALUES 
('Process and Policy Manager', 'Is divided into a strategic and an operational level: On a strategic level, the process owner serves to develop internal guidelines in the development and creation or revision of process flows. On an operational level, the policy owner controls compliance with policies, laws, and framework conditions that must be taken into account and fulfilled.');

INSERT INTO role_cluster (role_cluster_name, role_cluster_description) VALUES 
('Internal Support', 'Represents the advisory and supporting side during the development process within the project. A distinction is made between: - IT support: IT support provides and maintains the necessary IT infrastructure. - Qualification support: On the one hand, this provides support in the area of methods and, on the other hand, the qualification of the employees is individually ensured by means of specialized training. This can be done by the HR department, which also supports the project by acquiring suitable employees. - Systems Engineering (SE) support: The SE support offers separate support with regard to SE methods and handling of SE tools. This offers assistance in order to impart the necessary knowledge in the SE procedure.');

INSERT INTO role_cluster (role_cluster_name, role_cluster_description) VALUES 
('Innovation Management', 'Focuses on the commercially successful implementation of products or services, but also new business models or processes.');

INSERT INTO role_cluster (role_cluster_name, role_cluster_description) VALUES 
('Management', 'Forms the group of decision-makers and is represented by the management or department management. The cluster keeps an eye on the company''s goals, visions, and values. Since the opinion of the cluster is crucial for project progress, management is an important stakeholder in every respect.');

commit

select * from iso_processes order by name

select * from role_cluster 


select * from competency c 
delete from competency where id=3
truncate table competency restart identity; 

select * from competency_indicators ci 

DROP TABLE IF EXISTS public.role_process_matrix;


CREATE TABLE public.role_process_matrix (
    id serial4 PRIMARY KEY,
    role_cluster_id int4 NOT NULL,
    iso_process_id int4 NOT NULL,
    role_process_value int4 DEFAULT -100 CHECK (role_process_value IN (-100, 0, 1, 2)),
    CONSTRAINT role_process_matrix_role_cluster_id_fkey FOREIGN KEY (role_cluster_id) REFERENCES public.role_cluster(id) ON DELETE CASCADE,
    CONSTRAINT role_process_matrix_iso_process_id_fkey FOREIGN KEY (iso_process_id) REFERENCES public.iso_processes(id) ON DELETE CASCADE,
    CONSTRAINT role_process_matrix_unique UNIQUE (role_cluster_id, iso_process_id)
);

select * from public.role_process_matrix

DROP TABLE IF EXISTS public.process_competency_matrix;

CREATE TABLE public.process_competency_matrix (
    id serial4 PRIMARY KEY,
    iso_process_id int4 NOT NULL,
    competency_id int4 NOT NULL,
    relevance_value int4 DEFAULT -100 CHECK (relevance_value IN (-100, 0, 1, 2)),
    CONSTRAINT process_competency_matrix_iso_process_id_fkey FOREIGN KEY (iso_process_id) REFERENCES public.iso_processes(id) ON DELETE CASCADE,
    CONSTRAINT process_competency_matrix_competency_id_fkey FOREIGN KEY (competency_id) REFERENCES public.competency(id) ON DELETE CASCADE,
    CONSTRAINT process_competency_matrix_unique UNIQUE (iso_process_id, competency_id)
);

select * from public.process_competency_matrix
truncate table public.process_competency_matrix


CREATE TABLE public.role_competency_matrix (
    id serial4 PRIMARY KEY,
    role_cluster_id int4 NOT NULL,
    competency_id int4 NOT NULL,
    role_competency_value int4 NOT NULL CHECK (role_competency_value IN (0, 1, 2, 3, 4, 6)),
    CONSTRAINT role_competency_matrix_role_cluster_id_fkey FOREIGN KEY (role_cluster_id) REFERENCES public.role_cluster(id),
    CONSTRAINT role_competency_matrix_competency_id_fkey FOREIGN KEY (competency_id) REFERENCES public.competency(id),
    CONSTRAINT role_competency_matrix_unique UNIQUE (role_cluster_id, competency_id)
);



CREATE OR REPLACE FUNCTION refresh_role_competency_matrix() RETURNS VOID AS $$
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
$$ LANGUAGE plpgsql;


select * from role_process_matrix


ALTER TABLE public.competency
ALTER COLUMN description DROP NOT NULL,
ALTER COLUMN why_it_matters DROP NOT NULL;




CREATE OR REPLACE PROCEDURE update_role_competency_matrix()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Step 1: Truncate the role_competency_matrix table to clear previous entries
    TRUNCATE TABLE public.role_competency_matrix RESTART IDENTITY;

    -- Step 2: Insert calculated role-competency relationships into the matrix
    INSERT INTO public.role_competency_matrix (role_cluster_id, competency_id, competency_level)
    SELECT
        rpm.role_cluster_id,
        pcm.competency_id,
        MAX(
            CASE
                -- Mapping of combined values to competency levels
                WHEN rpm.role_process_value = 0 OR pcm.relevance_value = 0 THEN 0 -- "nicht relevant"
                WHEN rpm.role_process_value = 1 AND pcm.relevance_value IN (1, 2) THEN 1 -- "anwenden"
                WHEN rpm.role_process_value = 2 AND pcm.relevance_value IN (1, 2) THEN 2 -- "verstehen"
                WHEN rpm.role_process_value = 3 AND pcm.relevance_value IN (1, 2) THEN 6 -- "beherrschen"
                ELSE 0 -- Default to "nicht relevant"
            END
        ) AS competency_level
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





CREATE OR REPLACE PROCEDURE update_role_competency_matrix()
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



DROP TABLE IF EXISTS public.process_competency_matrix CASCADE;

CREATE TABLE public.process_competency_matrix (
    id serial4 NOT NULL,
    iso_process_id int4 NOT NULL,
    competency_id int4 NOT NULL,
    process_competency_value int4 DEFAULT '-100'::integer NULL,  -- Renamed from relevance_value
    CONSTRAINT process_competency_matrix_pkey PRIMARY KEY (id),
    CONSTRAINT process_competency_matrix_process_competency_value_check CHECK ((process_competency_value = ANY (ARRAY['-100'::integer, 0, 1, 2]))),
    CONSTRAINT process_competency_matrix_unique UNIQUE (iso_process_id, competency_id),
    CONSTRAINT process_competency_matrix_competency_id_fkey FOREIGN KEY (competency_id) REFERENCES public.competency(id) ON DELETE CASCADE,
    CONSTRAINT process_competency_matrix_iso_process_id_fkey FOREIGN KEY (iso_process_id) REFERENCES public.iso_processes(id) ON DELETE CASCADE
);


DROP TABLE IF EXISTS public.role_competency_matrix;

CREATE TABLE public.role_competency_matrix (
    id serial4 NOT NULL,
    role_cluster_id int4 NOT NULL,
    competency_id int4 NOT NULL,
    role_competency_value int4 DEFAULT '-100'::integer NOT NULL,
    CONSTRAINT role_competency_matrix_pkey PRIMARY KEY (id),
    CONSTRAINT role_competency_matrix_role_competency_value_check CHECK (
        role_competency_value = ANY (ARRAY[-100, 0, 1, 2, 3, 4, 6])
    ),
    CONSTRAINT role_competency_matrix_unique UNIQUE (role_cluster_id, competency_id),
    CONSTRAINT role_competency_matrix_competency_id_fkey FOREIGN KEY (competency_id) REFERENCES public.competency(id),
    CONSTRAINT role_competency_matrix_role_cluster_id_fkey FOREIGN KEY (role_cluster_id) REFERENCES public.role_cluster(id)
);


truncate table role_process_matrix  restart identity;


select rpm.*,rc.role_cluster_name,ip."name" 
from public.role_process_matrix rpm join role_cluster rc on rc.id=rpm.role_cluster_id join iso_processes ip on rpm.iso_process_id =ip.id
where role_process_value !=0

select * from role_process_matrix where role_cluster_id  not in (select id from role_cluster rc)

select * from role_cluster rc 

update role_cluster set role_cluster_name ='System Engineer' where role_cluster_name ='System Developer'



CALL update_role_competency_matrix();

SELECT 
    rc.role_cluster_name, 
    c.competency_name,
    rcm.role_competency_value 
FROM 
    role_competency_matrix rcm
JOIN 
    competency c ON rcm.competency_id = c.id
JOIN 
    role_cluster rc ON rcm.role_cluster_id = rc.id 
WHERE 
    rc.role_cluster_name = 'Internal Support'
ORDER BY 
    CASE c.competency_name
        WHEN 'Systems Thinking' THEN 1
        WHEN 'Systems Modeling and Analysis' THEN 2
        WHEN 'Lifecycle Consideration' THEN 3
        WHEN 'Customer / Value Orientation' THEN 4
        WHEN 'Requirements Definition' THEN 5
        WHEN 'System Architecting' THEN 6
        WHEN 'Integration, Verification,  Validation' THEN 7
        WHEN 'Operation and Support' THEN 8
        WHEN 'Agile Methods' THEN 9
        WHEN 'Self-Organization' THEN 10
        WHEN 'Communication' THEN 11
        WHEN 'Leadership' THEN 12
        WHEN 'Project Management' THEN 13
        WHEN 'Decision Management' THEN 14
        WHEN 'Information Management' THEN 15
        WHEN 'Configuration Management' THEN 16
    END;
   
   
  select * from competency c 
  
  
      SELECT
        rpm.role_cluster_id,
        pcm.competency_id,
        pcm.iso_process_id ,
        rpm.role_process_value,
        pcm.process_competency_value,
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
         AS role_competency_value
    FROM
        public.role_process_matrix rpm
    JOIN
        public.process_competency_matrix pcm
    ON
        rpm.iso_process_id = pcm.iso_process_id where rpm.role_cluster_id =13
        and pcm.competency_id =8
        
 select * from iso_processes ip where id=5 --Portfolio management process:2
 select * from competency  where id= 8 --Leadership:2
 
     
CREATE TABLE public.organization (
    id serial PRIMARY KEY,  -- Unique identifier for each organization
    organization_name varchar(255) NOT NULL UNIQUE  -- Name of the organization, must be unique
);

drop table public.user       

CREATE TABLE "app_user" (
    id SERIAL PRIMARY KEY,
    organization_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    username VARCHAR(255) UNIQUE NOT NULL,
    role_cluster_id INT NULL,
    tasks_responsibilities TEXT,
    FOREIGN KEY (organization_id) REFERENCES organization(id),
    FOREIGN KEY (role_cluster_id) REFERENCES role_cluster(id)
);


drop table user_score

CREATE TABLE user_score (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    competency_id INT NOT NULL,
    competency_level INT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES "app_user"(id),
    FOREIGN KEY (competency_id) REFERENCES competency(id),
    CONSTRAINT user_score_unique UNIQUE (user_id, competency_id)
);

select * from public.user 


select * from competency c  

Forms the interface between the customer and the company. The roles in this cluster form the voice for all customer-relevant information required for the project.


select * from role_competency_matrix where role_competency_value in (1,2,3,4,6) and competency_id = 

select rcm.competency_id , c.competency_name, rcm.role_competency_value ,rc.role_cluster_name from role_competency_matrix rcm join role_cluster rc 
on rcm.role_cluster_id =rc.id join competency c  on rcm.competency_id =c.id  




select * from competency c 


select * from organization o 


-- Add the column to role_process_matrix with a default value of 1
ALTER TABLE public.role_process_matrix
ADD COLUMN organization_id INT NOT NULL DEFAULT 1;

-- Add a foreign key constraint to link to the organization table
ALTER TABLE public.role_process_matrix
ADD CONSTRAINT role_process_matrix_organization_id_fkey 
FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;

-- Update the unique constraint to include organization_id
ALTER TABLE public.role_process_matrix
DROP CONSTRAINT role_process_matrix_unique,
ADD CONSTRAINT role_process_matrix_unique 
UNIQUE (organization_id, role_cluster_id, iso_process_id);

-- now how to remove the default 1 from rpm?

-- Add the column to role_competency_matrix with a default value of 1
ALTER TABLE public.role_competency_matrix
ADD COLUMN organization_id INT NOT NULL DEFAULT 1;

-- Add a foreign key constraint to link to the organization table
ALTER TABLE public.role_competency_matrix
ADD CONSTRAINT role_competency_matrix_organization_id_fkey 
FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;

-- Update the unique constraint to include organization_id
ALTER TABLE public.role_competency_matrix
DROP CONSTRAINT role_competency_matrix_unique,
ADD CONSTRAINT role_competency_matrix_unique 
UNIQUE (organization_id, role_cluster_id, competency_id);


-- Remove default value for organization_id after updating existing records
ALTER TABLE public.role_process_matrix
ALTER COLUMN organization_id DROP DEFAULT;

-- Remove default value for organization_id after updating existing records
ALTER TABLE public.role_competency_matrix
ALTER COLUMN organization_id DROP DEFAULT;


select * from role_competency_matrix


ALTER TABLE public.organization
ADD COLUMN organization_public_key VARCHAR(50) NOT null default 'singleuser';


select * from role_process_matrix
commit

ALTER TABLE public.organization
ADD CONSTRAINT organization_public_key_unique UNIQUE (organization_public_key);



CREATE OR REPLACE PROCEDURE insert_new_org_default_role_process_matrix(_organization_id INT)
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

CALL insert_new_org_default_role_process_matrix(3);


CREATE OR REPLACE PROCEDURE insert_new_org_default_role_competency_matrix(_organization_id INT)
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

CALL insert_new_org_default_role_competency_matrix(10);

select role_cluster_id,competency_id,role_competency_value,count(1) from role_competency_matrix
group by role_cluster_id,competency_id,role_competency_value


select role_cluster_id,iso_process_id,role_process_value,count(1) 
from role_process_matrix 
group by role_cluster_id,iso_process_id,role_process_value


select distinct organization_id 
from role_process_matrix rpm  


CALL insert_new_org_default_role_process_matrix(8);
CALL insert_new_org_default_role_competency_matrix(8);

select * from organization o 

where rc.role_cluster_name = 'System Engineer'


CREATE OR REPLACE PROCEDURE public.update_role_competency_matrix(_organization_id INT)
LANGUAGE plpgsql
AS $procedure$
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

END $procedure$;

select role_cluster_id,iso_process_id,role_process_value,count(1) from role_process_matrix rpm 
group by 
role_cluster_id,iso_process_id,role_process_value 

select id,competency_name from competency


CREATE TABLE public.competency_indicators_backup01112024 AS TABLE public.competency_indicators;

TRUNCATE TABLE public.competency_indicators RESTART IDENTITY;

select * from competency_indicators_backup01112024


-- Rename the existing column from "indicator" to "indicator_en"
ALTER TABLE public.competency_indicators RENAME COLUMN indicator TO indicator_en;

-- Add a new column for the German indicator
ALTER TABLE public.competency_indicators ADD COLUMN indicator_de text;


select distinct level
from competency_indicators

select * from role_cluster rc 

select competency_id,max(role_competency_value) from role_competency_matrix where role_cluster_id in (4,12) and organization_id in (1) group by competency_id 
order by competency_id 


select competency_id,level,count(1) from competency_indicators group by competency_id,level


CREATE TABLE user_se_competency_survey_results (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES app_user(id) ON DELETE CASCADE,
    organization_id INTEGER REFERENCES organization(id) ON DELETE CASCADE,
    competency_id INTEGER REFERENCES competency(id) ON DELETE CASCADE,
    score INTEGER NOT NULL,
    submitted_at TIMESTAMP DEFAULT NOW()
);

truncate table app_user restart identity cascade; 

ALTER TABLE app_user
ALTER COLUMN tasks_responsibilities
SET DATA TYPE JSONB
USING tasks_responsibilities::JSONB;

drop table user_score 

select * from user_se_competency_survey_results
select * from app_user
truncate table user_se_competency_survey_results restart identity cascade

truncate table app_user restart identity cascade

ALTER TABLE public.app_user
alter column role_cluster_id
SET DATA TYPE JSONB null
USING role_cluster_id::JSONB;
   select * from app_user au 
   
   
   select * from app_user au 
   
   select * from user_role_cluster
   
   select * from user_se_competency_survey_results uscsr 
   
   
   ALTER TABLE public.app_user
ALTER COLUMN role_cluster_id SET DATA TYPE JSONB USING to_jsonb(array[role_cluster_id]);



CREATE TABLE user_role_cluster (
    user_id INTEGER NOT NULL,
    role_cluster_id INTEGER NOT NULL,
    PRIMARY KEY (user_id, role_cluster_id),
    FOREIGN KEY (user_id) REFERENCES app_user(id) ON DELETE CASCADE,
    FOREIGN KEY (role_cluster_id) REFERENCES role_cluster(id) ON DELETE CASCADE
);

ALTER TABLE public.app_user DROP COLUMN role_cluster_id;



select * from user_se_competency_survey_results where user_id =1 and organization_id =1



select * from user_role_cluster

select competency_id,max(role_competency_value) from role_competency_matrix where organization_id=1 
and role_cluster_id in (select role_cluster_id from user_role_cluster where user_id=5)
group by competency_id order by competency_id 


select * from app_user au 

select * from competency_indicators

select * from user_se_competency_survey_results order by submitted_at  desc
case 
	when sr.score = 0 then 'Not Aware'
	when sr.score = 1 then 'knowing'
	when sr.score = 2 then 'understanding'
	when sr.score = 4 then 'Applying'
	when sr.score = 6 then 'Mastering'
end as user_recorded_competency_level,
case 
	when sr.score = 0 then 'Not Aware'
	when sr.score = 1 then 'kennen'
	when sr.score = 2 then 'verstehen'
	when sr.score = 4 then 'anwenden'
	when sr.score = 6 then 'beherrschen'
end as competency_indicator_key

case 
	when max(role_competency_value) = 0 then 'Not Aware'
	when max(role_competency_value) = 1 then 'knowing'
	when max(role_competency_value) = 2 then 'understanding'
	when max(role_competency_value) = 4 then 'Applying'
	when max(role_competency_value) = 6 then 'Mastering'
end as user_required_competency,
case 
	when max(role_competency_value) = 0 then 'Not Aware'
	when max(role_competency_value) = 1 then 'kennen'
	when max(role_competency_value) = 2 then 'verstehen'
	when max(role_competency_value) = 4 then 'anwenden'
	when max(role_competency_value) = 6 then 'beherrschen'
end as competency_indicator_key



with recorded_competencies as
(
select sr.competency_id, c.competency_area, c.competency_name,
sr.score  as user_score
from user_se_competency_survey_results sr 
left join competency c on sr.competency_id=c.id 
where sr.user_id =16 
),
required_competencies as
(
select competency_id,max(role_competency_value) as max_score
from role_competency_matrix where organization_id =1 and role_cluster_id
in (select role_cluster_id from user_role_cluster where user_id=16) group by competency_id
),
required_vs_recorded as 
(
select rec.*,req.max_score from recorded_competencies rec left join required_competencies req on rec.competency_id=req.competency_id
),
competency_indicators_with_score as 
(
select competency_id,"level",
case 
	when "level"='kennen' then 1
	when "level"='verstehen' then 2
	when "level"='anwenden' then 4
	when "level"='beherrschen' then 6
end
as level_assigned_score,
string_agg(indicator_en, '. ') as indicator_en from competency_indicators group by competency_id,"level"
),
required_vs_recorded_with_indicators_joined_by_req as 
(
select rr.*,i.level as recorded_level,i.indicator_en as recorded_level_indicators from  required_vs_recorded rr left join competency_indicators_with_score i on rr.competency_id=i.competency_id and 
rr.user_score=i.level_assigned_score
), 
required_vs_recorded_with_indicators_joined_by_req_joined_by_rec as
(
select rr.*,i.level as required_level,i.indicator_en as required_level_indicators from  required_vs_recorded_with_indicators_joined_by_req rr left join competency_indicators_with_score i 
on rr.competency_id=i.competency_id and 
rr.max_score=i.level_assigned_score
)
select competency_area,competency_name,coalesce (recorded_level,'unwissend') as user_recorded_level, coalesce (recorded_level_indicators,'You are unaware or lacks knowledge in this competency area') as user_recorded_level_competency_indicator, required_level as user_required_level,
required_level_indicators as user_required_level_competency_indicator
from required_vs_recorded_with_indicators_joined_by_req_joined_by_rec
except
SELECT * FROM get_competency_results(16, 1)


required_competencies as
(

)





recorded_competencies_with_indicators as 
(
select rc.*,ci.indicator_en from recorded_competencies as rc
left join competency_indicators ci 
on rc.competency_indicator_key=ci.level and rc.competency_id=ci.competency_id
),
recorded_preprocessed as 
(
select competency_id,competency_area,competency_name,user_score,user_recorded_competency_level,competency_indicator_key,
STRING_AGG(indicator_en,'. ')
from recorded_competencies_with_indicators
group by competency_id,competency_area,competency_name,user_score,user_recorded_competency_level,competency_indicator_key
)
select * from recorded_preprocessed
,
,
indicators as 
(
select * from competency_indicators
),
report_1 as
(
select recorded.competency_area,recorded.competency_name,recorded.user_recorded_competency_level,
required.user_required_competency, indicators.indicator_en as user_required_competency_indicator
from recorded_competencies as recorded left join required_competencies as required
on recorded.competency_id=required.competency_id 
left join indicators on recorded.competency_id=indicators.competency_id
and recorded.competency_indicator_key=indicators.level
),
report_2 as
(
select rep1.competency_area,rep1.competency_name,rep1.user_recorded_competency_level, indicators.indicator_en as user_recorded_competency_indicator
rep1.user_required_competency,rep1.user_required_competency_indicator
from report_1 rep1 left join indicators on 
)
select competency_area,competency_name,user_recorded_competency_level,user_required_competency,STRING_AGG(indicator_en, '.  ') as competency_indicator
from report
group by 
competency_area,competency_name,user_recorded_competency_level,user_required_competency
order by competency_area,competency_name


select role_cluster_id from user_role_cluster urc 
select * from app_user au 
select competency_id,max(role_competency_value) as max_score from role_competency_matrix where organization_id =1 and role_cluster_id
in (select role_cluster_id from user_role_cluster where user_id=16) group by competency_id



select competency_id,"level",indicator_en from competency_indicators ci 

SELECT 
    competency_id,
    "level",
    CASE
        WHEN "level" = 'kennen' THEN 1
        WHEN "level" = 'verstehen' THEN 2
        WHEN "level" = 'anwenden' THEN 4
        WHEN "level" = 'beherrschen' THEN 6
        ELSE 0 -- Optional: to handle unexpected level values
    END AS level_score,
    indicator_en
FROM 
    competency_indicators ci;
   
   
select * from competency_indicators 







CREATE OR REPLACE FUNCTION get_competency_results(p_user_id INT, p_organization_id INT)
RETURNS TABLE (
    competency_area TEXT,
    competency_name TEXT,
    user_recorded_level TEXT,
    user_recorded_level_competency_indicator TEXT,
    user_required_level TEXT,
    user_required_level_competency_indicator TEXT
) AS $$
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
$$ LANGUAGE plpgsql;


