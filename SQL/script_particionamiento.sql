-- SCRIPT SQL CREADO POR ALEJANDRO SABATER PARA CREAR TRIGGER PARA PARTICIONAMIENTO, LLAMAR FUNCION DE PARTICIONAMIENTO Y REALIZAR INSERCION POR SEMANA
-- FECHA: 04/04/2014



-- PASOS PARA PARTICONAMIENTO:

-- 1) CREAR SCHEMA nombre_de_esquema

	CREATE SCHEMA asp

-- 2) CREAR TABLA MASTER DE PARITICONAMIENTO. EN ESTA TABLA NO SE INSERTAN DATOS DIRECTAMENTE; SE UTILIZA PARA ESTABLECER LA DEFINICION DE LAS DEMAS TABLAS

	-- Table: audit_status

-- DROP TABLE audit_status;

		CREATE TABLE audit_status_master
		(
		  actiontime timestamp without time zone,
		  actioncode character varying,
		  identifier character varying,
		  serial integer,
		  node character varying,
		  nodealias character varying,
		  manager character varying,
		  agent character varying,
		  alertgroup character varying,
		  alertkey character varying,
		  severity integer,
		  summary character varying,
		  statechange timestamp without time zone,
		  firstoccurrence timestamp without time zone,
		  lastoccurrence timestamp without time zone,
		  internallast timestamp without time zone,
		  poll integer,
		  tipe integer,
		  tally integer,
		  clas integer,
		  grade integer,
		  locacion character varying,
		  owneruid integer,
		  ownergid integer,
		  acknowledged integer,
		  flash integer,
		  eventid character varying,
		  expiretime integer,
		  processreq integer,
		  suppressescl integer,
		  customer character varying,
		  service character varying,
		  physicalslot integer,
		  physicalport integer,
		  physicalcard character varying,
		  tasklist integer,
		  nmosserial character varying,
		  nmosobjinst integer,
		  nmoscausetype integer,
		  nmosdomainname character varying,
		  nmosentityid integer,
		  nmoseventmap character varying,
		  nmosmanagedstatus integer,
		  localnodealias character varying,
		  localpriobj character varying,
		  localsecobj character varying,
		  localrootobj character varying,
		  remotenodealias character varying,
		  remotepriobj character varying,
		  remotesecobj character varying,
		  remoterootobj character varying,
		  x733eventtype integer,
		  x733probablecause integer,
		  x733specificprob character varying,
		  x733corrnotif character varying,
		  elementname character varying,
		  elementparent character varying,
		  elementtype character varying,
		  provider character varying,
		  domainn character varying,
		  technology character varying,
		  logticket integer,
		  servername character varying,
		  serverserial integer,
		  cellid integer,
		  region integer,
		  criticos integer,
		  siteid integer
		)
		WITH (
		  OIDS=FALSE
		);
		ALTER TABLE audit_status
		  OWNER TO u_digitel;
		GRANT ALL ON TABLE audit_status TO u_digitel;
		GRANT ALL ON TABLE audit_status TO asp;
		
		-- Index: idx_audit_status_master_firstoccurrence
		
		CREATE INDEX idx_audit_status_master_firstoccurrence
		  ON audit_status_master
		  USING btree
		  (firstoccurrence);
		  
