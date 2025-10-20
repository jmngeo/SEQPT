-- Fix the trigger to only set username if NULL
CREATE OR REPLACE FUNCTION public.set_username() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.id IS NULL THEN
    NEW.id := nextval(pg_get_serial_sequence('new_survey_user', 'id'));
  END IF;
  
  -- Only set username if it's NULL or empty
  IF NEW.username IS NULL OR NEW.username = '' THEN
    NEW.username := 'se_survey_user_' || NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$;