-- 3) SE CREA LA TABLA audit_status_fuera, EN DONDE SE INSERTARAN LOS ROWS QUE NO ENTREN DENTRO DE LOS CONSTRAINSTS DE INSERCION


		CREATE TABLE audit_status_master
		(
		  actiontime timestamp without time zone,
		  actioncode character varying,
		  identifier character varying,
		  serial integer,
		  node character varying,
		  nodealias character varying,
		  manager character varying,
		  agent character varying,
		  alertgroup character varying,
		  alertkey character varying,
		  severity integer,
		  summary character varying,
		  statechange timestamp without time zone,
		  firstoccurrence timestamp without time zone,
		  lastoccurrence timestamp without time zone,
		  internallast timestamp without time zone,
		  poll integer,
		  tipe integer,
		  tally integer,
		  clas integer,
		  grade integer,
		  locacion character varying,
		  owneruid integer,
		  ownergid integer,
		  acknowledged integer,
		  flash integer,
		  eventid character varying,
		  expiretime integer,
		  processreq integer,
		  suppressescl integer,
		  customer character varying,
		  service character varying,
		  physicalslot integer,
		  physicalport integer,
		  physicalcard character varying,
		  tasklist integer,
		  nmosserial character varying,
		  nmosobjinst integer,
		  nmoscausetype integer,
		  nmosdomainname character varying,
		  nmosentityid integer,
		  nmoseventmap character varying,
		  nmosmanagedstatus integer,
		  localnodealias character varying,
		  localpriobj character varying,
		  localsecobj character varying,
		  localrootobj character varying,
		  remotenodealias character varying,
		  remotepriobj character varying,
		  remotesecobj character varying,
		  remoterootobj character varying,
		  x733eventtype integer,
		  x733probablecause integer,
		  x733specificprob character varying,
		  x733corrnotif character varying,
		  elementname character varying,
		  elementparent character varying,
		  elementtype character varying,
		  provider character varying,
		  domainn character varying,
		  technology character varying,
		  logticket integer,
		  servername character varying,
		  serverserial integer,
		  cellid integer,
		  region integer,
		  criticos integer,
		  siteid integer
		)
	
		  CREATE INDEX idx_audit_status_fuera_firstoccurrence
		  ON asp.audit_status_fuera
		  USING btree
		  (firstoccurrence);
		  
		  
-- 4) SE CREA LA FUNCION QUE SE LE VA A ASIGNAR AL TRIGGER DE INSERCIÓN Y SE CREA EL TRIGGER


		-- EL QUERY A CONTINUACION CREA UNA FUNCION LA CUAL LUEGO ES UTILIZADA POR UN TRIGGER EL CUAL SERA LLAMADO EN CADA INSERCION A TABLA MASTER
		
		CREATE OR REPLACE FUNCTION public.f_dealer_audit_status_out()
		  RETURNS trigger AS
		$BODY$
		DECLARE
			_schema				varchar := '';
			_target_table		varchar := '';	
			_table_OOR			varchar := '';			
			_sql_insert			varchar := '';
			_a_values			varchar[];
			_fields				varchar[];
		
		BEGIN
			IF TG_NARGS < 2 THEN
				RAISE EXCEPTION 'No se han definido los argumentos del trigger, %',TG_NARGS;
			END IF;
		
			-- Obtiene los parámetros del trigger
			_schema 	:= TG_ARGV[0];
			_table_OOR 	:= TG_ARGV[1];
			
			IF NEW.firstoccurrence IS NULL THEN
				RETURN NULL;
			END IF;
			
			-- Arma el nombre de la tabla donde se realizaró el insert. Debe quedar algo como: "test_partitioning.days_table_2010_07_23"
			_target_table := TG_TABLE_NAME || '_' || to_char(NEW.firstoccurrence,'YYYY_MM_DD');
			
			-- Define los campos que se utilizarón para el insert en la tabla correspondiente.
			_fields[1] := 'actiontime';
			_fields[2] := 'actioncode';
			_fields[3] := 'identifier';
			_fields[4] := 'serial';
			_fields[5] := 'node';
			_fields[6] := 'nodealias';
			_fields[7] := 'manager';
			_fields[8] := 'agent';
			_fields[9] := 'alertgroup';
			_fields[10] := 'alertkey';
			_fields[11] := 'severity';
			_fields[12] := 'summary';
			_fields[13] := 'statechange';
			_fields[14] := 'firstoccurrence';
			_fields[15] := 'lastoccurrence';
			_fields[16] := 'internallast';
			_fields[17] := 'poll';
			_fields[18] := 'tipe';
			_fields[19] := 'tally';
			_fields[20] := 'clas';
			_fields[21] := 'grade';
			_fields[22] := 'locacion';
			_fields[23] := 'owneruid';
			_fields[24] := 'ownergid';
			_fields[25] := 'acknowledged';
			_fields[26] := 'flash';
			_fields[27] := 'eventid';
			_fields[28] := 'expiretime';
			_fields[29] := 'processreq';
			_fields[30] := 'suppressescl';
			_fields[31] := 'customer';
			_fields[32] := 'service';
			_fields[33] := 'physicalslot';
			_fields[34] := 'physicalport';
			_fields[35] := 'physicalcard';
			_fields[36] := 'tasklist';
			_fields[37] := 'nmosserial';
			_fields[38] := 'nmosobjinst';
			_fields[39] := 'nmoscausetype';
			_fields[40] := 'nmosdomainname';
			_fields[41] := 'nmosentityid';
			_fields[42] := 'nmoseventmap';
			_fields[43] := 'nmosmanagedstatus';
			_fields[44] := 'localnodealias';
			_fields[45] := 'localpriobj';
			_fields[46] := 'localsecobj';
			_fields[47] := 'localrootobj';
			_fields[48] := 'remotenodealias';
			_fields[49] := 'remotepriobj';
			_fields[50] := 'remotesecobj';
			_fields[51] := 'remoterootobj';
			_fields[52] := 'x733eventtype';
			_fields[53] := 'x733probablecause';
			_fields[54] := 'x733specificprob';
			_fields[55] := 'x733corrnotif';
			_fields[56] := 'elementname';
			_fields[57] := 'elementparent';
			_fields[58] := 'elementtype';
			_fields[59] := 'provider';
			_fields[60] := 'domainn';
			_fields[61] := 'technology';
			_fields[62] := 'logticket';
			_fields[63] := 'servername';
			_fields[64] := 'serverserial';
			_fields[65] := 'cellid';
			_fields[66] := 'region';
			_fields[67] := 'criticos';
			_fields[68] := 'siteid';
		
		
			-- Se obtienen los valores que se insertarón.
			_a_values[1] := COALESCE(quote_literal(new.actiontime), 'NULL');
			_a_values[2] := COALESCE(quote_literal(new.actioncode), 'NULL');
			_a_values[3] := COALESCE(quote_literal(new.identifier), 'NULL');
			_a_values[4] := COALESCE(quote_literal(new.serial), 'NULL');
			_a_values[5] := COALESCE(quote_literal(new.node), 'NULL');
			_a_values[6] := COALESCE(quote_literal(new.nodealias), 'NULL');
			_a_values[7] := COALESCE(quote_literal(new.manager), 'NULL');
			_a_values[8] := COALESCE(quote_literal(new.agent), 'NULL');
			_a_values[9] := COALESCE(quote_literal(new.alertgroup), 'NULL');
			_a_values[10] := COALESCE(quote_literal(new.alertkey), 'NULL');
			_a_values[11] := COALESCE(quote_literal(new.severity), 'NULL');
			_a_values[12] := COALESCE(quote_literal(new.summary), 'NULL');
			_a_values[13] := COALESCE(quote_literal(new.statechange), 'NULL');
			_a_values[14] := COALESCE(quote_literal(new.firstoccurrence), 'NULL');
			_a_values[15] := COALESCE(quote_literal(new.lastoccurrence), 'NULL');
			_a_values[16] := COALESCE(quote_literal(new.internallast), 'NULL');
			_a_values[17] := COALESCE(quote_literal(new.poll), 'NULL');
			_a_values[18] := COALESCE(quote_literal(new.tipe), 'NULL');
			_a_values[19] := COALESCE(quote_literal(new.tally), 'NULL');
			_a_values[20] := COALESCE(quote_literal(new.clas), 'NULL');
			_a_values[21] := COALESCE(quote_literal(new.grade), 'NULL');
			_a_values[22] := COALESCE(quote_literal(new.locacion), 'NULL');
			_a_values[23] := COALESCE(quote_literal(new.owneruid), 'NULL');
			_a_values[24] := COALESCE(quote_literal(new.ownergid), 'NULL');
			_a_values[25] := COALESCE(quote_literal(new.acknowledged), 'NULL');
			_a_values[26] := COALESCE(quote_literal(new.flash), 'NULL');
			_a_values[27] := COALESCE(quote_literal(new.eventid), 'NULL');
			_a_values[28] := COALESCE(quote_literal(new.expiretime), 'NULL');
			_a_values[29] := COALESCE(quote_literal(new.processreq), 'NULL');
			_a_values[30] := COALESCE(quote_literal(new.suppressescl), 'NULL');
			_a_values[31] := COALESCE(quote_literal(new.customer), 'NULL');
			_a_values[32] := COALESCE(quote_literal(new.service), 'NULL');
			_a_values[33] := COALESCE(quote_literal(new.physicalslot), 'NULL');
			_a_values[34] := COALESCE(quote_literal(new.physicalport), 'NULL');
			_a_values[35] := COALESCE(quote_literal(new.physicalcard), 'NULL');
			_a_values[36] := COALESCE(quote_literal(new.tasklist), 'NULL');
			_a_values[37] := COALESCE(quote_literal(new.nmosserial), 'NULL');
			_a_values[38] := COALESCE(quote_literal(new.nmosobjinst), 'NULL');
			_a_values[39] := COALESCE(quote_literal(new.nmoscausetype), 'NULL');
			_a_values[40] := COALESCE(quote_literal(new.nmosdomainname), 'NULL');
			_a_values[41] := COALESCE(quote_literal(new.nmosentityid), 'NULL');
			_a_values[42] := COALESCE(quote_literal(new.nmoseventmap), 'NULL');
			_a_values[43] := COALESCE(quote_literal(new.nmosmanagedstatus), 'NULL');
			_a_values[44] := COALESCE(quote_literal(new.localnodealias), 'NULL');
			_a_values[45] := COALESCE(quote_literal(new.localpriobj), 'NULL');
			_a_values[46] := COALESCE(quote_literal(new.localsecobj), 'NULL');
			_a_values[47] := COALESCE(quote_literal(new.localrootobj), 'NULL');
			_a_values[48] := COALESCE(quote_literal(new.remotenodealias), 'NULL');
			_a_values[49] := COALESCE(quote_literal(new.remotepriobj), 'NULL');
			_a_values[50] := COALESCE(quote_literal(new.remotesecobj), 'NULL');
			_a_values[51] := COALESCE(quote_literal(new.remoterootobj), 'NULL');
			_a_values[52] := COALESCE(quote_literal(new.x733eventtype), 'NULL');
			_a_values[53] := COALESCE(quote_literal(new.x733probablecause), 'NULL');
			_a_values[54] := COALESCE(quote_literal(new.x733specificprob), 'NULL');
			_a_values[55] := COALESCE(quote_literal(new.x733corrnotif), 'NULL');
			_a_values[56] := COALESCE(quote_literal(new.elementname), 'NULL');
			_a_values[57] := COALESCE(quote_literal(new.elementparent), 'NULL');
			_a_values[58] := COALESCE(quote_literal(new.elementtype), 'NULL');
			_a_values[59] := COALESCE(quote_literal(new.provider), 'NULL');
			_a_values[60] := COALESCE(quote_literal(new.domainn), 'NULL');
			_a_values[61] := COALESCE(quote_literal(new.technology), 'NULL');
			_a_values[62] := COALESCE(quote_literal(new.logticket), 'NULL');
			_a_values[63] := COALESCE(quote_literal(new.servername), 'NULL');
			_a_values[64] := COALESCE(quote_literal(new.serverserial), 'NULL');
			_a_values[65] := COALESCE(quote_literal(new.cellid), 'NULL');
			_a_values[66] := COALESCE(quote_literal(new.region), 'NULL');
			_a_values[67] := COALESCE(quote_literal(new.criticos), 'NULL');
			_a_values[68] := COALESCE(quote_literal(new.siteid), 'NULL');
		
		
			-- Arma el INSERT 
			--	_schema: 		Nombre del esquema. proviene de los parámetros del TRIGGER
			-- _target_table:	Nombre de la tabla destino.
			-- _fields:			Cadena que tiene todos los campos que intervienen en el insert
			--	_a_values:		Array varchar que contiene todos los valores que se insertarón. (Debe corresponder con la cantidad de campos de _fields)
			
			_sql_insert := 'INSERT INTO ' || _schema || '.' || _target_table || '(' || array_to_string(_fields, ',') || ') VALUES (' || array_to_string(_a_values, ',') ||  ')';
			
			--RAISE NOTICE '%', _sql_insert;
			-- Ejecuta el insert. En el caso de que falle porque la tabla destino no existe, entonces se realizaró el insert en la tabla "_table_OOR"
			-- reportes_fuera_rango, que es un parámetro del trigger. 
			
			EXECUTE(_sql_insert);
			RETURN NULL;
			EXCEPTION 
				WHEN undefined_table THEN
					_sql_insert := 'INSERT INTO ' || _schema || '.' || _table_OOR || '(' || array_to_string(_fields, ',') || ') VALUES (' || array_to_string(_a_values, ',') || ')';
					EXECUTE(_sql_insert);
					RETURN NULL;
		END;
		$BODY$
		LANGUAGE 'plpgsql' VOLATILE;
		
		CREATE TRIGGER __dealer_days_table_out
		  BEFORE INSERT
		  ON public.audit_status_master
		  FOR EACH ROW
		  EXECUTE PROCEDURE public.f_dealer_audit_status_out('asp','audit_status_fuera');
		
		-- FIN DEL QUERY

-- LLAMADA DE FUNCION DE INSERCION, LA CUAL LLAMA AL TRIGGER CREADO ANTERIORMENTE.


		SELECT partitioning_tools.routine_interval(
			'public',
			'audit_status_master',
			'asp',
			'audit_status_fuera',
			'__dealer_days_table_out',
			'tbl2',
			'tbl3',
			'u_digitel',
			'firstoccurrence',
			false,
			'2012-11-01 00:00:00'::timestamp with time zone,
			'2014-02-24 23:59:59'::timestamp with time zone,
			'23:59:59'::interval
		);

SELECT partitioning_tools.routine_days(
			'public',
			'audit_status_master',
			'asp',
			'audit_status_fuera',
			'__dealer_days_table_out',
			'tbl2',
			'tbl3',
			'u_digitel',
			'firstoccurrence',
			false,
			'2012-11-01 00:00:00'::timestamp with time zone,
			'2014-02-24 23:59:59'::timestamp with time zone
		);

CREATE TABLE asp.audit_status_fuera (
) INHERITS (public.audit_status_master);

-- FIN DEL QUERY

-- QUERY DE INSERCION EN LA BASE DE DATOS AUDIT_STATUS_MASTER. TABLA MASTER DEL PARTICIONAMIENTO

INSERT INTO audit_status_master
SELECT actiontime, actioncode, identifier, serial, node, nodealias, 
       manager, agent, alertgroup, alertkey, severity, summary, statechange, 
       firstoccurrence, lastoccurrence, internallast, poll, tipe, tally, 
       clas, grade, locacion, owneruid, ownergid, acknowledged, flash, 
       eventid, expiretime, processreq, suppressescl, customer, service, 
       physicalslot, physicalport, physicalcard, tasklist, nmosserial, 
       nmosobjinst, nmoscausetype, nmosdomainname, nmosentityid, nmoseventmap, 
       nmosmanagedstatus, localnodealias, localpriobj, localsecobj, 
       localrootobj, remotenodealias, remotepriobj, remotesecobj, remoterootobj, 
       x733eventtype, x733probablecause, x733specificprob, x733corrnotif, 
       elementname, elementparent, elementtype, provider, domainn, technology, 
       logticket, servername, serverserial, cellid, region, criticos, 
       siteid
  FROM audit_status;

-- FIN DEL QUERY
