--
-- PostgreSQL database dump
--

\restrict 1bt34ivBgLlbyaHkQdk405DhLTRIUBAHtciqcB07fchlAelsrgS0i1sCjg8pMOC

-- Dumped from database version 16.10 (Ubuntu 16.10-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.10 (Ubuntu 16.10-0ubuntu0.24.04.1)

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
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: omen
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.active_storage_attachments OWNER TO omen;

--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: omen
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.active_storage_attachments_id_seq OWNER TO omen;

--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: omen
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: omen
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    created_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.active_storage_blobs OWNER TO omen;

--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: omen
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.active_storage_blobs_id_seq OWNER TO omen;

--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: omen
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: omen
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


ALTER TABLE public.active_storage_variant_records OWNER TO omen;

--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: omen
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNER TO omen;

--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: omen
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: omen
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.ar_internal_metadata OWNER TO omen;

--
-- Name: bulk_uploads; Type: TABLE; Schema: public; Owner: omen
--

CREATE TABLE public.bulk_uploads (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    total_rows integer DEFAULT 0,
    successful_rows integer DEFAULT 0,
    failed_rows integer DEFAULT 0,
    error_details jsonb DEFAULT '[]'::jsonb,
    processed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    processed_count integer DEFAULT 0 NOT NULL,
    current_row integer,
    started_at timestamp(6) without time zone
);


ALTER TABLE public.bulk_uploads OWNER TO omen;

--
-- Name: bulk_uploads_id_seq; Type: SEQUENCE; Schema: public; Owner: omen
--

CREATE SEQUENCE public.bulk_uploads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.bulk_uploads_id_seq OWNER TO omen;

--
-- Name: bulk_uploads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: omen
--

ALTER SEQUENCE public.bulk_uploads_id_seq OWNED BY public.bulk_uploads.id;


--
-- Name: communes; Type: TABLE; Schema: public; Owner: omen
--

CREATE TABLE public.communes (
    id bigint NOT NULL,
    name character varying,
    region_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.communes OWNER TO omen;

--
-- Name: communes_id_seq; Type: SEQUENCE; Schema: public; Owner: omen
--

CREATE SEQUENCE public.communes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.communes_id_seq OWNER TO omen;

--
-- Name: communes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: omen
--

ALTER SEQUENCE public.communes_id_seq OWNED BY public.communes.id;


--
-- Name: packages; Type: TABLE; Schema: public; Owner: omen
--

CREATE TABLE public.packages (
    id bigint NOT NULL,
    customer_name character varying,
    company character varying,
    address text,
    description text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id bigint,
    phone character varying,
    exchange boolean DEFAULT false NOT NULL,
    loading_date date,
    region_id bigint,
    commune_id bigint,
    status integer DEFAULT 0 NOT NULL,
    cancelled_at timestamp(6) without time zone,
    cancellation_reason text,
    amount numeric(10,2) DEFAULT 0.0 NOT NULL,
    tracking_code character varying NOT NULL,
    previous_status integer,
    status_history jsonb DEFAULT '[]'::jsonb,
    location character varying,
    attempts_count integer DEFAULT 0,
    assigned_courier_id bigint,
    proof text,
    reprogramed_to timestamp(6) without time zone,
    reprogram_motive text,
    picked_at timestamp(6) without time zone,
    shipped_at timestamp(6) without time zone,
    delivered_at timestamp(6) without time zone,
    admin_override boolean DEFAULT false,
    bulk_upload_id bigint
);


ALTER TABLE public.packages OWNER TO omen;

--
-- Name: packages_id_seq; Type: SEQUENCE; Schema: public; Owner: omen
--

CREATE SEQUENCE public.packages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.packages_id_seq OWNER TO omen;

--
-- Name: packages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: omen
--

ALTER SEQUENCE public.packages_id_seq OWNED BY public.packages.id;


--
-- Name: regions; Type: TABLE; Schema: public; Owner: omen
--

CREATE TABLE public.regions (
    id bigint NOT NULL,
    name character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.regions OWNER TO omen;

--
-- Name: regions_id_seq; Type: SEQUENCE; Schema: public; Owner: omen
--

CREATE SEQUENCE public.regions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.regions_id_seq OWNER TO omen;

--
-- Name: regions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: omen
--

ALTER SEQUENCE public.regions_id_seq OWNED BY public.regions.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: omen
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO omen;

--
-- Name: users; Type: TABLE; Schema: public; Owner: omen
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp(6) without time zone,
    remember_created_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    admin boolean DEFAULT false,
    role integer DEFAULT 1 NOT NULL,
    show_logo_on_labels boolean DEFAULT true,
    rut character varying,
    phone character varying,
    company character varying,
    active boolean DEFAULT true NOT NULL,
    delivery_charge numeric(10,2) DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.users OWNER TO omen;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: omen
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO omen;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: omen
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: omen
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: omen
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: omen
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: bulk_uploads id; Type: DEFAULT; Schema: public; Owner: omen
--

ALTER TABLE ONLY public.bulk_uploads ALTER COLUMN id SET DEFAULT nextval('public.bulk_uploads_id_seq'::regclass);


--
-- Name: communes id; Type: DEFAULT; Schema: public; Owner: omen
--

ALTER TABLE ONLY public.communes ALTER COLUMN id SET DEFAULT nextval('public.communes_id_seq'::regclass);


--
-- Name: packages id; Type: DEFAULT; Schema: public; Owner: omen
--

ALTER TABLE ONLY public.packages ALTER COLUMN id SET DEFAULT nextval('public.packages_id_seq'::regclass);


--
-- Name: regions id; Type: DEFAULT; Schema: public; Owner: omen
--

ALTER TABLE ONLY public.regions ALTER COLUMN id SET DEFAULT nextval('public.regions_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: omen
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: active_storage_attachments; Type: TABLE DATA; Schema: public; Owner: omen
--

COPY public.active_storage_attachments (id, name, record_type, record_id, blob_id, created_at) FROM stdin;
1	company_logo	User	3	1	2025-11-21 16:01:04.177597
2	company_logo	User	9	2	2025-11-21 16:43:15.615835
3	file	BulkUpload	1	3	2025-11-21 19:05:20.679231
4	file	BulkUpload	2	4	2025-11-21 19:07:49.901921
5	file	BulkUpload	3	5	2025-11-21 19:10:48.982648
6	file	BulkUpload	4	6	2025-11-21 19:19:17.758242
7	file	BulkUpload	5	7	2025-11-21 19:20:56.90471
8	file	BulkUpload	6	8	2025-11-21 19:26:18.998309
9	file	BulkUpload	7	9	2025-11-21 20:08:20.192793
10	file	BulkUpload	8	10	2025-11-23 14:31:31.56044
14	file	BulkUpload	12	14	2025-11-23 15:25:01.272029
15	file	BulkUpload	13	15	2025-11-23 15:25:56.059501
16	file	BulkUpload	14	16	2025-11-23 15:32:07.956961
19	file	BulkUpload	17	19	2025-11-24 13:51:13.939368
20	file	BulkUpload	18	20	2025-11-24 18:01:08.103497
21	file	BulkUpload	19	21	2025-11-24 18:08:55.814554
22	file	BulkUpload	20	22	2025-11-24 18:14:41.238721
23	file	BulkUpload	21	23	2025-11-24 18:22:46.155003
24	file	BulkUpload	22	24	2025-11-24 18:24:24.946052
27	file	BulkUpload	25	27	2025-11-24 18:51:20.640438
28	file	BulkUpload	26	28	2025-11-24 19:48:06.845851
29	file	BulkUpload	27	29	2025-11-24 19:50:20.788963
30	file	BulkUpload	28	30	2025-11-24 19:59:33.102448
31	file	BulkUpload	29	31	2025-11-24 20:05:28.408923
32	file	BulkUpload	30	32	2025-11-25 03:20:24.711213
33	file	BulkUpload	31	33	2025-11-25 03:35:24.048045
\.


--
-- Data for Name: active_storage_blobs; Type: TABLE DATA; Schema: public; Owner: omen
--

COPY public.active_storage_blobs (id, key, filename, content_type, metadata, service_name, byte_size, checksum, created_at) FROM stdin;
1	d12ibl41ch0z080eehggz97kt8kx	delivery4.png	image/png	{"identified":true,"analyzed":true}	local	15473	aj3OaHbFzwj/YPlHVXmHgA==	2025-11-21 16:01:04.176261
2	6t7k3h569oohuaf2ygf8v7y38g4m	logotest.png	image/png	{"identified":true,"analyzed":true}	local	3395	9YxihC6XTgWI8NgD9Agr7g==	2025-11-21 16:43:15.614488
3	dkvrfodfvqt0d36a96xn8ebdzd3v	plantilla_carga_masiva.csv	text/csv	{"identified":true,"analyzed":true}	local	442	YiaNn2i7ZT6Lq0nxyQpGsQ==	2025-11-21 19:05:20.676942
4	wkwmsvz0nzyw0iohctpgcq5h070v	plantilla_carga_masiva.csv	text/csv	{"identified":true,"analyzed":true}	local	442	YiaNn2i7ZT6Lq0nxyQpGsQ==	2025-11-21 19:07:49.900848
5	lvetmuax5uprgs09ccm8im1h7zt9	plantilla_carga_masiva.csv	text/csv	{"identified":true,"analyzed":true}	local	442	YiaNn2i7ZT6Lq0nxyQpGsQ==	2025-11-21 19:10:48.981358
6	a56ya1fo8kpx54978u9gxcyfltqq	plantilla_carga_masiva.csv	text/csv	{"identified":true,"analyzed":true}	local	442	F0anbkzwHnttRLMWa8lKyA==	2025-11-21 19:19:17.757248
7	eb3sv9t1mnsak6picygn3j10e0ok	plantilla_carga_masiva.csv	text/csv	{"identified":true,"analyzed":true}	local	475	H7T8R1sRr2EZ60R4CbsyVQ==	2025-11-21 19:20:56.90359
8	euh9ro1gt82lhegrlziayskugwty	plantilla_carga_masiva.csv	text/csv	{"identified":true,"analyzed":true}	local	168	iyF9I/YpjSpAcEu3XXz/TA==	2025-11-21 19:26:18.997162
9	1x389zg8rhmmf3j9t51k5vrkpsf6	plantilla_carga_masiva.csv	text/csv	{"identified":true,"analyzed":true}	local	301	LuU/pTNeECBLhVpVKNl12w==	2025-11-21 20:08:20.191582
10	0wyzrhlgl7blw3v83or5e55wwray	plantilla_carga_masiva.csv	text/csv	{"identified":true,"analyzed":true}	local	308	khFyfs57cOKK47D2x6j9eQ==	2025-11-23 14:31:31.556116
20	x96wlyvvu2wv6b5zqy6r45acpype	carga_masiva_roraima.csv	text/csv	{"identified":true,"analyzed":true}	local	7682	EvsrW7BcTFVCW86YYfW/tw==	2025-11-24 18:01:08.102163
21	tx0jo7c8sqk0otp3bzpp80vbi4ie	carga_masiva_roraima.csv	text/csv	{"identified":true,"analyzed":true}	local	7682	EvsrW7BcTFVCW86YYfW/tw==	2025-11-24 18:08:55.812828
14	659kia2zzuf4g5j07gzza456176p	plantilla_carga_masiva.csv	text/csv	{"identified":true,"analyzed":true}	local	292	+fdDpkiZ/qrG95/8AhnsHQ==	2025-11-23 15:25:01.270889
15	degatk2sgt8mdvsypzdkr68m5haj	plantilla_carga_masiva.csv	text/csv	{"identified":true,"analyzed":true}	local	292	+fdDpkiZ/qrG95/8AhnsHQ==	2025-11-23 15:25:56.058021
16	qt6iu988bbf65jvvm6ms09imj5ad	plantilla_carga_masiva.csv	text/csv	{"identified":true,"analyzed":true}	local	290	3aVhO5ENLxk8osQQ6ebR6Q==	2025-11-23 15:32:07.955914
22	k990th649fba45izyue4xsy8fpzj	carga_masiva_roraima.csv	text/csv	{"identified":true,"analyzed":true}	local	7682	EvsrW7BcTFVCW86YYfW/tw==	2025-11-24 18:14:41.237688
19	3utifzjvhn35r8twj9i78qre17kr	carga_masiva_roraima.csv	text/csv	{"identified":true,"analyzed":true}	local	7682	EvsrW7BcTFVCW86YYfW/tw==	2025-11-24 13:51:13.937948
23	6zijkybmxfb2udd4bh3ymt6nxbww	carga_masiva_roraima.csv	text/csv	{"identified":true,"analyzed":true}	local	7682	EvsrW7BcTFVCW86YYfW/tw==	2025-11-24 18:22:46.153938
24	0f40wn2a4czht2mc6j4pwgix88mf	carga_masiva_roraima.csv	text/csv	{"identified":true,"analyzed":true}	local	7682	EvsrW7BcTFVCW86YYfW/tw==	2025-11-24 18:24:24.944927
32	prpkztsxihopzw01bhl22z9niyz6	carga_masiva_paquetes (1).csv	text/csv	{"identified":true,"analyzed":true}	local	406	/KvW2OFCh3SaD6RaEwG5FQ==	2025-11-25 03:20:24.709443
27	jcxc8mx1x714f5jto2wbkyf426no	carga_masiva_paquetes.csv	text/csv	{"identified":true,"analyzed":true}	local	339	V9tvhg2HPabuLBb0UuZzQA==	2025-11-24 18:51:20.638344
28	tkg01ri2bjjhnl322o622frq4b0n	carga_masiva_paquetes (1).csv	text/csv	{"identified":true,"analyzed":true}	local	404	Oyh7ZkINzfIf4ipzURhp4w==	2025-11-24 19:48:06.843927
29	484kqk4ytfqx5pppjl8d1jw46vv1	carga_masiva_paquetes (1).csv	text/csv	{"identified":true,"analyzed":true}	local	404	Oyh7ZkINzfIf4ipzURhp4w==	2025-11-24 19:50:20.787517
30	y825p28o0soo9qrpsjeudul4iohw	carga_masiva_paquetes (1).csv	text/csv	{"identified":true,"analyzed":true}	local	404	Oyh7ZkINzfIf4ipzURhp4w==	2025-11-24 19:59:33.10092
31	js57roi2oe73d0ztxnvqopfkqed3	carga_masiva_paquetes (1).csv	text/csv	{"identified":true,"analyzed":true}	local	404	Tc2EUvuyXnxY6MlRDBfQiQ==	2025-11-24 20:05:28.407914
33	5nzasaknjp2c6hxc3hynn1kern5l	carga_masiva_paquetes (1).csv	text/csv	{"identified":true,"analyzed":true}	local	406	/KvW2OFCh3SaD6RaEwG5FQ==	2025-11-25 03:35:24.04659
\.


--
-- Data for Name: active_storage_variant_records; Type: TABLE DATA; Schema: public; Owner: omen
--

COPY public.active_storage_variant_records (id, blob_id, variation_digest) FROM stdin;
\.


--
-- Data for Name: ar_internal_metadata; Type: TABLE DATA; Schema: public; Owner: omen
--

COPY public.ar_internal_metadata (key, value, created_at, updated_at) FROM stdin;
environment	development	2025-11-21 14:34:36.582113	2025-11-21 14:34:36.582116
schema_sha1	7cf37f689ac4c8d61e80ee128876ada95f277214	2025-11-21 14:34:36.584595	2025-11-21 14:34:36.584597
\.


--
-- Data for Name: bulk_uploads; Type: TABLE DATA; Schema: public; Owner: omen
--

COPY public.bulk_uploads (id, user_id, status, total_rows, successful_rows, failed_rows, error_details, processed_at, created_at, updated_at, processed_count, current_row, started_at) FROM stdin;
1	1	0	0	0	0	[]	\N	2025-11-21 19:05:20.672308	2025-11-21 19:05:20.690973	0	\N	\N
18	3	2	100	99	1	[{"row": 2, "error": "Loading date debe ser hoy o posterior", "value": "", "column": "validación"}]	2025-11-24 18:10:42.34563	2025-11-24 18:01:08.097478	2025-11-24 18:10:42.345778	100	101	2025-11-24 18:10:41.169937
2	1	2	3	0	3	[{"row": 2, "error": "Loading date debe ser hoy o posterior", "value": "", "column": "validación"}, {"row": 3, "error": "Loading date debe ser hoy o posterior", "value": "", "column": "validación"}, {"row": 4, "error": "Loading date debe ser hoy o posterior", "value": "", "column": "validación"}]	2025-11-21 19:14:52.826412	2025-11-21 19:07:49.897914	2025-11-21 19:14:52.826593	0	\N	\N
3	1	2	3	0	3	[{"row": 2, "error": "Loading date debe ser hoy o posterior", "value": "", "column": "validación"}, {"row": 3, "error": "Loading date debe ser hoy o posterior", "value": "", "column": "validación"}, {"row": 4, "error": "Loading date debe ser hoy o posterior", "value": "", "column": "validación"}]	2025-11-21 19:14:52.827479	2025-11-21 19:10:48.978125	2025-11-21 19:14:52.827601	0	\N	\N
29	1	2	3	3	0	[]	2025-11-24 20:05:28.482778	2025-11-24 20:05:28.404845	2025-11-24 20:05:28.482984	3	4	2025-11-24 20:05:28.448135
12	3	2	3	3	0	[]	2025-11-23 15:25:01.405849	2025-11-23 15:25:01.267635	2025-11-23 15:25:01.406088	0	\N	\N
6	1	2	1	1	0	[]	2025-11-21 19:29:22.790254	2025-11-21 19:26:18.993197	2025-11-21 19:29:22.79044	0	\N	\N
5	1	2	3	3	0	[]	2025-11-21 19:29:22.818771	2025-11-21 19:20:56.899324	2025-11-21 19:29:22.819155	0	\N	\N
4	1	2	3	0	3	[{"row": 2, "error": "PG::UniqueViolation: ERROR:  duplicate key value violates unique constraint \\"index_packages_on_tracking_code\\"\\nDETAIL:  Key (tracking_code)=(Pkg-242352523532) already exists.\\n", "value": "", "column": "error"}, {"row": 3, "error": "PG::UniqueViolation: ERROR:  duplicate key value violates unique constraint \\"index_packages_on_tracking_code\\"\\nDETAIL:  Key (tracking_code)=(Pkg-12423456367) already exists.\\n", "value": "", "column": "error"}, {"row": 4, "error": "PG::UniqueViolation: ERROR:  duplicate key value violates unique constraint \\"index_packages_on_tracking_code\\"\\nDETAIL:  Key (tracking_code)=(Pkg-2454525235235) already exists.\\n", "value": "", "column": "error"}]	2025-11-21 19:29:22.82097	2025-11-21 19:19:17.754232	2025-11-21 19:29:22.821127	0	\N	\N
19	3	2	100	99	1	[{"row": 2, "error": "Loading date debe ser hoy o posterior", "value": "", "column": "validación"}]	2025-11-24 18:10:42.356863	2025-11-24 18:08:55.804238	2025-11-24 18:10:42.357052	100	101	2025-11-24 18:10:41.172245
7	9	2	4	0	0	[{"row": 2, "error": "no puede estar vacío", "value": "", "column": "EMPRESA"}, {"row": 3, "error": "no existe en el sistema", "value": "nunoa", "column": "COMUNA"}, {"row": 3, "error": "no puede estar vacío", "value": "", "column": "EMPRESA"}, {"row": 4, "error": "no puede estar vacío", "value": "", "column": "EMPRESA"}, {"row": 5, "error": "no puede estar vacío", "value": "", "column": "DESTINATARIO"}, {"row": 5, "error": "no puede estar vacío", "value": "", "column": "TELÉFONO"}, {"row": 5, "error": "no puede estar vacío", "value": "", "column": "DIRECCIÓN"}, {"row": 5, "error": "no puede estar vacío", "value": "", "column": "COMUNA"}, {"row": 5, "error": "no puede estar vacío", "value": "", "column": "DESCRIPCIÓN"}, {"row": 5, "error": "no puede estar vacío", "value": "", "column": "EMPRESA"}]	2025-11-21 20:08:20.311257	2025-11-21 20:08:20.187617	2025-11-21 20:08:20.311447	0	\N	\N
13	3	2	3	3	0	[]	2025-11-23 15:25:56.114304	2025-11-23 15:25:56.054033	2025-11-23 15:25:56.114531	0	\N	\N
8	3	2	4	0	0	[{"row": 2, "error": "no puede estar vacío", "value": "", "column": "EMPRESA"}, {"row": 3, "error": "no existe en el sistema", "value": "nunoa", "column": "COMUNA"}, {"row": 3, "error": "no puede estar vacío", "value": "", "column": "EMPRESA"}, {"row": 4, "error": "no puede estar vacío", "value": "", "column": "EMPRESA"}, {"row": 5, "error": "no puede estar vacío", "value": "", "column": "DESTINATARIO"}, {"row": 5, "error": "no puede estar vacío", "value": "", "column": "TELÉFONO"}, {"row": 5, "error": "no puede estar vacío", "value": "", "column": "DIRECCIÓN"}, {"row": 5, "error": "no puede estar vacío", "value": "", "column": "COMUNA"}, {"row": 5, "error": "no puede estar vacío", "value": "", "column": "DESCRIPCIÓN"}, {"row": 5, "error": "no puede estar vacío", "value": "", "column": "EMPRESA"}]	2025-11-23 14:34:28.173887	2025-11-23 14:31:31.54431	2025-11-23 14:34:28.174294	0	\N	\N
14	3	2	3	3	0	[]	2025-11-23 15:32:08.128351	2025-11-23 15:32:07.953055	2025-11-23 15:32:08.128514	0	\N	\N
26	1	2	3	2	1	[{"row": 3, "error": "Loading date debe ser hoy o posterior", "value": "", "column": "validación"}]	2025-11-24 19:48:07.04962	2025-11-24 19:48:06.839439	2025-11-24 19:48:07.049783	3	4	2025-11-24 19:48:06.985819
17	3	2	100	99	1	[{"row": 2, "error": "Loading date debe ser hoy o posterior", "value": "", "column": "validación"}]	2025-11-24 13:53:33.633137	2025-11-24 13:51:13.933349	2025-11-24 13:53:33.633335	0	\N	\N
25	3	2	3	3	0	[]	2025-11-24 18:51:20.800004	2025-11-24 18:51:20.6342	2025-11-24 18:51:20.800247	3	4	2025-11-24 18:51:20.701408
22	3	2	100	99	1	[{"row": 2, "error": "Loading date debe ser hoy o posterior", "value": "", "column": "validación"}]	2025-11-24 18:24:25.807114	2025-11-24 18:24:24.939895	2025-11-24 18:24:25.807243	100	101	2025-11-24 18:24:25.077184
20	3	2	100	99	1	[{"row": 2, "error": "Loading date debe ser hoy o posterior", "value": "", "column": "validación"}]	2025-11-24 18:23:04.432975	2025-11-24 18:14:41.234795	2025-11-24 18:23:04.433109	100	101	2025-11-24 18:23:03.217522
21	3	2	100	99	1	[{"row": 2, "error": "Loading date debe ser hoy o posterior", "value": "", "column": "validación"}]	2025-11-24 18:23:04.455348	2025-11-24 18:22:46.150971	2025-11-24 18:23:04.455479	100	101	2025-11-24 18:23:03.219418
28	1	2	3	2	1	[{"row": 3, "error": "Loading date debe ser hoy o posterior", "value": "", "column": "validación"}]	2025-11-24 19:59:33.305895	2025-11-24 19:59:33.095534	2025-11-24 19:59:33.306066	3	4	2025-11-24 19:59:33.244176
27	1	2	3	2	1	[{"row": 3, "error": "Loading date debe ser hoy o posterior", "value": "", "column": "validación"}]	2025-11-24 19:50:20.858307	2025-11-24 19:50:20.783401	2025-11-24 19:50:20.858555	3	4	2025-11-24 19:50:20.821855
30	1	2	3	3	0	[]	2025-11-25 03:21:46.07806	2025-11-25 03:20:24.704546	2025-11-25 03:21:46.078244	3	4	2025-11-25 03:21:46.003598
31	1	2	3	3	0	[]	2025-11-25 03:35:24.235923	2025-11-25 03:35:24.04227	2025-11-25 03:35:24.236084	3	4	2025-11-25 03:35:24.175238
\.


--
-- Data for Name: communes; Type: TABLE DATA; Schema: public; Owner: omen
--

COPY public.communes (id, name, region_id, created_at, updated_at) FROM stdin;
1	Arica	1	2025-11-21 14:34:36.743567	2025-11-21 14:34:36.743567
2	Camarones	1	2025-11-21 14:34:36.750354	2025-11-21 14:34:36.750354
3	Putre	1	2025-11-21 14:34:36.754896	2025-11-21 14:34:36.754896
4	General Lagos	1	2025-11-21 14:34:36.75946	2025-11-21 14:34:36.75946
5	Iquique	2	2025-11-21 14:34:36.769454	2025-11-21 14:34:36.769454
6	Alto Hospicio	2	2025-11-21 14:34:36.773444	2025-11-21 14:34:36.773444
7	Pozo Almonte	2	2025-11-21 14:34:36.777806	2025-11-21 14:34:36.777806
8	Camiña	2	2025-11-21 14:34:36.782583	2025-11-21 14:34:36.782583
9	Colchane	2	2025-11-21 14:34:36.787296	2025-11-21 14:34:36.787296
10	Huara	2	2025-11-21 14:34:36.791693	2025-11-21 14:34:36.791693
11	Pica	2	2025-11-21 14:34:36.796525	2025-11-21 14:34:36.796525
12	Antofagasta	3	2025-11-21 14:34:36.807481	2025-11-21 14:34:36.807481
13	Mejillones	3	2025-11-21 14:34:36.811777	2025-11-21 14:34:36.811777
14	Sierra Gorda	3	2025-11-21 14:34:36.815835	2025-11-21 14:34:36.815835
15	Taltal	3	2025-11-21 14:34:36.820141	2025-11-21 14:34:36.820141
16	Calama	3	2025-11-21 14:34:36.82497	2025-11-21 14:34:36.82497
17	Ollagüe	3	2025-11-21 14:34:36.829895	2025-11-21 14:34:36.829895
18	San Pedro de Atacama	3	2025-11-21 14:34:36.834184	2025-11-21 14:34:36.834184
19	Tocopilla	3	2025-11-21 14:34:36.838087	2025-11-21 14:34:36.838087
20	María Elena	3	2025-11-21 14:34:36.842011	2025-11-21 14:34:36.842011
21	Copiapó	4	2025-11-21 14:34:36.851136	2025-11-21 14:34:36.851136
22	Caldera	4	2025-11-21 14:34:36.85714	2025-11-21 14:34:36.85714
23	Tierra Amarilla	4	2025-11-21 14:34:36.861862	2025-11-21 14:34:36.861862
24	Chañaral	4	2025-11-21 14:34:36.86602	2025-11-21 14:34:36.86602
25	Diego de Almagro	4	2025-11-21 14:34:36.870266	2025-11-21 14:34:36.870266
26	Vallenar	4	2025-11-21 14:34:36.87442	2025-11-21 14:34:36.87442
27	Alto del Carmen	4	2025-11-21 14:34:36.878255	2025-11-21 14:34:36.878255
28	Freirina	4	2025-11-21 14:34:36.882063	2025-11-21 14:34:36.882063
29	Huasco	4	2025-11-21 14:34:36.885973	2025-11-21 14:34:36.885973
30	La Serena	5	2025-11-21 14:34:36.896444	2025-11-21 14:34:36.896444
31	Coquimbo	5	2025-11-21 14:34:36.900622	2025-11-21 14:34:36.900622
32	Andacollo	5	2025-11-21 14:34:36.904761	2025-11-21 14:34:36.904761
33	La Higuera	5	2025-11-21 14:34:36.908733	2025-11-21 14:34:36.908733
34	Paiguano	5	2025-11-21 14:34:36.91297	2025-11-21 14:34:36.91297
35	Vicuña	5	2025-11-21 14:34:36.917359	2025-11-21 14:34:36.917359
36	Illapel	5	2025-11-21 14:34:36.921844	2025-11-21 14:34:36.921844
37	Canela	5	2025-11-21 14:34:36.926691	2025-11-21 14:34:36.926691
38	Los Vilos	5	2025-11-21 14:34:36.931401	2025-11-21 14:34:36.931401
39	Salamanca	5	2025-11-21 14:34:36.935801	2025-11-21 14:34:36.935801
40	Ovalle	5	2025-11-21 14:34:36.939802	2025-11-21 14:34:36.939802
41	Combarbalá	5	2025-11-21 14:34:36.944325	2025-11-21 14:34:36.944325
42	Monte Patria	5	2025-11-21 14:34:36.948333	2025-11-21 14:34:36.948333
43	Punitaqui	5	2025-11-21 14:34:36.952733	2025-11-21 14:34:36.952733
44	Río Hurtado	5	2025-11-21 14:34:36.956902	2025-11-21 14:34:36.956902
45	Valparaíso	6	2025-11-21 14:34:36.966917	2025-11-21 14:34:36.966917
46	Casablanca	6	2025-11-21 14:34:36.971033	2025-11-21 14:34:36.971033
47	Concón	6	2025-11-21 14:34:36.975622	2025-11-21 14:34:36.975622
48	Juan Fernández	6	2025-11-21 14:34:36.97991	2025-11-21 14:34:36.97991
49	Puchuncaví	6	2025-11-21 14:34:36.984225	2025-11-21 14:34:36.984225
50	Quintero	6	2025-11-21 14:34:36.988345	2025-11-21 14:34:36.988345
51	Viña del Mar	6	2025-11-21 14:34:36.993374	2025-11-21 14:34:36.993374
52	Isla de Pascua	6	2025-11-21 14:34:36.997917	2025-11-21 14:34:36.997917
53	Los Andes	6	2025-11-21 14:34:37.002194	2025-11-21 14:34:37.002194
54	Calle Larga	6	2025-11-21 14:34:37.006479	2025-11-21 14:34:37.006479
55	Rinconada	6	2025-11-21 14:34:37.012408	2025-11-21 14:34:37.012408
56	San Esteban	6	2025-11-21 14:34:37.016843	2025-11-21 14:34:37.016843
57	La Ligua	6	2025-11-21 14:34:37.021313	2025-11-21 14:34:37.021313
58	Cabildo	6	2025-11-21 14:34:37.026241	2025-11-21 14:34:37.026241
59	Papudo	6	2025-11-21 14:34:37.031165	2025-11-21 14:34:37.031165
60	Petorca	6	2025-11-21 14:34:37.035792	2025-11-21 14:34:37.035792
61	Zapallar	6	2025-11-21 14:34:37.04124	2025-11-21 14:34:37.04124
62	Quillota	6	2025-11-21 14:34:37.045841	2025-11-21 14:34:37.045841
63	Calera	6	2025-11-21 14:34:37.050446	2025-11-21 14:34:37.050446
64	Hijuelas	6	2025-11-21 14:34:37.054904	2025-11-21 14:34:37.054904
65	La Cruz	6	2025-11-21 14:34:37.05906	2025-11-21 14:34:37.05906
66	Nogales	6	2025-11-21 14:34:37.063047	2025-11-21 14:34:37.063047
67	San Antonio	6	2025-11-21 14:34:37.068025	2025-11-21 14:34:37.068025
68	Algarrobo	6	2025-11-21 14:34:37.072301	2025-11-21 14:34:37.072301
69	Cartagena	6	2025-11-21 14:34:37.076381	2025-11-21 14:34:37.076381
70	El Quisco	6	2025-11-21 14:34:37.080691	2025-11-21 14:34:37.080691
71	El Tabo	6	2025-11-21 14:34:37.084865	2025-11-21 14:34:37.084865
72	Santo Domingo	6	2025-11-21 14:34:37.088888	2025-11-21 14:34:37.088888
73	San Felipe	6	2025-11-21 14:34:37.092913	2025-11-21 14:34:37.092913
74	Catemu	6	2025-11-21 14:34:37.097641	2025-11-21 14:34:37.097641
75	Llaillay	6	2025-11-21 14:34:37.101806	2025-11-21 14:34:37.101806
76	Panquehue	6	2025-11-21 14:34:37.105983	2025-11-21 14:34:37.105983
77	Putaendo	6	2025-11-21 14:34:37.110101	2025-11-21 14:34:37.110101
78	Santa María	6	2025-11-21 14:34:37.114068	2025-11-21 14:34:37.114068
79	Quilpué	6	2025-11-21 14:34:37.117844	2025-11-21 14:34:37.117844
80	Limache	6	2025-11-21 14:34:37.121585	2025-11-21 14:34:37.121585
81	Olmué	6	2025-11-21 14:34:37.125646	2025-11-21 14:34:37.125646
82	Villa Alemana	6	2025-11-21 14:34:37.129875	2025-11-21 14:34:37.129875
83	Santiago	7	2025-11-21 14:34:37.138694	2025-11-21 14:34:37.138694
84	Cerrillos	7	2025-11-21 14:34:37.14278	2025-11-21 14:34:37.14278
85	Cerro Navia	7	2025-11-21 14:34:37.146582	2025-11-21 14:34:37.146582
86	Conchalí	7	2025-11-21 14:34:37.150488	2025-11-21 14:34:37.150488
87	El Bosque	7	2025-11-21 14:34:37.154996	2025-11-21 14:34:37.154996
88	Estación Central	7	2025-11-21 14:34:37.15945	2025-11-21 14:34:37.15945
89	Huechuraba	7	2025-11-21 14:34:37.164103	2025-11-21 14:34:37.164103
90	Independencia	7	2025-11-21 14:34:37.168967	2025-11-21 14:34:37.168967
91	La Cisterna	7	2025-11-21 14:34:37.172818	2025-11-21 14:34:37.172818
92	La Florida	7	2025-11-21 14:34:37.176723	2025-11-21 14:34:37.176723
93	La Granja	7	2025-11-21 14:34:37.180561	2025-11-21 14:34:37.180561
94	La Pintana	7	2025-11-21 14:34:37.184362	2025-11-21 14:34:37.184362
95	La Reina	7	2025-11-21 14:34:37.188169	2025-11-21 14:34:37.188169
96	Las Condes	7	2025-11-21 14:34:37.192666	2025-11-21 14:34:37.192666
97	Lo Barnechea	7	2025-11-21 14:34:37.196681	2025-11-21 14:34:37.196681
98	Lo Espejo	7	2025-11-21 14:34:37.200971	2025-11-21 14:34:37.200971
99	Lo Prado	7	2025-11-21 14:34:37.204692	2025-11-21 14:34:37.204692
100	Macul	7	2025-11-21 14:34:37.208523	2025-11-21 14:34:37.208523
101	Maipú	7	2025-11-21 14:34:37.212338	2025-11-21 14:34:37.212338
102	Ñuñoa	7	2025-11-21 14:34:37.216118	2025-11-21 14:34:37.216118
103	Pedro Aguirre Cerda	7	2025-11-21 14:34:37.220621	2025-11-21 14:34:37.220621
104	Peñalolén	7	2025-11-21 14:34:37.225177	2025-11-21 14:34:37.225177
105	Providencia	7	2025-11-21 14:34:37.229127	2025-11-21 14:34:37.229127
106	Pudahuel	7	2025-11-21 14:34:37.233113	2025-11-21 14:34:37.233113
107	Quilicura	7	2025-11-21 14:34:37.23691	2025-11-21 14:34:37.23691
108	Quinta Normal	7	2025-11-21 14:34:37.240608	2025-11-21 14:34:37.240608
109	Recoleta	7	2025-11-21 14:34:37.244318	2025-11-21 14:34:37.244318
110	Renca	7	2025-11-21 14:34:37.248249	2025-11-21 14:34:37.248249
111	San Joaquín	7	2025-11-21 14:34:37.252254	2025-11-21 14:34:37.252254
112	San Miguel	7	2025-11-21 14:34:37.25662	2025-11-21 14:34:37.25662
113	San Ramón	7	2025-11-21 14:34:37.261021	2025-11-21 14:34:37.261021
114	Vitacura	7	2025-11-21 14:34:37.26482	2025-11-21 14:34:37.26482
115	Puente Alto	7	2025-11-21 14:34:37.268659	2025-11-21 14:34:37.268659
116	Pirque	7	2025-11-21 14:34:37.272484	2025-11-21 14:34:37.272484
117	San José de Maipo	7	2025-11-21 14:34:37.276175	2025-11-21 14:34:37.276175
118	Colina	7	2025-11-21 14:34:37.279919	2025-11-21 14:34:37.279919
119	Lampa	7	2025-11-21 14:34:37.283714	2025-11-21 14:34:37.283714
120	Tiltil	7	2025-11-21 14:34:37.288455	2025-11-21 14:34:37.288455
121	San Bernardo	7	2025-11-21 14:34:37.292387	2025-11-21 14:34:37.292387
122	Buin	7	2025-11-21 14:34:37.29636	2025-11-21 14:34:37.29636
123	Calera de Tango	7	2025-11-21 14:34:37.300347	2025-11-21 14:34:37.300347
124	Paine	7	2025-11-21 14:34:37.304361	2025-11-21 14:34:37.304361
125	Melipilla	7	2025-11-21 14:34:37.308124	2025-11-21 14:34:37.308124
126	Alhué	7	2025-11-21 14:34:37.312078	2025-11-21 14:34:37.312078
127	Curacaví	7	2025-11-21 14:34:37.316381	2025-11-21 14:34:37.316381
128	María Pinto	7	2025-11-21 14:34:37.320301	2025-11-21 14:34:37.320301
129	San Pedro	7	2025-11-21 14:34:37.324183	2025-11-21 14:34:37.324183
130	Talagante	7	2025-11-21 14:34:37.328073	2025-11-21 14:34:37.328073
131	El Monte	7	2025-11-21 14:34:37.331809	2025-11-21 14:34:37.331809
132	Isla de Maipo	7	2025-11-21 14:34:37.335589	2025-11-21 14:34:37.335589
133	Padre Hurtado	7	2025-11-21 14:34:37.339674	2025-11-21 14:34:37.339674
134	Peñaflor	7	2025-11-21 14:34:37.343578	2025-11-21 14:34:37.343578
135	Rancagua	8	2025-11-21 14:34:37.354051	2025-11-21 14:34:37.354051
136	Codegua	8	2025-11-21 14:34:37.358233	2025-11-21 14:34:37.358233
137	Coinco	8	2025-11-21 14:34:37.362428	2025-11-21 14:34:37.362428
138	Coltauco	8	2025-11-21 14:34:37.366272	2025-11-21 14:34:37.366272
139	Doñihue	8	2025-11-21 14:34:37.370457	2025-11-21 14:34:37.370457
140	Graneros	8	2025-11-21 14:34:37.374473	2025-11-21 14:34:37.374473
141	Las Cabras	8	2025-11-21 14:34:37.378414	2025-11-21 14:34:37.378414
142	Machalí	8	2025-11-21 14:34:37.383116	2025-11-21 14:34:37.383116
143	Malloa	8	2025-11-21 14:34:37.387137	2025-11-21 14:34:37.387137
144	Mostazal	8	2025-11-21 14:34:37.391151	2025-11-21 14:34:37.391151
145	Olivar	8	2025-11-21 14:34:37.394943	2025-11-21 14:34:37.394943
146	Peumo	8	2025-11-21 14:34:37.398682	2025-11-21 14:34:37.398682
147	Pichidegua	8	2025-11-21 14:34:37.402404	2025-11-21 14:34:37.402404
148	Quinta de Tilcoco	8	2025-11-21 14:34:37.406196	2025-11-21 14:34:37.406196
149	Rengo	8	2025-11-21 14:34:37.410944	2025-11-21 14:34:37.410944
150	Requínoa	8	2025-11-21 14:34:37.415278	2025-11-21 14:34:37.415278
151	San Vicente	8	2025-11-21 14:34:37.419859	2025-11-21 14:34:37.419859
152	Pichilemu	8	2025-11-21 14:34:37.424257	2025-11-21 14:34:37.424257
153	La Estrella	8	2025-11-21 14:34:37.428527	2025-11-21 14:34:37.428527
154	Litueche	8	2025-11-21 14:34:37.43273	2025-11-21 14:34:37.43273
155	Marchihue	8	2025-11-21 14:34:37.437032	2025-11-21 14:34:37.437032
156	Navidad	8	2025-11-21 14:34:37.441318	2025-11-21 14:34:37.441318
157	Paredones	8	2025-11-21 14:34:37.446012	2025-11-21 14:34:37.446012
158	San Fernando	8	2025-11-21 14:34:37.450276	2025-11-21 14:34:37.450276
159	Chépica	8	2025-11-21 14:34:37.454182	2025-11-21 14:34:37.454182
160	Chimbarongo	8	2025-11-21 14:34:37.457985	2025-11-21 14:34:37.457985
161	Lolol	8	2025-11-21 14:34:37.461779	2025-11-21 14:34:37.461779
162	Nancagua	8	2025-11-21 14:34:37.465535	2025-11-21 14:34:37.465535
163	Palmilla	8	2025-11-21 14:34:37.469295	2025-11-21 14:34:37.469295
164	Peralillo	8	2025-11-21 14:34:37.473148	2025-11-21 14:34:37.473148
165	Placilla	8	2025-11-21 14:34:37.477684	2025-11-21 14:34:37.477684
166	Pumanque	8	2025-11-21 14:34:37.481711	2025-11-21 14:34:37.481711
167	Santa Cruz	8	2025-11-21 14:34:37.485548	2025-11-21 14:34:37.485548
168	Talca	9	2025-11-21 14:34:37.49383	2025-11-21 14:34:37.49383
169	Constitución	9	2025-11-21 14:34:37.49772	2025-11-21 14:34:37.49772
170	Curepto	9	2025-11-21 14:34:37.501689	2025-11-21 14:34:37.501689
171	Empedrado	9	2025-11-21 14:34:37.506703	2025-11-21 14:34:37.506703
172	Maule	9	2025-11-21 14:34:37.510839	2025-11-21 14:34:37.510839
173	Pelarco	9	2025-11-21 14:34:37.514949	2025-11-21 14:34:37.514949
174	Pencahue	9	2025-11-21 14:34:37.518853	2025-11-21 14:34:37.518853
175	Río Claro	9	2025-11-21 14:34:37.522649	2025-11-21 14:34:37.522649
176	San Clemente	9	2025-11-21 14:34:37.526444	2025-11-21 14:34:37.526444
177	San Rafael	9	2025-11-21 14:34:37.530313	2025-11-21 14:34:37.530313
178	Cauquenes	9	2025-11-21 14:34:37.534131	2025-11-21 14:34:37.534131
179	Chanco	9	2025-11-21 14:34:37.53855	2025-11-21 14:34:37.53855
180	Pelluhue	9	2025-11-21 14:34:37.543088	2025-11-21 14:34:37.543088
181	Curicó	9	2025-11-21 14:34:37.546922	2025-11-21 14:34:37.546922
182	Hualañé	9	2025-11-21 14:34:37.551007	2025-11-21 14:34:37.551007
183	Licantén	9	2025-11-21 14:34:37.554714	2025-11-21 14:34:37.554714
184	Molina	9	2025-11-21 14:34:37.558588	2025-11-21 14:34:37.558588
185	Rauco	9	2025-11-21 14:34:37.562344	2025-11-21 14:34:37.562344
186	Romeral	9	2025-11-21 14:34:37.566128	2025-11-21 14:34:37.566128
187	Sagrada Familia	9	2025-11-21 14:34:37.57064	2025-11-21 14:34:37.57064
188	Teno	9	2025-11-21 14:34:37.574618	2025-11-21 14:34:37.574618
189	Vichuquén	9	2025-11-21 14:34:37.578522	2025-11-21 14:34:37.578522
190	Linares	9	2025-11-21 14:34:37.582434	2025-11-21 14:34:37.582434
191	Colbún	9	2025-11-21 14:34:37.586231	2025-11-21 14:34:37.586231
192	Longaví	9	2025-11-21 14:34:37.589949	2025-11-21 14:34:37.589949
193	Parral	9	2025-11-21 14:34:37.593741	2025-11-21 14:34:37.593741
194	Retiro	9	2025-11-21 14:34:37.59814	2025-11-21 14:34:37.59814
195	San Javier	9	2025-11-21 14:34:37.602082	2025-11-21 14:34:37.602082
196	Villa Alegre	9	2025-11-21 14:34:37.605938	2025-11-21 14:34:37.605938
197	Yerbas Buenas	9	2025-11-21 14:34:37.60975	2025-11-21 14:34:37.60975
198	Chillán	10	2025-11-21 14:34:37.617921	2025-11-21 14:34:37.617921
199	Bulnes	10	2025-11-21 14:34:37.622098	2025-11-21 14:34:37.622098
200	Chillán Viejo	10	2025-11-21 14:34:37.626412	2025-11-21 14:34:37.626412
201	El Carmen	10	2025-11-21 14:34:37.630851	2025-11-21 14:34:37.630851
202	Pemuco	10	2025-11-21 14:34:37.63533	2025-11-21 14:34:37.63533
203	Pinto	10	2025-11-21 14:34:37.639318	2025-11-21 14:34:37.639318
204	Quillón	10	2025-11-21 14:34:37.643255	2025-11-21 14:34:37.643255
205	San Ignacio	10	2025-11-21 14:34:37.647012	2025-11-21 14:34:37.647012
206	Yungay	10	2025-11-21 14:34:37.650686	2025-11-21 14:34:37.650686
207	Cobquecura	10	2025-11-21 14:34:37.654443	2025-11-21 14:34:37.654443
208	Coelemu	10	2025-11-21 14:34:37.658286	2025-11-21 14:34:37.658286
209	Ninhue	10	2025-11-21 14:34:37.663002	2025-11-21 14:34:37.663002
210	Portezuelo	10	2025-11-21 14:34:37.667026	2025-11-21 14:34:37.667026
211	Quirihue	10	2025-11-21 14:34:37.670772	2025-11-21 14:34:37.670772
212	Ránquil	10	2025-11-21 14:34:37.674537	2025-11-21 14:34:37.674537
213	Treguaco	10	2025-11-21 14:34:37.678289	2025-11-21 14:34:37.678289
214	Coihueco	10	2025-11-21 14:34:37.682032	2025-11-21 14:34:37.682032
215	Ñiquén	10	2025-11-21 14:34:37.68592	2025-11-21 14:34:37.68592
216	San Carlos	10	2025-11-21 14:34:37.69043	2025-11-21 14:34:37.69043
217	San Fabián	10	2025-11-21 14:34:37.694253	2025-11-21 14:34:37.694253
218	San Nicolás	10	2025-11-21 14:34:37.698096	2025-11-21 14:34:37.698096
219	Concepción	11	2025-11-21 14:34:37.70672	2025-11-21 14:34:37.70672
220	Coronel	11	2025-11-21 14:34:37.711135	2025-11-21 14:34:37.711135
221	Chiguayante	11	2025-11-21 14:34:37.715092	2025-11-21 14:34:37.715092
222	Florida	11	2025-11-21 14:34:37.719047	2025-11-21 14:34:37.719047
223	Hualqui	11	2025-11-21 14:34:37.723595	2025-11-21 14:34:37.723595
224	Lota	11	2025-11-21 14:34:37.728066	2025-11-21 14:34:37.728066
225	Penco	11	2025-11-21 14:34:37.731963	2025-11-21 14:34:37.731963
226	San Pedro de la Paz	11	2025-11-21 14:34:37.735774	2025-11-21 14:34:37.735774
227	Santa Juana	11	2025-11-21 14:34:37.73955	2025-11-21 14:34:37.73955
228	Talcahuano	11	2025-11-21 14:34:37.743278	2025-11-21 14:34:37.743278
229	Tomé	11	2025-11-21 14:34:37.746994	2025-11-21 14:34:37.746994
230	Hualpén	11	2025-11-21 14:34:37.750769	2025-11-21 14:34:37.750769
231	Lebu	11	2025-11-21 14:34:37.756455	2025-11-21 14:34:37.756455
232	Arauco	11	2025-11-21 14:34:37.760617	2025-11-21 14:34:37.760617
233	Cañete	11	2025-11-21 14:34:37.764615	2025-11-21 14:34:37.764615
234	Contulmo	11	2025-11-21 14:34:37.768386	2025-11-21 14:34:37.768386
235	Curanilahue	11	2025-11-21 14:34:37.772168	2025-11-21 14:34:37.772168
236	Los Álamos	11	2025-11-21 14:34:37.776057	2025-11-21 14:34:37.776057
237	Tirúa	11	2025-11-21 14:34:37.779932	2025-11-21 14:34:37.779932
238	Los Ángeles	11	2025-11-21 14:34:37.784396	2025-11-21 14:34:37.784396
239	Antuco	11	2025-11-21 14:34:37.788277	2025-11-21 14:34:37.788277
240	Cabrero	11	2025-11-21 14:34:37.792199	2025-11-21 14:34:37.792199
241	Laja	11	2025-11-21 14:34:37.796025	2025-11-21 14:34:37.796025
242	Mulchén	11	2025-11-21 14:34:37.80221	2025-11-21 14:34:37.80221
243	Nacimiento	11	2025-11-21 14:34:37.80633	2025-11-21 14:34:37.80633
244	Negrete	11	2025-11-21 14:34:37.811069	2025-11-21 14:34:37.811069
245	Quilaco	11	2025-11-21 14:34:37.815278	2025-11-21 14:34:37.815278
246	Quilleco	11	2025-11-21 14:34:37.819871	2025-11-21 14:34:37.819871
247	San Rosendo	11	2025-11-21 14:34:37.824519	2025-11-21 14:34:37.824519
248	Santa Bárbara	11	2025-11-21 14:34:37.828764	2025-11-21 14:34:37.828764
249	Tucapel	11	2025-11-21 14:34:37.832971	2025-11-21 14:34:37.832971
250	Yumbel	11	2025-11-21 14:34:37.837134	2025-11-21 14:34:37.837134
251	Alto Biobío	11	2025-11-21 14:34:37.840872	2025-11-21 14:34:37.840872
252	Temuco	12	2025-11-21 14:34:37.849349	2025-11-21 14:34:37.849349
253	Carahue	12	2025-11-21 14:34:37.854274	2025-11-21 14:34:37.854274
254	Cunco	12	2025-11-21 14:34:37.85843	2025-11-21 14:34:37.85843
255	Curarrehue	12	2025-11-21 14:34:37.86249	2025-11-21 14:34:37.86249
256	Freire	12	2025-11-21 14:34:37.866333	2025-11-21 14:34:37.866333
257	Galvarino	12	2025-11-21 14:34:37.870254	2025-11-21 14:34:37.870254
258	Gorbea	12	2025-11-21 14:34:37.874073	2025-11-21 14:34:37.874073
259	Lautaro	12	2025-11-21 14:34:37.878136	2025-11-21 14:34:37.878136
260	Loncoche	12	2025-11-21 14:34:37.882634	2025-11-21 14:34:37.882634
261	Melipeuco	12	2025-11-21 14:34:37.88664	2025-11-21 14:34:37.88664
262	Nueva Imperial	12	2025-11-21 14:34:37.890637	2025-11-21 14:34:37.890637
263	Padre Las Casas	12	2025-11-21 14:34:37.894701	2025-11-21 14:34:37.894701
264	Perquenco	12	2025-11-21 14:34:37.898542	2025-11-21 14:34:37.898542
265	Pitrufquén	12	2025-11-21 14:34:37.902763	2025-11-21 14:34:37.902763
266	Pucón	12	2025-11-21 14:34:37.906569	2025-11-21 14:34:37.906569
267	Saavedra	12	2025-11-21 14:34:37.910416	2025-11-21 14:34:37.910416
268	Teodoro Schmidt	12	2025-11-21 14:34:37.914752	2025-11-21 14:34:37.914752
269	Toltén	12	2025-11-21 14:34:37.919374	2025-11-21 14:34:37.919374
270	Vilcún	12	2025-11-21 14:34:37.923743	2025-11-21 14:34:37.923743
271	Villarrica	12	2025-11-21 14:34:37.928109	2025-11-21 14:34:37.928109
272	Cholchol	12	2025-11-21 14:34:37.932571	2025-11-21 14:34:37.932571
273	Angol	12	2025-11-21 14:34:37.936964	2025-11-21 14:34:37.936964
274	Collipulli	12	2025-11-21 14:34:37.941307	2025-11-21 14:34:37.941307
275	Curacautín	12	2025-11-21 14:34:37.946553	2025-11-21 14:34:37.946553
276	Ercilla	12	2025-11-21 14:34:37.950864	2025-11-21 14:34:37.950864
277	Lonquimay	12	2025-11-21 14:34:37.955246	2025-11-21 14:34:37.955246
278	Los Sauces	12	2025-11-21 14:34:37.959514	2025-11-21 14:34:37.959514
279	Lumaco	12	2025-11-21 14:34:37.963723	2025-11-21 14:34:37.963723
280	Purén	12	2025-11-21 14:34:37.968137	2025-11-21 14:34:37.968137
281	Renaico	12	2025-11-21 14:34:37.972279	2025-11-21 14:34:37.972279
282	Traiguén	12	2025-11-21 14:34:37.976782	2025-11-21 14:34:37.976782
283	Victoria	12	2025-11-21 14:34:37.981679	2025-11-21 14:34:37.981679
284	Valdivia	13	2025-11-21 14:34:37.991667	2025-11-21 14:34:37.991667
285	Corral	13	2025-11-21 14:34:37.996585	2025-11-21 14:34:37.996585
286	Lanco	13	2025-11-21 14:34:38.000649	2025-11-21 14:34:38.000649
287	Los Lagos	13	2025-11-21 14:34:38.004689	2025-11-21 14:34:38.004689
288	Máfil	13	2025-11-21 14:34:38.009191	2025-11-21 14:34:38.009191
289	Mariquina	13	2025-11-21 14:34:38.013706	2025-11-21 14:34:38.013706
290	Paillaco	13	2025-11-21 14:34:38.018365	2025-11-21 14:34:38.018365
291	Panguipulli	13	2025-11-21 14:34:38.023059	2025-11-21 14:34:38.023059
292	La Unión	13	2025-11-21 14:34:38.027394	2025-11-21 14:34:38.027394
293	Futrono	13	2025-11-21 14:34:38.031292	2025-11-21 14:34:38.031292
294	Lago Ranco	13	2025-11-21 14:34:38.035299	2025-11-21 14:34:38.035299
295	Río Bueno	13	2025-11-21 14:34:38.039712	2025-11-21 14:34:38.039712
296	Puerto Montt	14	2025-11-21 14:34:38.050053	2025-11-21 14:34:38.050053
297	Calbuco	14	2025-11-21 14:34:38.054723	2025-11-21 14:34:38.054723
298	Cochamó	14	2025-11-21 14:34:38.05932	2025-11-21 14:34:38.05932
299	Fresia	14	2025-11-21 14:34:38.063485	2025-11-21 14:34:38.063485
300	Frutillar	14	2025-11-21 14:34:38.067465	2025-11-21 14:34:38.067465
301	Los Muermos	14	2025-11-21 14:34:38.071746	2025-11-21 14:34:38.071746
302	Llanquihue	14	2025-11-21 14:34:38.076244	2025-11-21 14:34:38.076244
303	Maullín	14	2025-11-21 14:34:38.080479	2025-11-21 14:34:38.080479
304	Puerto Varas	14	2025-11-21 14:34:38.085157	2025-11-21 14:34:38.085157
305	Castro	14	2025-11-21 14:34:38.089414	2025-11-21 14:34:38.089414
306	Ancud	14	2025-11-21 14:34:38.093358	2025-11-21 14:34:38.093358
307	Chonchi	14	2025-11-21 14:34:38.097688	2025-11-21 14:34:38.097688
308	Curaco de Vélez	14	2025-11-21 14:34:38.101452	2025-11-21 14:34:38.101452
309	Dalcahue	14	2025-11-21 14:34:38.105224	2025-11-21 14:34:38.105224
310	Puqueldón	14	2025-11-21 14:34:38.109191	2025-11-21 14:34:38.109191
311	Queilén	14	2025-11-21 14:34:38.113051	2025-11-21 14:34:38.113051
312	Quellón	14	2025-11-21 14:34:38.117458	2025-11-21 14:34:38.117458
313	Quemchi	14	2025-11-21 14:34:38.121722	2025-11-21 14:34:38.121722
314	Quinchao	14	2025-11-21 14:34:38.125615	2025-11-21 14:34:38.125615
315	Osorno	14	2025-11-21 14:34:38.129386	2025-11-21 14:34:38.129386
316	Puerto Octay	14	2025-11-21 14:34:38.133211	2025-11-21 14:34:38.133211
317	Purranque	14	2025-11-21 14:34:38.137217	2025-11-21 14:34:38.137217
318	Puyehue	14	2025-11-21 14:34:38.141941	2025-11-21 14:34:38.141941
319	Río Negro	14	2025-11-21 14:34:38.147802	2025-11-21 14:34:38.147802
320	San Juan de la Costa	14	2025-11-21 14:34:38.152526	2025-11-21 14:34:38.152526
321	San Pablo	14	2025-11-21 14:34:38.157172	2025-11-21 14:34:38.157172
322	Chaitén	14	2025-11-21 14:34:38.161989	2025-11-21 14:34:38.161989
323	Futaleufú	14	2025-11-21 14:34:38.166213	2025-11-21 14:34:38.166213
324	Hualaihué	14	2025-11-21 14:34:38.170614	2025-11-21 14:34:38.170614
325	Palena	14	2025-11-21 14:34:38.175305	2025-11-21 14:34:38.175305
326	Coyhaique	15	2025-11-21 14:34:38.185494	2025-11-21 14:34:38.185494
327	Lago Verde	15	2025-11-21 14:34:38.190264	2025-11-21 14:34:38.190264
328	Aysén	15	2025-11-21 14:34:38.194536	2025-11-21 14:34:38.194536
329	Cisnes	15	2025-11-21 14:34:38.198985	2025-11-21 14:34:38.198985
330	Guaitecas	15	2025-11-21 14:34:38.203031	2025-11-21 14:34:38.203031
331	Cochrane	15	2025-11-21 14:34:38.207003	2025-11-21 14:34:38.207003
332	O'Higgins	15	2025-11-21 14:34:38.210973	2025-11-21 14:34:38.210973
333	Tortel	15	2025-11-21 14:34:38.214897	2025-11-21 14:34:38.214897
334	Chile Chico	15	2025-11-21 14:34:38.220302	2025-11-21 14:34:38.220302
335	Río Ibáñez	15	2025-11-21 14:34:38.224779	2025-11-21 14:34:38.224779
336	Punta Arenas	16	2025-11-21 14:34:38.235237	2025-11-21 14:34:38.235237
337	Laguna Blanca	16	2025-11-21 14:34:38.239846	2025-11-21 14:34:38.239846
338	Río Verde	16	2025-11-21 14:34:38.244314	2025-11-21 14:34:38.244314
339	San Gregorio	16	2025-11-21 14:34:38.249528	2025-11-21 14:34:38.249528
340	Cabo de Hornos	16	2025-11-21 14:34:38.255442	2025-11-21 14:34:38.255442
341	Antártica	16	2025-11-21 14:34:38.259791	2025-11-21 14:34:38.259791
342	Porvenir	16	2025-11-21 14:34:38.264184	2025-11-21 14:34:38.264184
343	Primavera	16	2025-11-21 14:34:38.268736	2025-11-21 14:34:38.268736
344	Timaukel	16	2025-11-21 14:34:38.272724	2025-11-21 14:34:38.272724
345	Natales	16	2025-11-21 14:34:38.277015	2025-11-21 14:34:38.277015
346	Torres del Paine	16	2025-11-21 14:34:38.281484	2025-11-21 14:34:38.281484
347	Til Til	7	2025-11-21 19:22:19.861395	2025-11-21 19:22:19.861395
\.


--
-- Data for Name: packages; Type: TABLE DATA; Schema: public; Owner: omen
--

COPY public.packages (id, customer_name, company, address, description, created_at, updated_at, user_id, phone, exchange, loading_date, region_id, commune_id, status, cancelled_at, cancellation_reason, amount, tracking_code, previous_status, status_history, location, attempts_count, assigned_courier_id, proof, reprogramed_to, reprogram_motive, picked_at, shipped_at, delivered_at, admin_override, bulk_upload_id) FROM stdin;
1	Cliente de Customer1 1	customer1@example.com	Calle Providencia 838	Paquete de prueba para customer1	2025-11-21 14:34:39.566727	2025-11-21 14:34:39.566727	2	+56923382098	f	2025-11-28	7	128	0	\N	\N	0.00	PKG-52425878467090	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
2	Cliente de Customer1 2	customer1@example.com	Calle Las Rosas 454	Paquete de prueba para customer1	2025-11-21 14:34:39.57769	2025-11-21 14:34:39.57769	2	+56991632192	f	2025-11-24	7	113	0	\N	\N	0.00	PKG-72772258932405	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
4	Cliente de Customer1 4	customer1@example.com	Calle Alameda 6703	Paquete de prueba para customer1	2025-11-21 14:34:39.594844	2025-11-21 14:34:39.594844	2	+56932679464	t	2025-11-27	7	124	0	\N	\N	0.00	PKG-84330101357777	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
5	Cliente de Customer1 5	customer1@example.com	Calle Providencia 7139	Paquete de prueba para customer1	2025-11-21 14:34:39.600992	2025-11-21 14:34:39.600992	2	+56962327185	f	2025-12-02	7	93	0	\N	\N	0.00	PKG-38650933940791	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
6	Cliente de Customer2 1	customer2@example.com	Av. Kennedy 7050	Paquete de prueba para customer2	2025-11-21 14:34:39.60776	2025-11-21 14:34:39.60776	3	+56942654000	f	2025-11-22	7	134	0	\N	\N	0.00	PKG-36583612349672	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
7	Cliente de Customer2 2	customer2@example.com	Av. Apoquindo 5923	Paquete de prueba para customer2	2025-11-21 14:34:39.613541	2025-11-21 14:34:39.613541	3	+56985481631	f	2025-11-24	7	100	0	\N	\N	0.00	PKG-84219423793964	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
9	Cliente de Customer3 1	customer3@example.com	Pasaje Las Acacias 408	Paquete de prueba para customer3	2025-11-21 14:34:39.625382	2025-11-21 14:34:39.625382	4	+56960222472	f	2025-11-23	7	98	0	\N	\N	0.00	PKG-46449449187824	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
10	Cliente de Customer3 2	customer3@example.com	Pasaje El Bosque 399	Paquete de prueba para customer3	2025-11-21 14:34:39.632388	2025-11-21 14:34:39.632388	4	+56921972084	f	2025-11-22	7	115	0	\N	\N	0.00	PKG-74701475990935	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
11	Cliente Admin 1	admin@paqueteria.com	Avenida 49 Norte 6927	Paquete gestionado por admin	2025-11-21 14:34:39.638925	2025-11-21 14:34:39.638925	1	+56971526309	f	2025-11-28	7	92	0	\N	\N	0.00	PKG-44990405826931	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
12	Cliente Admin 2	admin@paqueteria.com	Paseo 12 Norte 5429	Paquete gestionado por admin	2025-11-21 14:34:39.644903	2025-11-21 14:34:39.644903	1	+56976480050	f	2025-12-01	7	115	0	\N	\N	0.00	PKG-89980072760314	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
13	Cliente Admin 3	admin@paqueteria.com	Avenida 43 Norte 9204	Paquete gestionado por admin	2025-11-21 14:34:39.650795	2025-11-21 14:34:39.650795	1	+56996155835	f	2025-11-25	7	134	0	\N	\N	0.00	PKG-09428409345112	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
14	Cliente Admin 4	admin@paqueteria.com	Calle 14 Norte 8223	Paquete gestionado por admin	2025-11-21 14:34:39.656505	2025-11-21 14:34:39.656505	1	+56958994883	f	2025-12-01	7	108	0	\N	\N	0.00	PKG-40798231304207	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
15	Cliente Admin 5	admin@paqueteria.com	Calle 1 Norte 8582	Paquete gestionado por admin	2025-11-21 14:34:39.661805	2025-11-21 14:34:39.661805	1	+56938342092	t	2025-11-24	7	102	0	\N	\N	0.00	PKG-69010680713122	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
27	Camilo 1	\N	Segoviano	algo nuevoo	2025-11-23 15:25:56.093405	2025-11-23 15:25:56.093405	3	+56930762570	f	2025-11-23	7	105	0	\N	\N	100.00	PKG-20932535775372	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
28	Cristina 1	\N	ninune	algo puede	2025-11-23 15:25:56.101426	2025-11-23 15:25:56.101426	3	+56930762571	f	2025-11-24	7	102	0	\N	\N	0.00	PKG-13614398063716	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
3	Cliente de Customer1 3	customer1@example.com	Calle Las Rosas 2529	Paquete de prueba para customer	2025-11-21 14:34:39.585473	2025-11-21 16:37:36.660856	2	+56912815910	t	2025-12-05	7	130	0	\N	\N	1000.00	PKG-10523198650885	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
16	Johan Ramirez	luzmdiaz20231@gmail.com	vicuña Mackenna 1947	sdfgasgsdgsad	2025-11-21 16:42:32.190329	2025-11-21 16:45:27.222062	9	+56930762570	f	2025-11-21	7	93	0	\N	\N	1000.00	PKG-26688553871765	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
17	Juan Pérez	luzmdiaz20231@gmail.com	Av. Providencia 123	Paquete con ropa	2025-11-21 19:29:22.783663	2025-11-21 19:29:22.783663	1	+56912345678	f	2025-11-21	7	105	0	\N	\N	15000.00	Pkg-242352523532	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
20	María González	luzmdiaz20231@gmail.com	Los Leones 456	Electrónicos	2025-11-21 19:29:22.802934	2025-11-21 19:29:22.802934	1	+56987654321	t	2025-11-21	7	96	0	\N	\N	25000.00	Pkg-12423456367	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
22	Pedro Ramírez	luzmdiaz20231@gmail.com	Santa Rosa 789	Libros	2025-11-21 19:29:22.815506	2025-11-21 19:29:22.815506	1	+56956781234	f	2025-11-21	7	92	0	\N	\N	8000.00	Pkg-2454525235235	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
19	Luis	marca	Segoviano	algo nuevi	2025-11-21 19:29:22.786748	2025-11-21 19:37:56.060411	9	+56930762570	f	2025-11-21	7	105	0	\N	\N	100.00	PKG-85846559050461	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
8	Cliente de Customer2	customer2@example.com	Av. Kennedy 1908	Paquete de prueba para customer2	2025-11-21 14:34:39.618972	2025-11-23 14:29:22.769278	3	+56989705773	f	2025-11-28	7	95	0	\N	\N	0.00	PKG-38906555935809	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
24	Camilo 1	\N	Segoviano	algo nuevoo	2025-11-23 15:25:01.381471	2025-11-23 15:25:01.381471	3	+56930762570	f	2025-11-23	7	105	0	\N	\N	100.00	PKG-37192561358800	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
25	Cristina 1	\N	ninune	algo puede	2025-11-23 15:25:01.392513	2025-11-23 15:25:01.392513	3	+56930762571	f	2025-11-24	7	102	0	\N	\N	0.00	PKG-74733626567046	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
26	Carlos 1	\N	rasaz	rata	2025-11-23 15:25:01.403454	2025-11-23 15:25:01.403454	3	+56930762572	f	2025-11-25	7	96	0	\N	\N	0.00	PKG-21093713030841	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
29	Carlos 1	\N	rasaz	rata	2025-11-23 15:25:56.111561	2025-11-23 15:25:56.111561	3	+56930762572	f	2025-11-25	7	96	0	\N	\N	0.00	PKG-62969856338162	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
30	Camilo 1	\N	Segoviano	algo nuevoo	2025-11-23 15:32:08.113531	2025-11-23 15:32:08.113531	3	+56930762570	f	2025-11-23	7	105	0	\N	\N	100.00	PKG-08964996520695	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
31	Cristina 1	\N	ninune	algo puede	2025-11-23 15:32:08.120789	2025-11-23 15:32:08.120789	3	+56930762571	f	2025-11-24	7	102	0	\N	\N	0.00	PKG-31534565484404	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
32	Carlos 1	\N	rasaz	rata	2025-11-23 15:32:08.126527	2025-11-23 15:32:08.126527	3	+56930762572	t	2025-11-25	7	96	0	\N	\N	0.00	PKG-71777026473936	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
33	Cristina 1	\N	ninune	algo puede	2025-11-24 13:53:33.052411	2025-11-24 13:53:33.052411	3	+56930762571	t	2025-11-24	7	102	0	\N	\N	0.00	PKG-67539312947419	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
34	Carlos 1	\N	rasaz	rata	2025-11-24 13:53:33.059216	2025-11-24 13:53:33.059216	3	+56930762572	t	2025-11-25	7	96	0	\N	\N	0.00	PKG-99287245579880	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
35	Ana Soto	\N	avenida 1	entrega rápida	2025-11-24 13:53:33.06487	2025-11-24 13:53:33.06487	3	+56930762573	t	2025-11-26	7	105	0	\N	\N	500.00	PKG-02649419488804	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
36	Luis Rojas	\N	calle sur 22	paquete frágil	2025-11-24 13:53:33.07055	2025-11-24 13:53:33.07055	3	+56930762574	t	2025-11-27	7	102	0	\N	\N	320.00	PKG-97334871151100	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
37	María Vera	\N	los pinos 44	documentos	2025-11-24 13:53:33.076356	2025-11-24 13:53:33.076356	3	+56930762575	t	2025-11-28	7	92	0	\N	\N	90.00	PKG-92309445079767	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
38	Pablo Díaz	\N	oro verde 11	hogar	2025-11-24 13:53:33.082281	2025-11-24 13:53:33.082281	3	+56930762576	t	2025-11-29	7	115	0	\N	\N	0.00	PKG-06407782900679	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
39	Daniela Paz	\N	central 98	solicitud nueva	2025-11-24 13:53:33.088171	2025-11-24 13:53:33.088171	3	+56930762577	t	2025-11-30	7	105	0	\N	\N	245.00	PKG-70425787599595	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
40	José Toro	\N	rio azul 9	compra online	2025-11-24 13:53:33.095907	2025-11-24 13:53:33.095907	3	+56930762578	t	2025-12-01	7	83	0	\N	\N	600.00	PKG-77465201082578	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
41	Carla Núñez	\N	pedro 33	prueba	2025-11-24 13:53:33.103834	2025-11-24 13:53:33.103834	3	+56930762579	t	2025-12-02	7	100	0	\N	\N	0.00	PKG-65068393017045	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
42	Marcos León	\N	avenida 2	último pedido	2025-11-24 13:53:33.109845	2025-11-24 13:53:33.109845	3	+56930762580	t	2025-12-03	7	105	0	\N	\N	350.00	PKG-87970098025915	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
43	Vanessa M	\N	los robles 77	caja pequeña	2025-11-24 13:53:33.115435	2025-11-24 13:53:33.115435	3	+56930762581	t	2025-12-04	7	102	0	\N	\N	180.00	PKG-69362694351365	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
44	Hugo Sáez	\N	mirador 12	ropa nueva	2025-11-24 13:53:33.121017	2025-11-24 13:53:33.121017	3	+56930762582	t	2025-12-05	7	96	0	\N	\N	0.00	PKG-26820814070674	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
45	Elena Cruz	\N	sur 14	delivery	2025-11-24 13:53:33.126133	2025-11-24 13:53:33.126133	3	+56930762583	t	2025-12-06	7	92	0	\N	\N	0.00	PKG-25330013346777	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
46	Ricardo V	\N	norte 8	encargo urgente	2025-11-24 13:53:33.13216	2025-11-24 13:53:33.13216	3	+56930762584	t	2025-12-07	7	83	0	\N	\N	700.00	PKG-87839729198092	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
47	Sonia Pinto	\N	colón 334	accesorios	2025-11-24 13:53:33.137496	2025-11-24 13:53:33.137496	3	+56930762585	t	2025-12-08	7	105	0	\N	\N	0.00	PKG-19278548967205	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
48	Andrés G	\N	puente 9	libro	2025-11-24 13:53:33.1434	2025-11-24 13:53:33.1434	3	+56930762586	t	2025-12-09	7	115	0	\N	\N	0.00	PKG-26054946206474	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
49	Karen Soto	\N	monjitas 22	autoparte	2025-11-24 13:53:33.149263	2025-11-24 13:53:33.149263	3	+56930762587	t	2025-12-10	7	83	0	\N	\N	0.00	PKG-21227852857728	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
50	Lorena V	\N	los sauces 8	artículo hogar	2025-11-24 13:53:33.154159	2025-11-24 13:53:33.154159	3	+56930762588	t	2025-12-11	7	102	0	\N	\N	160.00	PKG-82984011766440	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
51	Esteban R	\N	monte 66	producto nuevo	2025-11-24 13:53:33.159072	2025-11-24 13:53:33.159072	3	+56930762589	t	2025-12-12	7	96	0	\N	\N	260.00	PKG-49086560489182	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
52	Felipe N	\N	costanera 77	paquete chico	2025-11-24 13:53:33.165311	2025-11-24 13:53:33.165311	3	+56930762590	t	2025-12-13	7	105	0	\N	\N	115.00	PKG-48500704191255	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
53	Claudia S	\N	tramonto 34	envío estándar	2025-11-24 13:53:33.171635	2025-11-24 13:53:33.171635	3	+56930762591	t	2025-12-14	7	100	0	\N	\N	240.00	PKG-77995384411586	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
54	Matías L	\N	pasaje 5	solicitud cliente	2025-11-24 13:53:33.177403	2025-11-24 13:53:33.177403	3	+56930762592	t	2025-12-15	7	92	0	\N	\N	390.00	PKG-55144752552320	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
55	Susana J	\N	catedral 11	regalo	2025-11-24 13:53:33.18295	2025-11-24 13:53:33.18295	3	+56930762593	t	2025-12-16	7	83	0	\N	\N	0.00	PKG-93149560068413	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
56	Bernardo T	\N	los boldos 3	fragil	2025-11-24 13:53:33.188801	2025-11-24 13:53:33.188801	3	+56930762594	f	2025-12-17	7	105	0	\N	\N	0.00	PKG-19292745674040	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
57	Fabiola U	\N	sur alto 91	repuesto	2025-11-24 13:53:33.193971	2025-11-24 13:53:33.193971	3	+56930762595	f	2025-12-18	7	102	0	\N	\N	0.00	PKG-09548767728768	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
58	Sebastián Z	\N	avenida 4	envío rápido	2025-11-24 13:53:33.200545	2025-11-24 13:53:33.200545	3	+56930762596	f	2025-12-19	7	96	0	\N	\N	410.00	PKG-37125855975791	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
59	Nadia P	\N	norte chico 1	producto bebé	2025-11-24 13:53:33.207015	2025-11-24 13:53:33.207015	3	+56930762597	f	2025-12-20	7	83	0	\N	\N	150.00	PKG-71771337541125	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
60	Ramiro C	\N	los maquis 8	consulta	2025-11-24 13:53:33.212978	2025-11-24 13:53:33.212978	3	+56930762598	f	2025-12-21	7	92	0	\N	\N	200.00	PKG-51698191705060	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
61	Gabriela F	\N	krauss 10	electrónica	2025-11-24 13:53:33.218983	2025-11-24 13:53:33.218983	3	+56930762599	f	2025-12-22	7	105	0	\N	\N	0.00	PKG-38557547993695	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
62	Pedro M	\N	avenida 9	zapatos	2025-11-24 13:53:33.225211	2025-11-24 13:53:33.225211	3	+56930762600	f	2025-12-23	7	115	0	\N	\N	0.00	PKG-86612973532256	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
63	Brenda H	\N	luna 33	ropa	2025-11-24 13:53:33.231699	2025-11-24 13:53:33.231699	3	+56930762601	f	2025-12-24	7	100	0	\N	\N	0.00	PKG-00769829564681	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
64	Diego A	\N	sol 72	caja mediana	2025-11-24 13:53:33.238214	2025-11-24 13:53:33.238214	3	+56930762602	f	2025-12-25	7	102	0	\N	\N	315.00	PKG-63100223442903	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
65	Valentina Q	\N	carmen 8	utensilios	2025-11-24 13:53:33.245293	2025-11-24 13:53:33.245293	3	+56930762603	f	2025-12-26	7	83	0	\N	\N	0.00	PKG-96301881070846	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
66	Rodrigo P	\N	estrella 41	encomienda	2025-11-24 13:53:33.252754	2025-11-24 13:53:33.252754	3	+56930762604	f	2025-12-27	7	105	0	\N	\N	0.00	PKG-87460055450154	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
67	Sara K	\N	pedro 90	manual	2025-11-24 13:53:33.259469	2025-11-24 13:53:33.259469	3	+56930762605	f	2025-12-28	7	96	0	\N	\N	0.00	PKG-60539188761302	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
68	Juan A	\N	flora 19	teléfono	2025-11-24 13:53:33.265605	2025-11-24 13:53:33.265605	3	+56930762606	f	2025-12-29	7	102	0	\N	\N	0.00	PKG-13087749070337	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
69	Alicia G	\N	monteverde 8	accesorios	2025-11-24 13:53:33.271667	2025-11-24 13:53:33.271667	3	+56930762607	f	2025-12-30	7	100	0	\N	\N	0.00	PKG-30948976541517	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
70	Roberto Y	\N	angamos 3	compra online	2025-11-24 13:53:33.277853	2025-11-24 13:53:33.277853	3	+56930762608	f	2025-12-31	7	83	0	\N	\N	510.00	PKG-92894890700367	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
71	Lucía J	\N	santana 17	artículo oficina	2025-11-24 13:53:33.283611	2025-11-24 13:53:33.283611	3	+56930762609	f	2026-01-01	7	92	0	\N	\N	230.00	PKG-19146984875547	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
72	Gonzalo H	\N	paceo 91	pedido recurrente	2025-11-24 13:53:33.29042	2025-11-24 13:53:33.29042	3	+56930762610	f	2026-01-02	7	105	0	\N	\N	330.00	PKG-51072046621571	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
73	Mariela R	\N	avenida 12	ropa deportiva	2025-11-24 13:53:33.296342	2025-11-24 13:53:33.296342	3	+56930762611	f	2026-01-03	7	102	0	\N	\N	260.00	PKG-04721793627488	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
74	Joel D	\N	fast 55	producto importado	2025-11-24 13:53:33.301627	2025-11-24 13:53:33.301627	3	+56930762612	f	2026-01-04	7	115	0	\N	\N	720.00	PKG-14556011651039	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
75	Mónica T	\N	tribuna 90	dispositivo	2025-11-24 13:53:33.30713	2025-11-24 13:53:33.30713	3	+56930762613	f	2026-01-05	7	100	0	\N	\N	0.00	PKG-17671494465823	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
76	Patricio S	\N	balmaceda 99	regalo cliente	2025-11-24 13:53:33.313363	2025-11-24 13:53:33.313363	3	+56930762614	f	2026-01-06	7	83	0	\N	\N	195.00	PKG-59393050263725	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
77	Javiera K	\N	olmos 14	delivery express	2025-11-24 13:53:33.31915	2025-11-24 13:53:33.31915	3	+56930762615	f	2026-01-07	7	92	0	\N	\N	350.00	PKG-15979013871430	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
78	Ismael N	\N	teja sur 22	productos varios	2025-11-24 13:53:33.324587	2025-11-24 13:53:33.324587	3	+56930762616	f	2026-01-08	7	105	0	\N	\N	430.00	PKG-62074017874946	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
79	Beatriz O	\N	urmeneta 1	agua embotellada	2025-11-24 13:53:33.329931	2025-11-24 13:53:33.329931	3	+56930762617	f	2026-01-09	7	102	0	\N	\N	90.00	PKG-43473760763179	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
80	Froilán Z	\N	comandante 7	libro de estudio	2025-11-24 13:53:33.335185	2025-11-24 13:53:33.335185	3	+56930762618	f	2026-01-10	7	96	0	\N	\N	240.00	PKG-48068468946262	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
81	Denisse Q	\N	ramón 88	petición especial	2025-11-24 13:53:33.34029	2025-11-24 13:53:33.34029	3	+56930762619	f	2026-01-11	7	83	0	\N	\N	610.00	PKG-49292484570661	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
82	Alan V	\N	rio alto 3	insumo médico	2025-11-24 13:53:33.345543	2025-11-24 13:53:33.345543	3	+56930762620	f	2026-01-12	7	92	0	\N	\N	980.00	PKG-91347654690354	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
83	Olga M	\N	quinta 4	vestuario	2025-11-24 13:53:33.350682	2025-11-24 13:53:33.350682	3	+56930762621	f	2026-01-13	7	105	0	\N	\N	0.00	PKG-49107161418374	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
84	Bastián E	\N	canal 87	envío simple	2025-11-24 13:53:33.3559	2025-11-24 13:53:33.3559	3	+56930762622	f	2026-01-14	7	102	0	\N	\N	130.00	PKG-49501065267409	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
85	Ximena T	\N	canto 11	caja gigante	2025-11-24 13:53:33.361049	2025-11-24 13:53:33.361049	3	+56930762623	f	2026-01-15	7	100	0	\N	\N	540.00	PKG-98608799700992	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
86	César L	\N	alto sur 2	entrega express	2025-11-24 13:53:33.36613	2025-11-24 13:53:33.36613	3	+56930762624	f	2026-01-16	7	83	0	\N	\N	320.00	PKG-24357690359863	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
87	Florencia I	\N	patio 66	elemento frágil	2025-11-24 13:53:33.371465	2025-11-24 13:53:33.371465	3	+56930762625	f	2026-01-17	7	96	0	\N	\N	470.00	PKG-67383555605392	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
88	Jeremías F	\N	loma 17	pedido	2025-11-24 13:53:33.37721	2025-11-24 13:53:33.37721	3	+56930762626	f	2026-01-18	7	105	0	\N	\N	230.00	PKG-67054450384913	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
89	Carolina D	\N	los sauces 1	compra cliente	2025-11-24 13:53:33.38304	2025-11-24 13:53:33.38304	3	+56930762627	f	2026-01-19	7	102	0	\N	\N	160.00	PKG-20192530829063	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
90	Tomás G	\N	los acacios 9	pieza repuesto	2025-11-24 13:53:33.388576	2025-11-24 13:53:33.388576	3	+56930762628	f	2026-01-20	7	92	0	\N	\N	490.00	PKG-29100305565683	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
91	Romina H	\N	avenida 44	regalo sorpresa	2025-11-24 13:53:33.394195	2025-11-24 13:53:33.394195	3	+56930762629	f	2026-01-21	7	115	0	\N	\N	150.00	PKG-80450140704259	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
92	Gabriel C	\N	pedro II 8	objecto nuevo	2025-11-24 13:53:33.399562	2025-11-24 13:53:33.399562	3	+56930762630	f	2026-01-22	7	83	0	\N	\N	280.00	PKG-24334684414140	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
93	Fernanda P	\N	monte real 3	accesorio hogar	2025-11-24 13:53:33.4047	2025-11-24 13:53:33.4047	3	+56930762631	f	2026-01-23	7	96	0	\N	\N	330.00	PKG-92128322842879	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
94	Héctor M	\N	colón 81	producto digital	2025-11-24 13:53:33.410312	2025-11-24 13:53:33.410312	3	+56930762632	f	2026-01-24	7	105	0	\N	\N	525.00	PKG-40857227566632	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
95	Paola Y	\N	estrella 33	pañales	2025-11-24 13:53:33.415927	2025-11-24 13:53:33.415927	3	+56930762633	f	2026-01-25	7	102	0	\N	\N	0.00	PKG-25067460644808	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
96	Ángel A	\N	sol 100	alimento	2025-11-24 13:53:33.421619	2025-11-24 13:53:33.421619	3	+56930762634	f	2026-01-26	7	92	0	\N	\N	0.00	PKG-09980927095499	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
97	Yesenia L	\N	avenida 7	bebida	2025-11-24 13:53:33.426854	2025-11-24 13:53:33.426854	3	+56930762635	f	2026-01-27	7	100	0	\N	\N	0.00	PKG-03343066838736	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
98	Rafael O	\N	oro 55	solicitud general	2025-11-24 13:53:33.432367	2025-11-24 13:53:33.432367	3	+56930762636	f	2026-01-28	7	83	0	\N	\N	150.00	PKG-39643228211368	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
99	Valery R	\N	verde 44	producto gourmet	2025-11-24 13:53:33.438228	2025-11-24 13:53:33.438228	3	+56930762637	f	2026-01-29	7	105	0	\N	\N	740.00	PKG-83655525185122	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
100	Cristóbal T	\N	central 19	repuesto auto	2025-11-24 13:53:33.444218	2025-11-24 13:53:33.444218	3	+56930762638	f	2026-01-30	7	96	0	\N	\N	350.00	PKG-67480488318762	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
101	Lina J	\N	pedregal 11	insumo técnico	2025-11-24 13:53:33.449963	2025-11-24 13:53:33.449963	3	+56930762639	f	2026-01-31	7	102	0	\N	\N	275.00	PKG-07817899815602	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
102	Maximiliano B	\N	rio 90	accesorio gamer	2025-11-24 13:53:33.456115	2025-11-24 13:53:33.456115	3	+56930762640	f	2026-02-01	7	92	0	\N	\N	510.00	PKG-81939265024528	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
103	Pilar E	\N	lagos 82	objeto hogar	2025-11-24 13:53:33.461803	2025-11-24 13:53:33.461803	3	+56930762641	f	2026-02-02	7	83	0	\N	\N	200.00	PKG-24413136474610	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
104	Tadeo P	\N	costa azul 5	pedido interno	2025-11-24 13:53:33.467652	2025-11-24 13:53:33.467652	3	+56930762642	f	2026-02-03	7	105	0	\N	\N	330.00	PKG-14819034201075	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
105	Agustina L	\N	montaña 2	mueble pequeño	2025-11-24 13:53:33.473673	2025-11-24 13:53:33.473673	3	+56930762643	f	2026-02-04	7	96	0	\N	\N	780.00	PKG-23225147425808	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
106	Julián F	\N	avenida 5	pedido rápido	2025-11-24 13:53:33.483094	2025-11-24 13:53:33.483094	3	+56930762644	f	2026-02-05	7	102	0	\N	\N	120.00	PKG-28407005180155	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
107	Marta A	\N	luna 7	mercadería	2025-11-24 13:53:33.491302	2025-11-24 13:53:33.491302	3	+56930762645	f	2026-02-06	7	115	0	\N	\N	0.00	PKG-69898629751880	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
108	Leandro D	\N	avenida 15	ropa invierno	2025-11-24 13:53:33.499998	2025-11-24 13:53:33.499998	3	+56930762646	f	2026-02-07	7	100	0	\N	\N	290.00	PKG-71880560096025	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
109	Emilia G	\N	pasaje 8	perfume	2025-11-24 13:53:33.508089	2025-11-24 13:53:33.508089	3	+56930762647	f	2026-02-08	7	83	0	\N	\N	0.00	PKG-32847565420100	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
110	Benjamín C	\N	bosque 17	artículo cocina	2025-11-24 13:53:33.514345	2025-11-24 13:53:33.514345	3	+56930762648	f	2026-02-09	7	105	0	\N	\N	230.00	PKG-76695888406137	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
111	Inés H	\N	cerro 88	producto nuevo	2025-11-24 13:53:33.520096	2025-11-24 13:53:33.520096	3	+56930762649	f	2026-02-10	7	92	0	\N	\N	480.00	PKG-51937367067707	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
112	Alonso T	\N	rio largo 22	insumo técnico	2025-11-24 13:53:33.526431	2025-11-24 13:53:33.526431	3	+56930762650	f	2026-02-11	7	102	0	\N	\N	310.00	PKG-93871074566190	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
113	Constanza Y	\N	ruta 44	accesorio hogar	2025-11-24 13:53:33.532106	2025-11-24 13:53:33.532106	3	+56930762651	f	2026-02-12	7	115	0	\N	\N	160.00	PKG-53026567975967	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
114	Kevin M	\N	croacia 5	caja pequeña	2025-11-24 13:53:33.538312	2025-11-24 13:53:33.538312	3	+56930762652	f	2026-02-13	7	83	0	\N	\N	120.00	PKG-96749477399677	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
115	Aranza R	\N	loto 66	juguete	2025-11-24 13:53:33.543789	2025-11-24 13:53:33.543789	3	+56930762653	f	2026-02-14	7	96	0	\N	\N	0.00	PKG-08903233714921	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
116	Thiago S	\N	avenida 99	comida	2025-11-24 13:53:33.549443	2025-11-24 13:53:33.549443	3	+56930762654	f	2026-02-15	7	105	0	\N	\N	0.00	PKG-95282034169865	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
117	Juan José L	\N	faro 3	lámpara	2025-11-24 13:53:33.554706	2025-11-24 13:53:33.554706	3	+56930762655	f	2026-02-16	7	102	0	\N	\N	0.00	PKG-33754241581534	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
118	Fernanda C	\N	pedro 6	productos varios	2025-11-24 13:53:33.560051	2025-11-24 13:53:33.560051	3	+56930762656	f	2026-02-17	7	83	0	\N	\N	140.00	PKG-51682244515124	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
119	Elías U	\N	calle 10	notebook	2025-11-24 13:53:33.565364	2025-11-24 13:53:33.565364	3	+56930762657	f	2026-02-18	7	100	0	\N	\N	0.00	PKG-33707027021128	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
120	Trinidad M	\N	carmen 77	artículos bebés	2025-11-24 13:53:33.570669	2025-11-24 13:53:33.570669	3	+56930762658	f	2026-02-19	7	92	0	\N	\N	260.00	PKG-69395289990637	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
121	Alfredo Z	\N	subida 4	implementos	2025-11-24 13:53:33.575986	2025-11-24 13:53:33.575986	3	+56930762659	f	2026-02-20	7	96	0	\N	\N	0.00	PKG-69547464308860	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
122	Romina B	\N	rosales 11	accesorio auto	2025-11-24 13:53:33.581241	2025-11-24 13:53:33.581241	3	+56930762660	f	2026-02-21	7	105	0	\N	\N	180.00	PKG-88627138593952	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
123	Sherly V	\N	rio gris 2	té especial	2025-11-24 13:53:33.58663	2025-11-24 13:53:33.58663	3	+56930762661	f	2026-02-22	7	83	0	\N	\N	0.00	PKG-48532644031118	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
124	Leonardo H	\N	lira 44	servicio técnico	2025-11-24 13:53:33.592773	2025-11-24 13:53:33.592773	3	+56930762662	f	2026-02-23	7	102	0	\N	\N	520.00	PKG-74788626936961	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
125	Amparo J	\N	pedro 19	taza cerámica	2025-11-24 13:53:33.598359	2025-11-24 13:53:33.598359	3	+56930762663	f	2026-02-24	7	100	0	\N	\N	110.00	PKG-79128242374637	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
126	Elvira P	\N	rio profundo 1	insumos limpeza	2025-11-24 13:53:33.604219	2025-11-24 13:53:33.604219	3	+56930762664	f	2026-02-25	7	115	0	\N	\N	140.00	PKG-37331527874663	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
127	Oliver Y	\N	avenida 121	material oficina	2025-11-24 13:53:33.610147	2025-11-24 13:53:33.610147	3	+56930762665	f	2026-02-26	7	83	0	\N	\N	260.00	PKG-61631101902035	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
128	Selena A	\N	los cedros 3	plato vidrio	2025-11-24 13:53:33.615426	2025-11-24 13:53:33.615426	3	+56930762666	f	2026-02-27	7	92	0	\N	\N	130.00	PKG-33302940848667	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
129	Eduardo T	\N	ulmo 17	producto premium	2025-11-24 13:53:33.620829	2025-11-24 13:53:33.620829	3	+56930762667	f	2026-02-28	7	105	0	\N	\N	870.00	PKG-07409107329538	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
130	Rocío E	\N	lago azul 8	regalo especial	2025-11-24 13:53:33.625972	2025-11-24 13:53:33.625972	3	+56930762668	f	2026-03-01	7	96	0	\N	\N	190.00	PKG-05282520699402	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
131	Mario R	\N	arbustos 7	audífonos	2025-11-24 13:53:33.631546	2025-11-24 13:53:33.631546	3	+56930762669	f	2026-03-02	7	102	0	\N	\N	0.00	PKG-39154299389597	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
132	Cristina 1	\N	ninune	algo puede	2025-11-24 18:10:41.251238	2025-11-24 18:10:41.251238	3	+56930762571	t	2025-11-24	7	102	0	\N	\N	0.00	PKG-78358803112719	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
133	Cristina 1	\N	ninune	algo puede	2025-11-24 18:10:41.25281	2025-11-24 18:10:41.25281	3	+56930762571	t	2025-11-24	7	102	0	\N	\N	0.00	PKG-79653015481715	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
134	Carlos 1	\N	rasaz	rata	2025-11-24 18:10:41.261063	2025-11-24 18:10:41.261063	3	+56930762572	t	2025-11-25	7	96	0	\N	\N	0.00	PKG-70676735028627	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
135	Carlos 1	\N	rasaz	rata	2025-11-24 18:10:41.262463	2025-11-24 18:10:41.262463	3	+56930762572	t	2025-11-25	7	96	0	\N	\N	0.00	PKG-03747147332661	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
136	Ana Soto	\N	avenida 1	entrega rápida	2025-11-24 18:10:41.271216	2025-11-24 18:10:41.271216	3	+56930762573	t	2025-11-26	7	105	0	\N	\N	500.00	PKG-15219843016461	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
137	Ana Soto	\N	avenida 1	entrega rápida	2025-11-24 18:10:41.274025	2025-11-24 18:10:41.274025	3	+56930762573	t	2025-11-26	7	105	0	\N	\N	500.00	PKG-66439005701596	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
138	Luis Rojas	\N	calle sur 22	paquete frágil	2025-11-24 18:10:41.28108	2025-11-24 18:10:41.28108	3	+56930762574	t	2025-11-27	7	102	0	\N	\N	320.00	PKG-54790276681704	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
139	Luis Rojas	\N	calle sur 22	paquete frágil	2025-11-24 18:10:41.283744	2025-11-24 18:10:41.283744	3	+56930762574	t	2025-11-27	7	102	0	\N	\N	320.00	PKG-30624705076014	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
140	María Vera	\N	los pinos 44	documentos	2025-11-24 18:10:41.306651	2025-11-24 18:10:41.306651	3	+56930762575	t	2025-11-28	7	92	0	\N	\N	90.00	PKG-65929444327983	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
141	María Vera	\N	los pinos 44	documentos	2025-11-24 18:10:41.308009	2025-11-24 18:10:41.308009	3	+56930762575	t	2025-11-28	7	92	0	\N	\N	90.00	PKG-61956275978757	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
142	Pablo Díaz	\N	oro verde 11	hogar	2025-11-24 18:10:41.317786	2025-11-24 18:10:41.317786	3	+56930762576	t	2025-11-29	7	115	0	\N	\N	0.00	PKG-92215655069405	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
143	Pablo Díaz	\N	oro verde 11	hogar	2025-11-24 18:10:41.318166	2025-11-24 18:10:41.318166	3	+56930762576	t	2025-11-29	7	115	0	\N	\N	0.00	PKG-77847222815614	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
144	Daniela Paz	\N	central 98	solicitud nueva	2025-11-24 18:10:41.326235	2025-11-24 18:10:41.326235	3	+56930762577	t	2025-11-30	7	105	0	\N	\N	245.00	PKG-25814346547114	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
145	Daniela Paz	\N	central 98	solicitud nueva	2025-11-24 18:10:41.327643	2025-11-24 18:10:41.327643	3	+56930762577	t	2025-11-30	7	105	0	\N	\N	245.00	PKG-96466938985871	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
146	José Toro	\N	rio azul 9	compra online	2025-11-24 18:10:41.335968	2025-11-24 18:10:41.335968	3	+56930762578	t	2025-12-01	7	83	0	\N	\N	600.00	PKG-72584359672327	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
147	José Toro	\N	rio azul 9	compra online	2025-11-24 18:10:41.337217	2025-11-24 18:10:41.337217	3	+56930762578	t	2025-12-01	7	83	0	\N	\N	600.00	PKG-81698220919110	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
148	Carla Núñez	\N	pedro 33	prueba	2025-11-24 18:10:41.345396	2025-11-24 18:10:41.345396	3	+56930762579	t	2025-12-02	7	100	0	\N	\N	0.00	PKG-49457855634030	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
149	Carla Núñez	\N	pedro 33	prueba	2025-11-24 18:10:41.346674	2025-11-24 18:10:41.346674	3	+56930762579	t	2025-12-02	7	100	0	\N	\N	0.00	PKG-73917999160555	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
150	Marcos León	\N	avenida 2	último pedido	2025-11-24 18:10:41.35926	2025-11-24 18:10:41.35926	3	+56930762580	t	2025-12-03	7	105	0	\N	\N	350.00	PKG-76674973673822	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
151	Marcos León	\N	avenida 2	último pedido	2025-11-24 18:10:41.35987	2025-11-24 18:10:41.35987	3	+56930762580	t	2025-12-03	7	105	0	\N	\N	350.00	PKG-03367185581692	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
152	Vanessa M	\N	los robles 77	caja pequeña	2025-11-24 18:10:41.369886	2025-11-24 18:10:41.369886	3	+56930762581	t	2025-12-04	7	102	0	\N	\N	180.00	PKG-54127225076087	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
153	Vanessa M	\N	los robles 77	caja pequeña	2025-11-24 18:10:41.370499	2025-11-24 18:10:41.370499	3	+56930762581	t	2025-12-04	7	102	0	\N	\N	180.00	PKG-43197165432472	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
154	Hugo Sáez	\N	mirador 12	ropa nueva	2025-11-24 18:10:41.37945	2025-11-24 18:10:41.37945	3	+56930762582	t	2025-12-05	7	96	0	\N	\N	0.00	PKG-21200797873417	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
155	Hugo Sáez	\N	mirador 12	ropa nueva	2025-11-24 18:10:41.380963	2025-11-24 18:10:41.380963	3	+56930762582	t	2025-12-05	7	96	0	\N	\N	0.00	PKG-52438853886234	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
156	Elena Cruz	\N	sur 14	delivery	2025-11-24 18:10:41.389114	2025-11-24 18:10:41.389114	3	+56930762583	t	2025-12-06	7	92	0	\N	\N	0.00	PKG-32387323729262	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
157	Elena Cruz	\N	sur 14	delivery	2025-11-24 18:10:41.390781	2025-11-24 18:10:41.390781	3	+56930762583	t	2025-12-06	7	92	0	\N	\N	0.00	PKG-88926789045882	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
158	Ricardo V	\N	norte 8	encargo urgente	2025-11-24 18:10:41.398663	2025-11-24 18:10:41.398663	3	+56930762584	t	2025-12-07	7	83	0	\N	\N	700.00	PKG-09936896884010	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
159	Ricardo V	\N	norte 8	encargo urgente	2025-11-24 18:10:41.400254	2025-11-24 18:10:41.400254	3	+56930762584	t	2025-12-07	7	83	0	\N	\N	700.00	PKG-43731837478308	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
160	Sonia Pinto	\N	colón 334	accesorios	2025-11-24 18:10:41.411878	2025-11-24 18:10:41.411878	3	+56930762585	t	2025-12-08	7	105	0	\N	\N	0.00	PKG-49643867169076	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
161	Sonia Pinto	\N	colón 334	accesorios	2025-11-24 18:10:41.413538	2025-11-24 18:10:41.413538	3	+56930762585	t	2025-12-08	7	105	0	\N	\N	0.00	PKG-81325010504501	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
162	Andrés G	\N	puente 9	libro	2025-11-24 18:10:41.42168	2025-11-24 18:10:41.42168	3	+56930762586	t	2025-12-09	7	115	0	\N	\N	0.00	PKG-12543136813881	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
163	Andrés G	\N	puente 9	libro	2025-11-24 18:10:41.422934	2025-11-24 18:10:41.422934	3	+56930762586	t	2025-12-09	7	115	0	\N	\N	0.00	PKG-04409900557108	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
164	Karen Soto	\N	monjitas 22	autoparte	2025-11-24 18:10:41.433251	2025-11-24 18:10:41.433251	3	+56930762587	t	2025-12-10	7	83	0	\N	\N	0.00	PKG-64351023035205	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
165	Karen Soto	\N	monjitas 22	autoparte	2025-11-24 18:10:41.433626	2025-11-24 18:10:41.433626	3	+56930762587	t	2025-12-10	7	83	0	\N	\N	0.00	PKG-10756619879981	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
166	Lorena V	\N	los sauces 8	artículo hogar	2025-11-24 18:10:41.441864	2025-11-24 18:10:41.441864	3	+56930762588	t	2025-12-11	7	102	0	\N	\N	160.00	PKG-28342494233849	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
167	Lorena V	\N	los sauces 8	artículo hogar	2025-11-24 18:10:41.443133	2025-11-24 18:10:41.443133	3	+56930762588	t	2025-12-11	7	102	0	\N	\N	160.00	PKG-34221493050287	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
168	Esteban R	\N	monte 66	producto nuevo	2025-11-24 18:10:41.454189	2025-11-24 18:10:41.454189	3	+56930762589	t	2025-12-12	7	96	0	\N	\N	260.00	PKG-44593871992224	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
169	Esteban R	\N	monte 66	producto nuevo	2025-11-24 18:10:41.455279	2025-11-24 18:10:41.455279	3	+56930762589	t	2025-12-12	7	96	0	\N	\N	260.00	PKG-01728483322483	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
171	Felipe N	\N	costanera 77	paquete chico	2025-11-24 18:10:41.472433	2025-11-24 18:10:41.472433	3	+56930762590	t	2025-12-13	7	105	0	\N	\N	115.00	PKG-15292470875308	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
173	Claudia S	\N	tramonto 34	envío estándar	2025-11-24 18:10:41.483212	2025-11-24 18:10:41.483212	3	+56930762591	t	2025-12-14	7	100	0	\N	\N	240.00	PKG-67560500383613	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
175	Matías L	\N	pasaje 5	solicitud cliente	2025-11-24 18:10:41.494885	2025-11-24 18:10:41.494885	3	+56930762592	t	2025-12-15	7	92	0	\N	\N	390.00	PKG-76785035143148	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
177	Susana J	\N	catedral 11	regalo	2025-11-24 18:10:41.506209	2025-11-24 18:10:41.506209	3	+56930762593	t	2025-12-16	7	83	0	\N	\N	0.00	PKG-28140171628531	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
179	Bernardo T	\N	los boldos 3	fragil	2025-11-24 18:10:41.516242	2025-11-24 18:10:41.516242	3	+56930762594	f	2025-12-17	7	105	0	\N	\N	0.00	PKG-60156569059981	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
181	Fabiola U	\N	sur alto 91	repuesto	2025-11-24 18:10:41.530799	2025-11-24 18:10:41.530799	3	+56930762595	f	2025-12-18	7	102	0	\N	\N	0.00	PKG-86426761208521	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
183	Sebastián Z	\N	avenida 4	envío rápido	2025-11-24 18:10:41.541617	2025-11-24 18:10:41.541617	3	+56930762596	f	2025-12-19	7	96	0	\N	\N	410.00	PKG-27005675636086	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
185	Nadia P	\N	norte chico 1	producto bebé	2025-11-24 18:10:41.551617	2025-11-24 18:10:41.551617	3	+56930762597	f	2025-12-20	7	83	0	\N	\N	150.00	PKG-02305299745004	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
187	Ramiro C	\N	los maquis 8	consulta	2025-11-24 18:10:41.562607	2025-11-24 18:10:41.562607	3	+56930762598	f	2025-12-21	7	92	0	\N	\N	200.00	PKG-87127110923303	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
189	Gabriela F	\N	krauss 10	electrónica	2025-11-24 18:10:41.574009	2025-11-24 18:10:41.574009	3	+56930762599	f	2025-12-22	7	105	0	\N	\N	0.00	PKG-77906719370688	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
191	Pedro M	\N	avenida 9	zapatos	2025-11-24 18:10:41.588216	2025-11-24 18:10:41.588216	3	+56930762600	f	2025-12-23	7	115	0	\N	\N	0.00	PKG-07434992320393	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
193	Brenda H	\N	luna 33	ropa	2025-11-24 18:10:41.598844	2025-11-24 18:10:41.598844	3	+56930762601	f	2025-12-24	7	100	0	\N	\N	0.00	PKG-41484011531646	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
195	Diego A	\N	sol 72	caja mediana	2025-11-24 18:10:41.608745	2025-11-24 18:10:41.608745	3	+56930762602	f	2025-12-25	7	102	0	\N	\N	315.00	PKG-32805972514914	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
197	Valentina Q	\N	carmen 8	utensilios	2025-11-24 18:10:41.619424	2025-11-24 18:10:41.619424	3	+56930762603	f	2025-12-26	7	83	0	\N	\N	0.00	PKG-15055016905248	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
199	Rodrigo P	\N	estrella 41	encomienda	2025-11-24 18:10:41.632587	2025-11-24 18:10:41.632587	3	+56930762604	f	2025-12-27	7	105	0	\N	\N	0.00	PKG-42251697895861	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
201	Sara K	\N	pedro 90	manual	2025-11-24 18:10:41.646697	2025-11-24 18:10:41.646697	3	+56930762605	f	2025-12-28	7	96	0	\N	\N	0.00	PKG-01657827810850	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
203	Juan A	\N	flora 19	teléfono	2025-11-24 18:10:41.656602	2025-11-24 18:10:41.656602	3	+56930762606	f	2025-12-29	7	102	0	\N	\N	0.00	PKG-42015263381284	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
205	Alicia G	\N	monteverde 8	accesorios	2025-11-24 18:10:41.665887	2025-11-24 18:10:41.665887	3	+56930762607	f	2025-12-30	7	100	0	\N	\N	0.00	PKG-42713119476616	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
207	Roberto Y	\N	angamos 3	compra online	2025-11-24 18:10:41.676273	2025-11-24 18:10:41.676273	3	+56930762608	f	2025-12-31	7	83	0	\N	\N	510.00	PKG-16287778620155	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
209	Lucía J	\N	santana 17	artículo oficina	2025-11-24 18:10:41.686238	2025-11-24 18:10:41.686238	3	+56930762609	f	2026-01-01	7	92	0	\N	\N	230.00	PKG-01555414987192	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
211	Gonzalo H	\N	paceo 91	pedido recurrente	2025-11-24 18:10:41.701747	2025-11-24 18:10:41.701747	3	+56930762610	f	2026-01-02	7	105	0	\N	\N	330.00	PKG-06867277256087	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
213	Mariela R	\N	avenida 12	ropa deportiva	2025-11-24 18:10:41.712962	2025-11-24 18:10:41.712962	3	+56930762611	f	2026-01-03	7	102	0	\N	\N	260.00	PKG-57134474065358	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
215	Joel D	\N	fast 55	producto importado	2025-11-24 18:10:41.723661	2025-11-24 18:10:41.723661	3	+56930762612	f	2026-01-04	7	115	0	\N	\N	720.00	PKG-80311755985246	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
217	Mónica T	\N	tribuna 90	dispositivo	2025-11-24 18:10:41.73344	2025-11-24 18:10:41.73344	3	+56930762613	f	2026-01-05	7	100	0	\N	\N	0.00	PKG-83404721456370	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
219	Patricio S	\N	balmaceda 99	regalo cliente	2025-11-24 18:10:41.743517	2025-11-24 18:10:41.743517	3	+56930762614	f	2026-01-06	7	83	0	\N	\N	195.00	PKG-85491859415566	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
221	Javiera K	\N	olmos 14	delivery express	2025-11-24 18:10:41.760531	2025-11-24 18:10:41.760531	3	+56930762615	f	2026-01-07	7	92	0	\N	\N	350.00	PKG-95383600370720	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
223	Ismael N	\N	teja sur 22	productos varios	2025-11-24 18:10:41.771086	2025-11-24 18:10:41.771086	3	+56930762616	f	2026-01-08	7	105	0	\N	\N	430.00	PKG-43683402253812	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
225	Beatriz O	\N	urmeneta 1	agua embotellada	2025-11-24 18:10:41.782561	2025-11-24 18:10:41.782561	3	+56930762617	f	2026-01-09	7	102	0	\N	\N	90.00	PKG-13162256262230	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
227	Froilán Z	\N	comandante 7	libro de estudio	2025-11-24 18:10:41.792255	2025-11-24 18:10:41.792255	3	+56930762618	f	2026-01-10	7	96	0	\N	\N	240.00	PKG-37576200672300	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
229	Denisse Q	\N	ramón 88	petición especial	2025-11-24 18:10:41.801677	2025-11-24 18:10:41.801677	3	+56930762619	f	2026-01-11	7	83	0	\N	\N	610.00	PKG-32686391426403	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
231	Alan V	\N	rio alto 3	insumo médico	2025-11-24 18:10:41.815022	2025-11-24 18:10:41.815022	3	+56930762620	f	2026-01-12	7	92	0	\N	\N	980.00	PKG-98863116562127	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
233	Olga M	\N	quinta 4	vestuario	2025-11-24 18:10:41.826121	2025-11-24 18:10:41.826121	3	+56930762621	f	2026-01-13	7	105	0	\N	\N	0.00	PKG-83190845661496	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
235	Bastián E	\N	canal 87	envío simple	2025-11-24 18:10:41.835439	2025-11-24 18:10:41.835439	3	+56930762622	f	2026-01-14	7	102	0	\N	\N	130.00	PKG-81040921836057	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
237	Ximena T	\N	canto 11	caja gigante	2025-11-24 18:10:41.844888	2025-11-24 18:10:41.844888	3	+56930762623	f	2026-01-15	7	100	0	\N	\N	540.00	PKG-43493871296215	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
239	César L	\N	alto sur 2	entrega express	2025-11-24 18:10:41.854454	2025-11-24 18:10:41.854454	3	+56930762624	f	2026-01-16	7	83	0	\N	\N	320.00	PKG-69570574966869	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
241	Florencia I	\N	patio 66	elemento frágil	2025-11-24 18:10:41.867464	2025-11-24 18:10:41.867464	3	+56930762625	f	2026-01-17	7	96	0	\N	\N	470.00	PKG-95567151720367	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
242	Jeremías F	\N	loma 17	pedido	2025-11-24 18:10:41.876239	2025-11-24 18:10:41.876239	3	+56930762626	f	2026-01-18	7	105	0	\N	\N	230.00	PKG-72247977071711	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
244	Carolina D	\N	los sauces 1	compra cliente	2025-11-24 18:10:41.888319	2025-11-24 18:10:41.888319	3	+56930762627	f	2026-01-19	7	102	0	\N	\N	160.00	PKG-33763604844842	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
246	Tomás G	\N	los acacios 9	pieza repuesto	2025-11-24 18:10:41.897121	2025-11-24 18:10:41.897121	3	+56930762628	f	2026-01-20	7	92	0	\N	\N	490.00	PKG-50361108290952	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
248	Romina H	\N	avenida 44	regalo sorpresa	2025-11-24 18:10:41.906864	2025-11-24 18:10:41.906864	3	+56930762629	f	2026-01-21	7	115	0	\N	\N	150.00	PKG-98393889990883	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
250	Gabriel C	\N	pedro II 8	objecto nuevo	2025-11-24 18:10:41.920508	2025-11-24 18:10:41.920508	3	+56930762630	f	2026-01-22	7	83	0	\N	\N	280.00	PKG-51660272050737	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
170	Felipe N	\N	costanera 77	paquete chico	2025-11-24 18:10:41.470973	2025-11-24 18:10:41.470973	3	+56930762590	t	2025-12-13	7	105	0	\N	\N	115.00	PKG-56203208323036	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
172	Claudia S	\N	tramonto 34	envío estándar	2025-11-24 18:10:41.480709	2025-11-24 18:10:41.480709	3	+56930762591	t	2025-12-14	7	100	0	\N	\N	240.00	PKG-43388260009064	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
174	Matías L	\N	pasaje 5	solicitud cliente	2025-11-24 18:10:41.490509	2025-11-24 18:10:41.490509	3	+56930762592	t	2025-12-15	7	92	0	\N	\N	390.00	PKG-82548659877422	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
176	Susana J	\N	catedral 11	regalo	2025-11-24 18:10:41.502525	2025-11-24 18:10:41.502525	3	+56930762593	t	2025-12-16	7	83	0	\N	\N	0.00	PKG-73912612414771	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
178	Bernardo T	\N	los boldos 3	fragil	2025-11-24 18:10:41.513465	2025-11-24 18:10:41.513465	3	+56930762594	f	2025-12-17	7	105	0	\N	\N	0.00	PKG-15377875237910	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
180	Fabiola U	\N	sur alto 91	repuesto	2025-11-24 18:10:41.529114	2025-11-24 18:10:41.529114	3	+56930762595	f	2025-12-18	7	102	0	\N	\N	0.00	PKG-55646970831662	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
182	Sebastián Z	\N	avenida 4	envío rápido	2025-11-24 18:10:41.538965	2025-11-24 18:10:41.538965	3	+56930762596	f	2025-12-19	7	96	0	\N	\N	410.00	PKG-47344263772141	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
184	Nadia P	\N	norte chico 1	producto bebé	2025-11-24 18:10:41.549038	2025-11-24 18:10:41.549038	3	+56930762597	f	2025-12-20	7	83	0	\N	\N	150.00	PKG-74709836605841	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
186	Ramiro C	\N	los maquis 8	consulta	2025-11-24 18:10:41.560111	2025-11-24 18:10:41.560111	3	+56930762598	f	2025-12-21	7	92	0	\N	\N	200.00	PKG-76256639799977	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
188	Gabriela F	\N	krauss 10	electrónica	2025-11-24 18:10:41.570976	2025-11-24 18:10:41.570976	3	+56930762599	f	2025-12-22	7	105	0	\N	\N	0.00	PKG-78151535068918	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
190	Pedro M	\N	avenida 9	zapatos	2025-11-24 18:10:41.586202	2025-11-24 18:10:41.586202	3	+56930762600	f	2025-12-23	7	115	0	\N	\N	0.00	PKG-85971740275994	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
192	Brenda H	\N	luna 33	ropa	2025-11-24 18:10:41.596134	2025-11-24 18:10:41.596134	3	+56930762601	f	2025-12-24	7	100	0	\N	\N	0.00	PKG-39972370166328	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
194	Diego A	\N	sol 72	caja mediana	2025-11-24 18:10:41.607391	2025-11-24 18:10:41.607391	3	+56930762602	f	2025-12-25	7	102	0	\N	\N	315.00	PKG-85418301675118	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
196	Valentina Q	\N	carmen 8	utensilios	2025-11-24 18:10:41.617953	2025-11-24 18:10:41.617953	3	+56930762603	f	2025-12-26	7	83	0	\N	\N	0.00	PKG-50928726864998	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
198	Rodrigo P	\N	estrella 41	encomienda	2025-11-24 18:10:41.628133	2025-11-24 18:10:41.628133	3	+56930762604	f	2025-12-27	7	105	0	\N	\N	0.00	PKG-05940964418291	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
200	Sara K	\N	pedro 90	manual	2025-11-24 18:10:41.643068	2025-11-24 18:10:41.643068	3	+56930762605	f	2025-12-28	7	96	0	\N	\N	0.00	PKG-79462920913601	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
202	Juan A	\N	flora 19	teléfono	2025-11-24 18:10:41.653281	2025-11-24 18:10:41.653281	3	+56930762606	f	2025-12-29	7	102	0	\N	\N	0.00	PKG-60788868862625	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
204	Alicia G	\N	monteverde 8	accesorios	2025-11-24 18:10:41.663462	2025-11-24 18:10:41.663462	3	+56930762607	f	2025-12-30	7	100	0	\N	\N	0.00	PKG-93238256388500	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
206	Roberto Y	\N	angamos 3	compra online	2025-11-24 18:10:41.673626	2025-11-24 18:10:41.673626	3	+56930762608	f	2025-12-31	7	83	0	\N	\N	510.00	PKG-52347266415160	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
208	Lucía J	\N	santana 17	artículo oficina	2025-11-24 18:10:41.683949	2025-11-24 18:10:41.683949	3	+56930762609	f	2026-01-01	7	92	0	\N	\N	230.00	PKG-93645878423489	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
210	Gonzalo H	\N	paceo 91	pedido recurrente	2025-11-24 18:10:41.700393	2025-11-24 18:10:41.700393	3	+56930762610	f	2026-01-02	7	105	0	\N	\N	330.00	PKG-58768627154347	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
212	Mariela R	\N	avenida 12	ropa deportiva	2025-11-24 18:10:41.710958	2025-11-24 18:10:41.710958	3	+56930762611	f	2026-01-03	7	102	0	\N	\N	260.00	PKG-12738547296826	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
214	Joel D	\N	fast 55	producto importado	2025-11-24 18:10:41.721914	2025-11-24 18:10:41.721914	3	+56930762612	f	2026-01-04	7	115	0	\N	\N	720.00	PKG-29218763297694	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
216	Mónica T	\N	tribuna 90	dispositivo	2025-11-24 18:10:41.73175	2025-11-24 18:10:41.73175	3	+56930762613	f	2026-01-05	7	100	0	\N	\N	0.00	PKG-53410336830904	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
218	Patricio S	\N	balmaceda 99	regalo cliente	2025-11-24 18:10:41.741971	2025-11-24 18:10:41.741971	3	+56930762614	f	2026-01-06	7	83	0	\N	\N	195.00	PKG-98757880302940	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
220	Javiera K	\N	olmos 14	delivery express	2025-11-24 18:10:41.758472	2025-11-24 18:10:41.758472	3	+56930762615	f	2026-01-07	7	92	0	\N	\N	350.00	PKG-06453312586750	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
222	Ismael N	\N	teja sur 22	productos varios	2025-11-24 18:10:41.770436	2025-11-24 18:10:41.770436	3	+56930762616	f	2026-01-08	7	105	0	\N	\N	430.00	PKG-21383590408268	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
224	Beatriz O	\N	urmeneta 1	agua embotellada	2025-11-24 18:10:41.78093	2025-11-24 18:10:41.78093	3	+56930762617	f	2026-01-09	7	102	0	\N	\N	90.00	PKG-04405384079355	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
226	Froilán Z	\N	comandante 7	libro de estudio	2025-11-24 18:10:41.790985	2025-11-24 18:10:41.790985	3	+56930762618	f	2026-01-10	7	96	0	\N	\N	240.00	PKG-43312910421849	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
228	Denisse Q	\N	ramón 88	petición especial	2025-11-24 18:10:41.800252	2025-11-24 18:10:41.800252	3	+56930762619	f	2026-01-11	7	83	0	\N	\N	610.00	PKG-83078364314035	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
230	Alan V	\N	rio alto 3	insumo médico	2025-11-24 18:10:41.813742	2025-11-24 18:10:41.813742	3	+56930762620	f	2026-01-12	7	92	0	\N	\N	980.00	PKG-69123494173631	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
232	Olga M	\N	quinta 4	vestuario	2025-11-24 18:10:41.824128	2025-11-24 18:10:41.824128	3	+56930762621	f	2026-01-13	7	105	0	\N	\N	0.00	PKG-43841382186512	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
234	Bastián E	\N	canal 87	envío simple	2025-11-24 18:10:41.834169	2025-11-24 18:10:41.834169	3	+56930762622	f	2026-01-14	7	102	0	\N	\N	130.00	PKG-83507281111689	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
236	Ximena T	\N	canto 11	caja gigante	2025-11-24 18:10:41.843599	2025-11-24 18:10:41.843599	3	+56930762623	f	2026-01-15	7	100	0	\N	\N	540.00	PKG-75632005354639	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
238	César L	\N	alto sur 2	entrega express	2025-11-24 18:10:41.853188	2025-11-24 18:10:41.853188	3	+56930762624	f	2026-01-16	7	83	0	\N	\N	320.00	PKG-42052639818153	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
240	Florencia I	\N	patio 66	elemento frágil	2025-11-24 18:10:41.865967	2025-11-24 18:10:41.865967	3	+56930762625	f	2026-01-17	7	96	0	\N	\N	470.00	PKG-44415846196077	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
243	Jeremías F	\N	loma 17	pedido	2025-11-24 18:10:41.877879	2025-11-24 18:10:41.877879	3	+56930762626	f	2026-01-18	7	105	0	\N	\N	230.00	PKG-34596567077727	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
245	Carolina D	\N	los sauces 1	compra cliente	2025-11-24 18:10:41.888706	2025-11-24 18:10:41.888706	3	+56930762627	f	2026-01-19	7	102	0	\N	\N	160.00	PKG-75211533253770	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
247	Tomás G	\N	los acacios 9	pieza repuesto	2025-11-24 18:10:41.898434	2025-11-24 18:10:41.898434	3	+56930762628	f	2026-01-20	7	92	0	\N	\N	490.00	PKG-31620877341600	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
249	Romina H	\N	avenida 44	regalo sorpresa	2025-11-24 18:10:41.908171	2025-11-24 18:10:41.908171	3	+56930762629	f	2026-01-21	7	115	0	\N	\N	150.00	PKG-23796777997136	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
251	Gabriel C	\N	pedro II 8	objecto nuevo	2025-11-24 18:10:41.92204	2025-11-24 18:10:41.92204	3	+56930762630	f	2026-01-22	7	83	0	\N	\N	280.00	PKG-83125048809297	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
253	Fernanda P	\N	monte real 3	accesorio hogar	2025-11-24 18:10:41.932702	2025-11-24 18:10:41.932702	3	+56930762631	f	2026-01-23	7	96	0	\N	\N	330.00	PKG-39173159071873	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
252	Fernanda P	\N	monte real 3	accesorio hogar	2025-11-24 18:10:41.930274	2025-11-24 18:10:41.930274	3	+56930762631	f	2026-01-23	7	96	0	\N	\N	330.00	PKG-07537580326737	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
254	Héctor M	\N	colón 81	producto digital	2025-11-24 18:10:41.940265	2025-11-24 18:10:41.940265	3	+56930762632	f	2026-01-24	7	105	0	\N	\N	525.00	PKG-45118116014218	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
256	Paola Y	\N	estrella 33	pañales	2025-11-24 18:10:41.95078	2025-11-24 18:10:41.95078	3	+56930762633	f	2026-01-25	7	102	0	\N	\N	0.00	PKG-74490309495899	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
258	Ángel A	\N	sol 100	alimento	2025-11-24 18:10:41.960165	2025-11-24 18:10:41.960165	3	+56930762634	f	2026-01-26	7	92	0	\N	\N	0.00	PKG-34570091276290	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
260	Yesenia L	\N	avenida 7	bebida	2025-11-24 18:10:41.974195	2025-11-24 18:10:41.974195	3	+56930762635	f	2026-01-27	7	100	0	\N	\N	0.00	PKG-49573650868388	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
262	Rafael O	\N	oro 55	solicitud general	2025-11-24 18:10:41.984029	2025-11-24 18:10:41.984029	3	+56930762636	f	2026-01-28	7	83	0	\N	\N	150.00	PKG-44807623755939	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
264	Valery R	\N	verde 44	producto gourmet	2025-11-24 18:10:41.992876	2025-11-24 18:10:41.992876	3	+56930762637	f	2026-01-29	7	105	0	\N	\N	740.00	PKG-87267709437016	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
266	Cristóbal T	\N	central 19	repuesto auto	2025-11-24 18:10:42.003365	2025-11-24 18:10:42.003365	3	+56930762638	f	2026-01-30	7	96	0	\N	\N	350.00	PKG-97249663494431	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
268	Lina J	\N	pedregal 11	insumo técnico	2025-11-24 18:10:42.014214	2025-11-24 18:10:42.014214	3	+56930762639	f	2026-01-31	7	102	0	\N	\N	275.00	PKG-99494567210744	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
270	Maximiliano B	\N	rio 90	accesorio gamer	2025-11-24 18:10:42.027019	2025-11-24 18:10:42.027019	3	+56930762640	f	2026-02-01	7	92	0	\N	\N	510.00	PKG-01262921186319	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
272	Pilar E	\N	lagos 82	objeto hogar	2025-11-24 18:10:42.036788	2025-11-24 18:10:42.036788	3	+56930762641	f	2026-02-02	7	83	0	\N	\N	200.00	PKG-27854919945399	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
274	Tadeo P	\N	costa azul 5	pedido interno	2025-11-24 18:10:42.046481	2025-11-24 18:10:42.046481	3	+56930762642	f	2026-02-03	7	105	0	\N	\N	330.00	PKG-59710371475303	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
276	Agustina L	\N	montaña 2	mueble pequeño	2025-11-24 18:10:42.056132	2025-11-24 18:10:42.056132	3	+56930762643	f	2026-02-04	7	96	0	\N	\N	780.00	PKG-05467592754070	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
278	Julián F	\N	avenida 5	pedido rápido	2025-11-24 18:10:42.067209	2025-11-24 18:10:42.067209	3	+56930762644	f	2026-02-05	7	102	0	\N	\N	120.00	PKG-21739067254703	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
280	Marta A	\N	luna 7	mercadería	2025-11-24 18:10:42.080613	2025-11-24 18:10:42.080613	3	+56930762645	f	2026-02-06	7	115	0	\N	\N	0.00	PKG-44245992631200	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
282	Leandro D	\N	avenida 15	ropa invierno	2025-11-24 18:10:42.091161	2025-11-24 18:10:42.091161	3	+56930762646	f	2026-02-07	7	100	0	\N	\N	290.00	PKG-73340431640796	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
284	Emilia G	\N	pasaje 8	perfume	2025-11-24 18:10:42.101429	2025-11-24 18:10:42.101429	3	+56930762647	f	2026-02-08	7	83	0	\N	\N	0.00	PKG-21467753004248	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
286	Benjamín C	\N	bosque 17	artículo cocina	2025-11-24 18:10:42.112721	2025-11-24 18:10:42.112721	3	+56930762648	f	2026-02-09	7	105	0	\N	\N	230.00	PKG-97751190691240	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
288	Inés H	\N	cerro 88	producto nuevo	2025-11-24 18:10:42.122988	2025-11-24 18:10:42.122988	3	+56930762649	f	2026-02-10	7	92	0	\N	\N	480.00	PKG-06360216424238	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
290	Alonso T	\N	rio largo 22	insumo técnico	2025-11-24 18:10:42.137871	2025-11-24 18:10:42.137871	3	+56930762650	f	2026-02-11	7	102	0	\N	\N	310.00	PKG-94051513029465	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
292	Constanza Y	\N	ruta 44	accesorio hogar	2025-11-24 18:10:42.148715	2025-11-24 18:10:42.148715	3	+56930762651	f	2026-02-12	7	115	0	\N	\N	160.00	PKG-27574632433648	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
294	Kevin M	\N	croacia 5	caja pequeña	2025-11-24 18:10:42.15872	2025-11-24 18:10:42.15872	3	+56930762652	f	2026-02-13	7	83	0	\N	\N	120.00	PKG-12936074045254	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
296	Aranza R	\N	loto 66	juguete	2025-11-24 18:10:42.168974	2025-11-24 18:10:42.168974	3	+56930762653	f	2026-02-14	7	96	0	\N	\N	0.00	PKG-53596255235921	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
298	Thiago S	\N	avenida 99	comida	2025-11-24 18:10:42.178977	2025-11-24 18:10:42.178977	3	+56930762654	f	2026-02-15	7	105	0	\N	\N	0.00	PKG-76379224504987	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
300	Juan José L	\N	faro 3	lámpara	2025-11-24 18:10:42.191955	2025-11-24 18:10:42.191955	3	+56930762655	f	2026-02-16	7	102	0	\N	\N	0.00	PKG-11221203994411	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
301	Fernanda C	\N	pedro 6	productos varios	2025-11-24 18:10:42.201225	2025-11-24 18:10:42.201225	3	+56930762656	f	2026-02-17	7	83	0	\N	\N	140.00	PKG-17200834197928	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
303	Elías U	\N	calle 10	notebook	2025-11-24 18:10:42.211257	2025-11-24 18:10:42.211257	3	+56930762657	f	2026-02-18	7	100	0	\N	\N	0.00	PKG-07652448820252	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
305	Trinidad M	\N	carmen 77	artículos bebés	2025-11-24 18:10:42.220731	2025-11-24 18:10:42.220731	3	+56930762658	f	2026-02-19	7	92	0	\N	\N	260.00	PKG-50690852014490	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
307	Alfredo Z	\N	subida 4	implementos	2025-11-24 18:10:42.229627	2025-11-24 18:10:42.229627	3	+56930762659	f	2026-02-20	7	96	0	\N	\N	0.00	PKG-13737396911796	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
310	Romina B	\N	rosales 11	accesorio auto	2025-11-24 18:10:42.243137	2025-11-24 18:10:42.243137	3	+56930762660	f	2026-02-21	7	105	0	\N	\N	180.00	PKG-64466507484505	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
311	Sherly V	\N	rio gris 2	té especial	2025-11-24 18:10:42.253022	2025-11-24 18:10:42.253022	3	+56930762661	f	2026-02-22	7	83	0	\N	\N	0.00	PKG-23562911586347	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
313	Leonardo H	\N	lira 44	servicio técnico	2025-11-24 18:10:42.263204	2025-11-24 18:10:42.263204	3	+56930762662	f	2026-02-23	7	102	0	\N	\N	520.00	PKG-00247924698821	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
315	Amparo J	\N	pedro 19	taza cerámica	2025-11-24 18:10:42.273148	2025-11-24 18:10:42.273148	3	+56930762663	f	2026-02-24	7	100	0	\N	\N	110.00	PKG-32364385968841	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
317	Elvira P	\N	rio profundo 1	insumos limpeza	2025-11-24 18:10:42.283218	2025-11-24 18:10:42.283218	3	+56930762664	f	2026-02-25	7	115	0	\N	\N	140.00	PKG-13487892785437	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
320	Oliver Y	\N	avenida 121	material oficina	2025-11-24 18:10:42.297877	2025-11-24 18:10:42.297877	3	+56930762665	f	2026-02-26	7	83	0	\N	\N	260.00	PKG-94312959133155	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
321	Selena A	\N	los cedros 3	plato vidrio	2025-11-24 18:10:42.306982	2025-11-24 18:10:42.306982	3	+56930762666	f	2026-02-27	7	92	0	\N	\N	130.00	PKG-06194373416165	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
323	Eduardo T	\N	ulmo 17	producto premium	2025-11-24 18:10:42.317961	2025-11-24 18:10:42.317961	3	+56930762667	f	2026-02-28	7	105	0	\N	\N	870.00	PKG-82665229797179	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
325	Rocío E	\N	lago azul 8	regalo especial	2025-11-24 18:10:42.328665	2025-11-24 18:10:42.328665	3	+56930762668	f	2026-03-01	7	96	0	\N	\N	190.00	PKG-87376118495097	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
327	Mario R	\N	arbustos 7	audífonos	2025-11-24 18:10:42.338968	2025-11-24 18:10:42.338968	3	+56930762669	f	2026-03-02	7	102	0	\N	\N	0.00	PKG-53050522958609	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
255	Héctor M	\N	colón 81	producto digital	2025-11-24 18:10:41.943581	2025-11-24 18:10:41.943581	3	+56930762632	f	2026-01-24	7	105	0	\N	\N	525.00	PKG-70451218829119	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
257	Paola Y	\N	estrella 33	pañales	2025-11-24 18:10:41.954114	2025-11-24 18:10:41.954114	3	+56930762633	f	2026-01-25	7	102	0	\N	\N	0.00	PKG-44604136292962	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
259	Ángel A	\N	sol 100	alimento	2025-11-24 18:10:41.964199	2025-11-24 18:10:41.964199	3	+56930762634	f	2026-01-26	7	92	0	\N	\N	0.00	PKG-26355646454027	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
261	Yesenia L	\N	avenida 7	bebida	2025-11-24 18:10:41.977837	2025-11-24 18:10:41.977837	3	+56930762635	f	2026-01-27	7	100	0	\N	\N	0.00	PKG-96611662970613	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
263	Rafael O	\N	oro 55	solicitud general	2025-11-24 18:10:41.988037	2025-11-24 18:10:41.988037	3	+56930762636	f	2026-01-28	7	83	0	\N	\N	150.00	PKG-61712650828164	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
265	Valery R	\N	verde 44	producto gourmet	2025-11-24 18:10:41.997808	2025-11-24 18:10:41.997808	3	+56930762637	f	2026-01-29	7	105	0	\N	\N	740.00	PKG-21871050759430	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
267	Cristóbal T	\N	central 19	repuesto auto	2025-11-24 18:10:42.008693	2025-11-24 18:10:42.008693	3	+56930762638	f	2026-01-30	7	96	0	\N	\N	350.00	PKG-97917251188759	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
269	Lina J	\N	pedregal 11	insumo técnico	2025-11-24 18:10:42.01856	2025-11-24 18:10:42.01856	3	+56930762639	f	2026-01-31	7	102	0	\N	\N	275.00	PKG-77255127402858	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
271	Maximiliano B	\N	rio 90	accesorio gamer	2025-11-24 18:10:42.033425	2025-11-24 18:10:42.033425	3	+56930762640	f	2026-02-01	7	92	0	\N	\N	510.00	PKG-72227091952715	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
273	Pilar E	\N	lagos 82	objeto hogar	2025-11-24 18:10:42.043858	2025-11-24 18:10:42.043858	3	+56930762641	f	2026-02-02	7	83	0	\N	\N	200.00	PKG-05808927164797	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
275	Tadeo P	\N	costa azul 5	pedido interno	2025-11-24 18:10:42.054303	2025-11-24 18:10:42.054303	3	+56930762642	f	2026-02-03	7	105	0	\N	\N	330.00	PKG-01199391687601	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
277	Agustina L	\N	montaña 2	mueble pequeño	2025-11-24 18:10:42.065206	2025-11-24 18:10:42.065206	3	+56930762643	f	2026-02-04	7	96	0	\N	\N	780.00	PKG-80740704228019	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
279	Julián F	\N	avenida 5	pedido rápido	2025-11-24 18:10:42.075544	2025-11-24 18:10:42.075544	3	+56930762644	f	2026-02-05	7	102	0	\N	\N	120.00	PKG-70729645915612	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
281	Marta A	\N	luna 7	mercadería	2025-11-24 18:10:42.089738	2025-11-24 18:10:42.089738	3	+56930762645	f	2026-02-06	7	115	0	\N	\N	0.00	PKG-61762742657344	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
283	Leandro D	\N	avenida 15	ropa invierno	2025-11-24 18:10:42.099737	2025-11-24 18:10:42.099737	3	+56930762646	f	2026-02-07	7	100	0	\N	\N	290.00	PKG-88479366787509	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
285	Emilia G	\N	pasaje 8	perfume	2025-11-24 18:10:42.111949	2025-11-24 18:10:42.111949	3	+56930762647	f	2026-02-08	7	83	0	\N	\N	0.00	PKG-42955789921240	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
287	Benjamín C	\N	bosque 17	artículo cocina	2025-11-24 18:10:42.121253	2025-11-24 18:10:42.121253	3	+56930762648	f	2026-02-09	7	105	0	\N	\N	230.00	PKG-39560683433531	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
289	Inés H	\N	cerro 88	producto nuevo	2025-11-24 18:10:42.132382	2025-11-24 18:10:42.132382	3	+56930762649	f	2026-02-10	7	92	0	\N	\N	480.00	PKG-12343493034884	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
291	Alonso T	\N	rio largo 22	insumo técnico	2025-11-24 18:10:42.146165	2025-11-24 18:10:42.146165	3	+56930762650	f	2026-02-11	7	102	0	\N	\N	310.00	PKG-23598637008465	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
293	Constanza Y	\N	ruta 44	accesorio hogar	2025-11-24 18:10:42.155988	2025-11-24 18:10:42.155988	3	+56930762651	f	2026-02-12	7	115	0	\N	\N	160.00	PKG-57196417043842	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
295	Kevin M	\N	croacia 5	caja pequeña	2025-11-24 18:10:42.166219	2025-11-24 18:10:42.166219	3	+56930762652	f	2026-02-13	7	83	0	\N	\N	120.00	PKG-11819948597280	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
297	Aranza R	\N	loto 66	juguete	2025-11-24 18:10:42.176269	2025-11-24 18:10:42.176269	3	+56930762653	f	2026-02-14	7	96	0	\N	\N	0.00	PKG-67118061347534	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
299	Thiago S	\N	avenida 99	comida	2025-11-24 18:10:42.187002	2025-11-24 18:10:42.187002	3	+56930762654	f	2026-02-15	7	105	0	\N	\N	0.00	PKG-93746518101241	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
302	Juan José L	\N	faro 3	lámpara	2025-11-24 18:10:42.203533	2025-11-24 18:10:42.203533	3	+56930762655	f	2026-02-16	7	102	0	\N	\N	0.00	PKG-25645744084267	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
304	Fernanda C	\N	pedro 6	productos varios	2025-11-24 18:10:42.212624	2025-11-24 18:10:42.212624	3	+56930762656	f	2026-02-17	7	83	0	\N	\N	140.00	PKG-25579873397392	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
306	Elías U	\N	calle 10	notebook	2025-11-24 18:10:42.222189	2025-11-24 18:10:42.222189	3	+56930762657	f	2026-02-18	7	100	0	\N	\N	0.00	PKG-79918786042409	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
308	Trinidad M	\N	carmen 77	artículos bebés	2025-11-24 18:10:42.232032	2025-11-24 18:10:42.232032	3	+56930762658	f	2026-02-19	7	92	0	\N	\N	260.00	PKG-25804037628147	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
309	Alfredo Z	\N	subida 4	implementos	2025-11-24 18:10:42.241621	2025-11-24 18:10:42.241621	3	+56930762659	f	2026-02-20	7	96	0	\N	\N	0.00	PKG-41863445608816	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
312	Romina B	\N	rosales 11	accesorio auto	2025-11-24 18:10:42.256682	2025-11-24 18:10:42.256682	3	+56930762660	f	2026-02-21	7	105	0	\N	\N	180.00	PKG-48369843747119	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
314	Sherly V	\N	rio gris 2	té especial	2025-11-24 18:10:42.266407	2025-11-24 18:10:42.266407	3	+56930762661	f	2026-02-22	7	83	0	\N	\N	0.00	PKG-33798862788834	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
316	Leonardo H	\N	lira 44	servicio técnico	2025-11-24 18:10:42.276046	2025-11-24 18:10:42.276046	3	+56930762662	f	2026-02-23	7	102	0	\N	\N	520.00	PKG-79431795666843	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
318	Amparo J	\N	pedro 19	taza cerámica	2025-11-24 18:10:42.285743	2025-11-24 18:10:42.285743	3	+56930762663	f	2026-02-24	7	100	0	\N	\N	110.00	PKG-35243283559594	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
319	Elvira P	\N	rio profundo 1	insumos limpeza	2025-11-24 18:10:42.295351	2025-11-24 18:10:42.295351	3	+56930762664	f	2026-02-25	7	115	0	\N	\N	140.00	PKG-58895979067128	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
322	Oliver Y	\N	avenida 121	material oficina	2025-11-24 18:10:42.311194	2025-11-24 18:10:42.311194	3	+56930762665	f	2026-02-26	7	83	0	\N	\N	260.00	PKG-86519458056388	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
324	Selena A	\N	los cedros 3	plato vidrio	2025-11-24 18:10:42.321269	2025-11-24 18:10:42.321269	3	+56930762666	f	2026-02-27	7	92	0	\N	\N	130.00	PKG-05660301822954	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
326	Eduardo T	\N	ulmo 17	producto premium	2025-11-24 18:10:42.331188	2025-11-24 18:10:42.331188	3	+56930762667	f	2026-02-28	7	105	0	\N	\N	870.00	PKG-78488013446436	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
328	Rocío E	\N	lago azul 8	regalo especial	2025-11-24 18:10:42.341408	2025-11-24 18:10:42.341408	3	+56930762668	f	2026-03-01	7	96	0	\N	\N	190.00	PKG-31691946877318	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
329	Mario R	\N	arbustos 7	audífonos	2025-11-24 18:10:42.35048	2025-11-24 18:10:42.35048	3	+56930762669	f	2026-03-02	7	102	0	\N	\N	0.00	PKG-15152792071061	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
330	Cristina 1	\N	ninune	algo puede	2025-11-24 18:23:03.298286	2025-11-24 18:23:03.298286	3	+56930762571	t	2025-11-24	7	102	0	\N	\N	0.00	PKG-63894338166029	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
331	Cristina 1	\N	ninune	algo puede	2025-11-24 18:23:03.302168	2025-11-24 18:23:03.302168	3	+56930762571	t	2025-11-24	7	102	0	\N	\N	0.00	PKG-31367084359828	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
332	Carlos 1	\N	rasaz	rata	2025-11-24 18:23:03.30985	2025-11-24 18:23:03.30985	3	+56930762572	t	2025-11-25	7	96	0	\N	\N	0.00	PKG-96898498214976	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
333	Carlos 1	\N	rasaz	rata	2025-11-24 18:23:03.313195	2025-11-24 18:23:03.313195	3	+56930762572	t	2025-11-25	7	96	0	\N	\N	0.00	PKG-82299153357201	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
334	Ana Soto	\N	avenida 1	entrega rápida	2025-11-24 18:23:03.320508	2025-11-24 18:23:03.320508	3	+56930762573	t	2025-11-26	7	105	0	\N	\N	500.00	PKG-16869244844967	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
335	Ana Soto	\N	avenida 1	entrega rápida	2025-11-24 18:23:03.324134	2025-11-24 18:23:03.324134	3	+56930762573	t	2025-11-26	7	105	0	\N	\N	500.00	PKG-07455122094885	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
337	Luis Rojas	\N	calle sur 22	paquete frágil	2025-11-24 18:23:03.335203	2025-11-24 18:23:03.335203	3	+56930762574	t	2025-11-27	7	102	0	\N	\N	320.00	PKG-61147012391695	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
339	María Vera	\N	los pinos 44	documentos	2025-11-24 18:23:03.358551	2025-11-24 18:23:03.358551	3	+56930762575	t	2025-11-28	7	92	0	\N	\N	90.00	PKG-08262066951604	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
341	Pablo Díaz	\N	oro verde 11	hogar	2025-11-24 18:23:03.370235	2025-11-24 18:23:03.370235	3	+56930762576	t	2025-11-29	7	115	0	\N	\N	0.00	PKG-44680799838225	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
343	Daniela Paz	\N	central 98	solicitud nueva	2025-11-24 18:23:03.38056	2025-11-24 18:23:03.38056	3	+56930762577	t	2025-11-30	7	105	0	\N	\N	245.00	PKG-87760242056948	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
345	José Toro	\N	rio azul 9	compra online	2025-11-24 18:23:03.390271	2025-11-24 18:23:03.390271	3	+56930762578	t	2025-12-01	7	83	0	\N	\N	600.00	PKG-49180090470319	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
347	Carla Núñez	\N	pedro 33	prueba	2025-11-24 18:23:03.400908	2025-11-24 18:23:03.400908	3	+56930762579	t	2025-12-02	7	100	0	\N	\N	0.00	PKG-73752041647854	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
349	Marcos León	\N	avenida 2	último pedido	2025-11-24 18:23:03.415702	2025-11-24 18:23:03.415702	3	+56930762580	t	2025-12-03	7	105	0	\N	\N	350.00	PKG-16239773890037	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
351	Vanessa M	\N	los robles 77	caja pequeña	2025-11-24 18:23:03.427837	2025-11-24 18:23:03.427837	3	+56930762581	t	2025-12-04	7	102	0	\N	\N	180.00	PKG-84381310517636	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
353	Hugo Sáez	\N	mirador 12	ropa nueva	2025-11-24 18:23:03.438606	2025-11-24 18:23:03.438606	3	+56930762582	t	2025-12-05	7	96	0	\N	\N	0.00	PKG-29351189140039	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
355	Elena Cruz	\N	sur 14	delivery	2025-11-24 18:23:03.449733	2025-11-24 18:23:03.449733	3	+56930762583	t	2025-12-06	7	92	0	\N	\N	0.00	PKG-32680190426063	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
357	Ricardo V	\N	norte 8	encargo urgente	2025-11-24 18:23:03.460538	2025-11-24 18:23:03.460538	3	+56930762584	t	2025-12-07	7	83	0	\N	\N	700.00	PKG-17551651922780	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
359	Sonia Pinto	\N	colón 334	accesorios	2025-11-24 18:23:03.47423	2025-11-24 18:23:03.47423	3	+56930762585	t	2025-12-08	7	105	0	\N	\N	0.00	PKG-66363370450515	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
361	Andrés G	\N	puente 9	libro	2025-11-24 18:23:03.484161	2025-11-24 18:23:03.484161	3	+56930762586	t	2025-12-09	7	115	0	\N	\N	0.00	PKG-94896617405688	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
363	Karen Soto	\N	monjitas 22	autoparte	2025-11-24 18:23:03.497026	2025-11-24 18:23:03.497026	3	+56930762587	t	2025-12-10	7	83	0	\N	\N	0.00	PKG-40531894631892	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
365	Lorena V	\N	los sauces 8	artículo hogar	2025-11-24 18:23:03.507735	2025-11-24 18:23:03.507735	3	+56930762588	t	2025-12-11	7	102	0	\N	\N	160.00	PKG-73048933159894	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
367	Esteban R	\N	monte 66	producto nuevo	2025-11-24 18:23:03.520259	2025-11-24 18:23:03.520259	3	+56930762589	t	2025-12-12	7	96	0	\N	\N	260.00	PKG-06725694962042	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
370	Felipe N	\N	costanera 77	paquete chico	2025-11-24 18:23:03.536292	2025-11-24 18:23:03.536292	3	+56930762590	t	2025-12-13	7	105	0	\N	\N	115.00	PKG-05184590753221	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
372	Claudia S	\N	tramonto 34	envío estándar	2025-11-24 18:23:03.54773	2025-11-24 18:23:03.54773	3	+56930762591	t	2025-12-14	7	100	0	\N	\N	240.00	PKG-29658045228794	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
374	Matías L	\N	pasaje 5	solicitud cliente	2025-11-24 18:23:03.560582	2025-11-24 18:23:03.560582	3	+56930762592	t	2025-12-15	7	92	0	\N	\N	390.00	PKG-27886339539628	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
376	Susana J	\N	catedral 11	regalo	2025-11-24 18:23:03.572149	2025-11-24 18:23:03.572149	3	+56930762593	t	2025-12-16	7	83	0	\N	\N	0.00	PKG-01930487614702	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
377	Bernardo T	\N	los boldos 3	fragil	2025-11-24 18:23:03.583432	2025-11-24 18:23:03.583432	3	+56930762594	f	2025-12-17	7	105	0	\N	\N	0.00	PKG-44698477500453	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
380	Fabiola U	\N	sur alto 91	repuesto	2025-11-24 18:23:03.598839	2025-11-24 18:23:03.598839	3	+56930762595	f	2025-12-18	7	102	0	\N	\N	0.00	PKG-75386047819111	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
382	Sebastián Z	\N	avenida 4	envío rápido	2025-11-24 18:23:03.609952	2025-11-24 18:23:03.609952	3	+56930762596	f	2025-12-19	7	96	0	\N	\N	410.00	PKG-05628319524841	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
384	Nadia P	\N	norte chico 1	producto bebé	2025-11-24 18:23:03.621198	2025-11-24 18:23:03.621198	3	+56930762597	f	2025-12-20	7	83	0	\N	\N	150.00	PKG-60289745572003	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
386	Ramiro C	\N	los maquis 8	consulta	2025-11-24 18:23:03.632416	2025-11-24 18:23:03.632416	3	+56930762598	f	2025-12-21	7	92	0	\N	\N	200.00	PKG-63539023097411	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
388	Gabriela F	\N	krauss 10	electrónica	2025-11-24 18:23:03.642962	2025-11-24 18:23:03.642962	3	+56930762599	f	2025-12-22	7	105	0	\N	\N	0.00	PKG-93639209757850	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
390	Pedro M	\N	avenida 9	zapatos	2025-11-24 18:23:03.657754	2025-11-24 18:23:03.657754	3	+56930762600	f	2025-12-23	7	115	0	\N	\N	0.00	PKG-26881954848286	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
392	Brenda H	\N	luna 33	ropa	2025-11-24 18:23:03.670075	2025-11-24 18:23:03.670075	3	+56930762601	f	2025-12-24	7	100	0	\N	\N	0.00	PKG-81475753244905	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
394	Diego A	\N	sol 72	caja mediana	2025-11-24 18:23:03.680583	2025-11-24 18:23:03.680583	3	+56930762602	f	2025-12-25	7	102	0	\N	\N	315.00	PKG-36202263288254	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
396	Valentina Q	\N	carmen 8	utensilios	2025-11-24 18:23:03.692839	2025-11-24 18:23:03.692839	3	+56930762603	f	2025-12-26	7	83	0	\N	\N	0.00	PKG-22230223170861	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
398	Rodrigo P	\N	estrella 41	encomienda	2025-11-24 18:23:03.703857	2025-11-24 18:23:03.703857	3	+56930762604	f	2025-12-27	7	105	0	\N	\N	0.00	PKG-36351823419414	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
401	Sara K	\N	pedro 90	manual	2025-11-24 18:23:03.719921	2025-11-24 18:23:03.719921	3	+56930762605	f	2025-12-28	7	96	0	\N	\N	0.00	PKG-79245360750027	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
403	Juan A	\N	flora 19	teléfono	2025-11-24 18:23:03.730542	2025-11-24 18:23:03.730542	3	+56930762606	f	2025-12-29	7	102	0	\N	\N	0.00	PKG-42859281608797	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
405	Alicia G	\N	monteverde 8	accesorios	2025-11-24 18:23:03.741958	2025-11-24 18:23:03.741958	3	+56930762607	f	2025-12-30	7	100	0	\N	\N	0.00	PKG-18456046160969	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
406	Roberto Y	\N	angamos 3	compra online	2025-11-24 18:23:03.754529	2025-11-24 18:23:03.754529	3	+56930762608	f	2025-12-31	7	83	0	\N	\N	510.00	PKG-26562634645179	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
408	Lucía J	\N	santana 17	artículo oficina	2025-11-24 18:23:03.767526	2025-11-24 18:23:03.767526	3	+56930762609	f	2026-01-01	7	92	0	\N	\N	230.00	PKG-97259822577624	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
411	Gonzalo H	\N	paceo 91	pedido recurrente	2025-11-24 18:23:03.782916	2025-11-24 18:23:03.782916	3	+56930762610	f	2026-01-02	7	105	0	\N	\N	330.00	PKG-52212470957853	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
413	Mariela R	\N	avenida 12	ropa deportiva	2025-11-24 18:23:03.792488	2025-11-24 18:23:03.792488	3	+56930762611	f	2026-01-03	7	102	0	\N	\N	260.00	PKG-23672214496936	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
415	Joel D	\N	fast 55	producto importado	2025-11-24 18:23:03.802293	2025-11-24 18:23:03.802293	3	+56930762612	f	2026-01-04	7	115	0	\N	\N	720.00	PKG-40418311562574	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
416	Mónica T	\N	tribuna 90	dispositivo	2025-11-24 18:23:03.811524	2025-11-24 18:23:03.811524	3	+56930762613	f	2026-01-05	7	100	0	\N	\N	0.00	PKG-90090900118421	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
418	Patricio S	\N	balmaceda 99	regalo cliente	2025-11-24 18:23:03.822541	2025-11-24 18:23:03.822541	3	+56930762614	f	2026-01-06	7	83	0	\N	\N	195.00	PKG-96854714878462	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
421	Javiera K	\N	olmos 14	delivery express	2025-11-24 18:23:03.837851	2025-11-24 18:23:03.837851	3	+56930762615	f	2026-01-07	7	92	0	\N	\N	350.00	PKG-01254893116774	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
336	Luis Rojas	\N	calle sur 22	paquete frágil	2025-11-24 18:23:03.33068	2025-11-24 18:23:03.33068	3	+56930762574	t	2025-11-27	7	102	0	\N	\N	320.00	PKG-27236285727338	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
338	María Vera	\N	los pinos 44	documentos	2025-11-24 18:23:03.357708	2025-11-24 18:23:03.357708	3	+56930762575	t	2025-11-28	7	92	0	\N	\N	90.00	PKG-98925393682403	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
340	Pablo Díaz	\N	oro verde 11	hogar	2025-11-24 18:23:03.367545	2025-11-24 18:23:03.367545	3	+56930762576	t	2025-11-29	7	115	0	\N	\N	0.00	PKG-67865040675087	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
342	Daniela Paz	\N	central 98	solicitud nueva	2025-11-24 18:23:03.377976	2025-11-24 18:23:03.377976	3	+56930762577	t	2025-11-30	7	105	0	\N	\N	245.00	PKG-58898255902616	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
344	José Toro	\N	rio azul 9	compra online	2025-11-24 18:23:03.387786	2025-11-24 18:23:03.387786	3	+56930762578	t	2025-12-01	7	83	0	\N	\N	600.00	PKG-11224946369742	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
346	Carla Núñez	\N	pedro 33	prueba	2025-11-24 18:23:03.398347	2025-11-24 18:23:03.398347	3	+56930762579	t	2025-12-02	7	100	0	\N	\N	0.00	PKG-95603725076046	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
348	Marcos León	\N	avenida 2	último pedido	2025-11-24 18:23:03.412431	2025-11-24 18:23:03.412431	3	+56930762580	t	2025-12-03	7	105	0	\N	\N	350.00	PKG-55690377166146	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
350	Vanessa M	\N	los robles 77	caja pequeña	2025-11-24 18:23:03.423838	2025-11-24 18:23:03.423838	3	+56930762581	t	2025-12-04	7	102	0	\N	\N	180.00	PKG-44187916271761	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
352	Hugo Sáez	\N	mirador 12	ropa nueva	2025-11-24 18:23:03.434438	2025-11-24 18:23:03.434438	3	+56930762582	t	2025-12-05	7	96	0	\N	\N	0.00	PKG-08624029355426	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
354	Elena Cruz	\N	sur 14	delivery	2025-11-24 18:23:03.444763	2025-11-24 18:23:03.444763	3	+56930762583	t	2025-12-06	7	92	0	\N	\N	0.00	PKG-67853551570944	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
356	Ricardo V	\N	norte 8	encargo urgente	2025-11-24 18:23:03.454529	2025-11-24 18:23:03.454529	3	+56930762584	t	2025-12-07	7	83	0	\N	\N	700.00	PKG-73070804763805	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
358	Sonia Pinto	\N	colón 334	accesorios	2025-11-24 18:23:03.46923	2025-11-24 18:23:03.46923	3	+56930762585	t	2025-12-08	7	105	0	\N	\N	0.00	PKG-90969289915046	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
360	Andrés G	\N	puente 9	libro	2025-11-24 18:23:03.479993	2025-11-24 18:23:03.479993	3	+56930762586	t	2025-12-09	7	115	0	\N	\N	0.00	PKG-12311660531968	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
362	Karen Soto	\N	monjitas 22	autoparte	2025-11-24 18:23:03.490518	2025-11-24 18:23:03.490518	3	+56930762587	t	2025-12-10	7	83	0	\N	\N	0.00	PKG-05987296331693	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
364	Lorena V	\N	los sauces 8	artículo hogar	2025-11-24 18:23:03.500873	2025-11-24 18:23:03.500873	3	+56930762588	t	2025-12-11	7	102	0	\N	\N	160.00	PKG-46780650701492	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
366	Esteban R	\N	monte 66	producto nuevo	2025-11-24 18:23:03.510766	2025-11-24 18:23:03.510766	3	+56930762589	t	2025-12-12	7	96	0	\N	\N	260.00	PKG-86278131633703	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
368	Felipe N	\N	costanera 77	paquete chico	2025-11-24 18:23:03.52427	2025-11-24 18:23:03.52427	3	+56930762590	t	2025-12-13	7	105	0	\N	\N	115.00	PKG-64515289585071	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
369	Claudia S	\N	tramonto 34	envío estándar	2025-11-24 18:23:03.5337	2025-11-24 18:23:03.5337	3	+56930762591	t	2025-12-14	7	100	0	\N	\N	240.00	PKG-67345850833585	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
371	Matías L	\N	pasaje 5	solicitud cliente	2025-11-24 18:23:03.544907	2025-11-24 18:23:03.544907	3	+56930762592	t	2025-12-15	7	92	0	\N	\N	390.00	PKG-74879577977257	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
373	Susana J	\N	catedral 11	regalo	2025-11-24 18:23:03.557534	2025-11-24 18:23:03.557534	3	+56930762593	t	2025-12-16	7	83	0	\N	\N	0.00	PKG-47658982612620	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
375	Bernardo T	\N	los boldos 3	fragil	2025-11-24 18:23:03.569351	2025-11-24 18:23:03.569351	3	+56930762594	f	2025-12-17	7	105	0	\N	\N	0.00	PKG-51441760056337	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
378	Fabiola U	\N	sur alto 91	repuesto	2025-11-24 18:23:03.584016	2025-11-24 18:23:03.584016	3	+56930762595	f	2025-12-18	7	102	0	\N	\N	0.00	PKG-47935769096900	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
379	Sebastián Z	\N	avenida 4	envío rápido	2025-11-24 18:23:03.593892	2025-11-24 18:23:03.593892	3	+56930762596	f	2025-12-19	7	96	0	\N	\N	410.00	PKG-07877326426234	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
381	Nadia P	\N	norte chico 1	producto bebé	2025-11-24 18:23:03.604031	2025-11-24 18:23:03.604031	3	+56930762597	f	2025-12-20	7	83	0	\N	\N	150.00	PKG-16263487193252	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
383	Ramiro C	\N	los maquis 8	consulta	2025-11-24 18:23:03.613891	2025-11-24 18:23:03.613891	3	+56930762598	f	2025-12-21	7	92	0	\N	\N	200.00	PKG-07168715709432	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
385	Gabriela F	\N	krauss 10	electrónica	2025-11-24 18:23:03.624508	2025-11-24 18:23:03.624508	3	+56930762599	f	2025-12-22	7	105	0	\N	\N	0.00	PKG-86334938181862	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
387	Pedro M	\N	avenida 9	zapatos	2025-11-24 18:23:03.639229	2025-11-24 18:23:03.639229	3	+56930762600	f	2025-12-23	7	115	0	\N	\N	0.00	PKG-76017578852290	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
389	Brenda H	\N	luna 33	ropa	2025-11-24 18:23:03.649349	2025-11-24 18:23:03.649349	3	+56930762601	f	2025-12-24	7	100	0	\N	\N	0.00	PKG-92447500254414	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
391	Diego A	\N	sol 72	caja mediana	2025-11-24 18:23:03.659126	2025-11-24 18:23:03.659126	3	+56930762602	f	2025-12-25	7	102	0	\N	\N	315.00	PKG-58724401809183	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
393	Valentina Q	\N	carmen 8	utensilios	2025-11-24 18:23:03.670678	2025-11-24 18:23:03.670678	3	+56930762603	f	2025-12-26	7	83	0	\N	\N	0.00	PKG-02320074099379	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
395	Rodrigo P	\N	estrella 41	encomienda	2025-11-24 18:23:03.682124	2025-11-24 18:23:03.682124	3	+56930762604	f	2025-12-27	7	105	0	\N	\N	0.00	PKG-51374841264217	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
397	Sara K	\N	pedro 90	manual	2025-11-24 18:23:03.697884	2025-11-24 18:23:03.697884	3	+56930762605	f	2025-12-28	7	96	0	\N	\N	0.00	PKG-62547271402276	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
399	Juan A	\N	flora 19	teléfono	2025-11-24 18:23:03.708444	2025-11-24 18:23:03.708444	3	+56930762606	f	2025-12-29	7	102	0	\N	\N	0.00	PKG-57281670857663	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
400	Alicia G	\N	monteverde 8	accesorios	2025-11-24 18:23:03.719042	2025-11-24 18:23:03.719042	3	+56930762607	f	2025-12-30	7	100	0	\N	\N	0.00	PKG-18593885617082	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
402	Roberto Y	\N	angamos 3	compra online	2025-11-24 18:23:03.728012	2025-11-24 18:23:03.728012	3	+56930762608	f	2025-12-31	7	83	0	\N	\N	510.00	PKG-04617152740279	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
404	Lucía J	\N	santana 17	artículo oficina	2025-11-24 18:23:03.73789	2025-11-24 18:23:03.73789	3	+56930762609	f	2026-01-01	7	92	0	\N	\N	230.00	PKG-13264188731740	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
407	Gonzalo H	\N	paceo 91	pedido recurrente	2025-11-24 18:23:03.757078	2025-11-24 18:23:03.757078	3	+56930762610	f	2026-01-02	7	105	0	\N	\N	330.00	PKG-06191408654529	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
409	Mariela R	\N	avenida 12	ropa deportiva	2025-11-24 18:23:03.768904	2025-11-24 18:23:03.768904	3	+56930762611	f	2026-01-03	7	102	0	\N	\N	260.00	PKG-01089267440452	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
410	Joel D	\N	fast 55	producto importado	2025-11-24 18:23:03.779336	2025-11-24 18:23:03.779336	3	+56930762612	f	2026-01-04	7	115	0	\N	\N	720.00	PKG-84508729053042	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
412	Mónica T	\N	tribuna 90	dispositivo	2025-11-24 18:23:03.789792	2025-11-24 18:23:03.789792	3	+56930762613	f	2026-01-05	7	100	0	\N	\N	0.00	PKG-16168144039979	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
414	Patricio S	\N	balmaceda 99	regalo cliente	2025-11-24 18:23:03.799572	2025-11-24 18:23:03.799572	3	+56930762614	f	2026-01-06	7	83	0	\N	\N	195.00	PKG-36562172016453	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
417	Javiera K	\N	olmos 14	delivery express	2025-11-24 18:23:03.814314	2025-11-24 18:23:03.814314	3	+56930762615	f	2026-01-07	7	92	0	\N	\N	350.00	PKG-43947191338736	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
419	Ismael N	\N	teja sur 22	productos varios	2025-11-24 18:23:03.824669	2025-11-24 18:23:03.824669	3	+56930762616	f	2026-01-08	7	105	0	\N	\N	430.00	PKG-44706107456812	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
420	Beatriz O	\N	urmeneta 1	agua embotellada	2025-11-24 18:23:03.83418	2025-11-24 18:23:03.83418	3	+56930762617	f	2026-01-09	7	102	0	\N	\N	90.00	PKG-30368527953633	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
422	Froilán Z	\N	comandante 7	libro de estudio	2025-11-24 18:23:03.84414	2025-11-24 18:23:03.84414	3	+56930762618	f	2026-01-10	7	96	0	\N	\N	240.00	PKG-65761885260863	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
424	Denisse Q	\N	ramón 88	petición especial	2025-11-24 18:23:03.854601	2025-11-24 18:23:03.854601	3	+56930762619	f	2026-01-11	7	83	0	\N	\N	610.00	PKG-48155234870906	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
427	Alan V	\N	rio alto 3	insumo médico	2025-11-24 18:23:03.869397	2025-11-24 18:23:03.869397	3	+56930762620	f	2026-01-12	7	92	0	\N	\N	980.00	PKG-53216971751725	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
429	Olga M	\N	quinta 4	vestuario	2025-11-24 18:23:03.879843	2025-11-24 18:23:03.879843	3	+56930762621	f	2026-01-13	7	105	0	\N	\N	0.00	PKG-75144910950742	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
430	Bastián E	\N	canal 87	envío simple	2025-11-24 18:23:03.891285	2025-11-24 18:23:03.891285	3	+56930762622	f	2026-01-14	7	102	0	\N	\N	130.00	PKG-87733161416066	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
432	Ximena T	\N	canto 11	caja gigante	2025-11-24 18:23:03.900797	2025-11-24 18:23:03.900797	3	+56930762623	f	2026-01-15	7	100	0	\N	\N	540.00	PKG-18484890041004	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
434	César L	\N	alto sur 2	entrega express	2025-11-24 18:23:03.910742	2025-11-24 18:23:03.910742	3	+56930762624	f	2026-01-16	7	83	0	\N	\N	320.00	PKG-44925110006814	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
437	Florencia I	\N	patio 66	elemento frágil	2025-11-24 18:23:03.924868	2025-11-24 18:23:03.924868	3	+56930762625	f	2026-01-17	7	96	0	\N	\N	470.00	PKG-48930012361181	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
439	Jeremías F	\N	loma 17	pedido	2025-11-24 18:23:03.935016	2025-11-24 18:23:03.935016	3	+56930762626	f	2026-01-18	7	105	0	\N	\N	230.00	PKG-82535164330229	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
440	Carolina D	\N	los sauces 1	compra cliente	2025-11-24 18:23:03.944422	2025-11-24 18:23:03.944422	3	+56930762627	f	2026-01-19	7	102	0	\N	\N	160.00	PKG-50463426432510	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
442	Tomás G	\N	los acacios 9	pieza repuesto	2025-11-24 18:23:03.955564	2025-11-24 18:23:03.955564	3	+56930762628	f	2026-01-20	7	92	0	\N	\N	490.00	PKG-59189526061168	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
444	Romina H	\N	avenida 44	regalo sorpresa	2025-11-24 18:23:03.965482	2025-11-24 18:23:03.965482	3	+56930762629	f	2026-01-21	7	115	0	\N	\N	150.00	PKG-30508757111520	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
447	Gabriel C	\N	pedro II 8	objecto nuevo	2025-11-24 18:23:03.979396	2025-11-24 18:23:03.979396	3	+56930762630	f	2026-01-22	7	83	0	\N	\N	280.00	PKG-72496459764244	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
449	Fernanda P	\N	monte real 3	accesorio hogar	2025-11-24 18:23:03.988544	2025-11-24 18:23:03.988544	3	+56930762631	f	2026-01-23	7	96	0	\N	\N	330.00	PKG-87816111265492	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
450	Héctor M	\N	colón 81	producto digital	2025-11-24 18:23:03.998875	2025-11-24 18:23:03.998875	3	+56930762632	f	2026-01-24	7	105	0	\N	\N	525.00	PKG-20974299260755	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
452	Paola Y	\N	estrella 33	pañales	2025-11-24 18:23:04.009295	2025-11-24 18:23:04.009295	3	+56930762633	f	2026-01-25	7	102	0	\N	\N	0.00	PKG-51418054657795	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
454	Ángel A	\N	sol 100	alimento	2025-11-24 18:23:04.020433	2025-11-24 18:23:04.020433	3	+56930762634	f	2026-01-26	7	92	0	\N	\N	0.00	PKG-97319128126019	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
457	Yesenia L	\N	avenida 7	bebida	2025-11-24 18:23:04.035349	2025-11-24 18:23:04.035349	3	+56930762635	f	2026-01-27	7	100	0	\N	\N	0.00	PKG-79639141349597	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
459	Rafael O	\N	oro 55	solicitud general	2025-11-24 18:23:04.046446	2025-11-24 18:23:04.046446	3	+56930762636	f	2026-01-28	7	83	0	\N	\N	150.00	PKG-52655487213095	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
461	Valery R	\N	verde 44	producto gourmet	2025-11-24 18:23:04.057037	2025-11-24 18:23:04.057037	3	+56930762637	f	2026-01-29	7	105	0	\N	\N	740.00	PKG-69843275983718	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
463	Cristóbal T	\N	central 19	repuesto auto	2025-11-24 18:23:04.067055	2025-11-24 18:23:04.067055	3	+56930762638	f	2026-01-30	7	96	0	\N	\N	350.00	PKG-79075011439777	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
465	Lina J	\N	pedregal 11	insumo técnico	2025-11-24 18:23:04.078912	2025-11-24 18:23:04.078912	3	+56930762639	f	2026-01-31	7	102	0	\N	\N	275.00	PKG-09019102110152	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
467	Maximiliano B	\N	rio 90	accesorio gamer	2025-11-24 18:23:04.093649	2025-11-24 18:23:04.093649	3	+56930762640	f	2026-02-01	7	92	0	\N	\N	510.00	PKG-16910191450475	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
469	Pilar E	\N	lagos 82	objeto hogar	2025-11-24 18:23:04.1057	2025-11-24 18:23:04.1057	3	+56930762641	f	2026-02-02	7	83	0	\N	\N	200.00	PKG-19209043169415	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
471	Tadeo P	\N	costa azul 5	pedido interno	2025-11-24 18:23:04.115694	2025-11-24 18:23:04.115694	3	+56930762642	f	2026-02-03	7	105	0	\N	\N	330.00	PKG-99490811520142	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
473	Agustina L	\N	montaña 2	mueble pequeño	2025-11-24 18:23:04.124899	2025-11-24 18:23:04.124899	3	+56930762643	f	2026-02-04	7	96	0	\N	\N	780.00	PKG-15342241013420	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
475	Julián F	\N	avenida 5	pedido rápido	2025-11-24 18:23:04.135815	2025-11-24 18:23:04.135815	3	+56930762644	f	2026-02-05	7	102	0	\N	\N	120.00	PKG-11256683040292	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
477	Marta A	\N	luna 7	mercadería	2025-11-24 18:23:04.148925	2025-11-24 18:23:04.148925	3	+56930762645	f	2026-02-06	7	115	0	\N	\N	0.00	PKG-81788413959382	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
479	Leandro D	\N	avenida 15	ropa invierno	2025-11-24 18:23:04.16085	2025-11-24 18:23:04.16085	3	+56930762646	f	2026-02-07	7	100	0	\N	\N	290.00	PKG-51326913281751	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
480	Emilia G	\N	pasaje 8	perfume	2025-11-24 18:23:04.17118	2025-11-24 18:23:04.17118	3	+56930762647	f	2026-02-08	7	83	0	\N	\N	0.00	PKG-69959610268992	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
482	Benjamín C	\N	bosque 17	artículo cocina	2025-11-24 18:23:04.181068	2025-11-24 18:23:04.181068	3	+56930762648	f	2026-02-09	7	105	0	\N	\N	230.00	PKG-87886789638842	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
484	Inés H	\N	cerro 88	producto nuevo	2025-11-24 18:23:04.190696	2025-11-24 18:23:04.190696	3	+56930762649	f	2026-02-10	7	92	0	\N	\N	480.00	PKG-84964312422454	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
486	Alonso T	\N	rio largo 22	insumo técnico	2025-11-24 18:23:04.207588	2025-11-24 18:23:04.207588	3	+56930762650	f	2026-02-11	7	102	0	\N	\N	310.00	PKG-96471023259618	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
488	Constanza Y	\N	ruta 44	accesorio hogar	2025-11-24 18:23:04.217873	2025-11-24 18:23:04.217873	3	+56930762651	f	2026-02-12	7	115	0	\N	\N	160.00	PKG-66596104570787	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
490	Kevin M	\N	croacia 5	caja pequeña	2025-11-24 18:23:04.228879	2025-11-24 18:23:04.228879	3	+56930762652	f	2026-02-13	7	83	0	\N	\N	120.00	PKG-82640619570854	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
492	Aranza R	\N	loto 66	juguete	2025-11-24 18:23:04.239949	2025-11-24 18:23:04.239949	3	+56930762653	f	2026-02-14	7	96	0	\N	\N	0.00	PKG-45838629803349	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
494	Thiago S	\N	avenida 99	comida	2025-11-24 18:23:04.251581	2025-11-24 18:23:04.251581	3	+56930762654	f	2026-02-15	7	105	0	\N	\N	0.00	PKG-22283896513856	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
496	Juan José L	\N	faro 3	lámpara	2025-11-24 18:23:04.265753	2025-11-24 18:23:04.265753	3	+56930762655	f	2026-02-16	7	102	0	\N	\N	0.00	PKG-35535272198133	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
498	Fernanda C	\N	pedro 6	productos varios	2025-11-24 18:23:04.277462	2025-11-24 18:23:04.277462	3	+56930762656	f	2026-02-17	7	83	0	\N	\N	140.00	PKG-74484587491315	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
500	Elías U	\N	calle 10	notebook	2025-11-24 18:23:04.288095	2025-11-24 18:23:04.288095	3	+56930762657	f	2026-02-18	7	100	0	\N	\N	0.00	PKG-81641790685342	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
502	Trinidad M	\N	carmen 77	artículos bebés	2025-11-24 18:23:04.298529	2025-11-24 18:23:04.298529	3	+56930762658	f	2026-02-19	7	92	0	\N	\N	260.00	PKG-35283467028387	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
423	Ismael N	\N	teja sur 22	productos varios	2025-11-24 18:23:03.847503	2025-11-24 18:23:03.847503	3	+56930762616	f	2026-01-08	7	105	0	\N	\N	430.00	PKG-79345945801915	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
425	Beatriz O	\N	urmeneta 1	agua embotellada	2025-11-24 18:23:03.857387	2025-11-24 18:23:03.857387	3	+56930762617	f	2026-01-09	7	102	0	\N	\N	90.00	PKG-58667572239156	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
426	Froilán Z	\N	comandante 7	libro de estudio	2025-11-24 18:23:03.867022	2025-11-24 18:23:03.867022	3	+56930762618	f	2026-01-10	7	96	0	\N	\N	240.00	PKG-64665437690281	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
428	Denisse Q	\N	ramón 88	petición especial	2025-11-24 18:23:03.877496	2025-11-24 18:23:03.877496	3	+56930762619	f	2026-01-11	7	83	0	\N	\N	610.00	PKG-03589170513570	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
431	Alan V	\N	rio alto 3	insumo médico	2025-11-24 18:23:03.892641	2025-11-24 18:23:03.892641	3	+56930762620	f	2026-01-12	7	92	0	\N	\N	980.00	PKG-88972337161617	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
433	Olga M	\N	quinta 4	vestuario	2025-11-24 18:23:03.903318	2025-11-24 18:23:03.903318	3	+56930762621	f	2026-01-13	7	105	0	\N	\N	0.00	PKG-74034665940711	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
435	Bastián E	\N	canal 87	envío simple	2025-11-24 18:23:03.913199	2025-11-24 18:23:03.913199	3	+56930762622	f	2026-01-14	7	102	0	\N	\N	130.00	PKG-22527035411178	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
436	Ximena T	\N	canto 11	caja gigante	2025-11-24 18:23:03.922299	2025-11-24 18:23:03.922299	3	+56930762623	f	2026-01-15	7	100	0	\N	\N	540.00	PKG-03272647714375	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
438	César L	\N	alto sur 2	entrega express	2025-11-24 18:23:03.932339	2025-11-24 18:23:03.932339	3	+56930762624	f	2026-01-16	7	83	0	\N	\N	320.00	PKG-83995425654867	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
441	Florencia I	\N	patio 66	elemento frágil	2025-11-24 18:23:03.946671	2025-11-24 18:23:03.946671	3	+56930762625	f	2026-01-17	7	96	0	\N	\N	470.00	PKG-38056755932126	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
443	Jeremías F	\N	loma 17	pedido	2025-11-24 18:23:03.956901	2025-11-24 18:23:03.956901	3	+56930762626	f	2026-01-18	7	105	0	\N	\N	230.00	PKG-75648997460463	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
445	Carolina D	\N	los sauces 1	compra cliente	2025-11-24 18:23:03.967106	2025-11-24 18:23:03.967106	3	+56930762627	f	2026-01-19	7	102	0	\N	\N	160.00	PKG-61898781424860	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
446	Tomás G	\N	los acacios 9	pieza repuesto	2025-11-24 18:23:03.976049	2025-11-24 18:23:03.976049	3	+56930762628	f	2026-01-20	7	92	0	\N	\N	490.00	PKG-67097371511424	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
448	Romina H	\N	avenida 44	regalo sorpresa	2025-11-24 18:23:03.985866	2025-11-24 18:23:03.985866	3	+56930762629	f	2026-01-21	7	115	0	\N	\N	150.00	PKG-45083155775374	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
451	Gabriel C	\N	pedro II 8	objecto nuevo	2025-11-24 18:23:04.000474	2025-11-24 18:23:04.000474	3	+56930762630	f	2026-01-22	7	83	0	\N	\N	280.00	PKG-47088818357397	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
453	Fernanda P	\N	monte real 3	accesorio hogar	2025-11-24 18:23:04.011006	2025-11-24 18:23:04.011006	3	+56930762631	f	2026-01-23	7	96	0	\N	\N	330.00	PKG-76918997296497	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
455	Héctor M	\N	colón 81	producto digital	2025-11-24 18:23:04.021803	2025-11-24 18:23:04.021803	3	+56930762632	f	2026-01-24	7	105	0	\N	\N	525.00	PKG-70454368132228	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
456	Paola Y	\N	estrella 33	pañales	2025-11-24 18:23:04.031306	2025-11-24 18:23:04.031306	3	+56930762633	f	2026-01-25	7	102	0	\N	\N	0.00	PKG-32829053661685	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
458	Ángel A	\N	sol 100	alimento	2025-11-24 18:23:04.042215	2025-11-24 18:23:04.042215	3	+56930762634	f	2026-01-26	7	92	0	\N	\N	0.00	PKG-12147454745241	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
460	Yesenia L	\N	avenida 7	bebida	2025-11-24 18:23:04.055681	2025-11-24 18:23:04.055681	3	+56930762635	f	2026-01-27	7	100	0	\N	\N	0.00	PKG-52090071402289	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
462	Rafael O	\N	oro 55	solicitud general	2025-11-24 18:23:04.065671	2025-11-24 18:23:04.065671	3	+56930762636	f	2026-01-28	7	83	0	\N	\N	150.00	PKG-45804392625120	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
464	Valery R	\N	verde 44	producto gourmet	2025-11-24 18:23:04.077547	2025-11-24 18:23:04.077547	3	+56930762637	f	2026-01-29	7	105	0	\N	\N	740.00	PKG-73296042920674	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
466	Cristóbal T	\N	central 19	repuesto auto	2025-11-24 18:23:04.087807	2025-11-24 18:23:04.087807	3	+56930762638	f	2026-01-30	7	96	0	\N	\N	350.00	PKG-55458282643875	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
468	Lina J	\N	pedregal 11	insumo técnico	2025-11-24 18:23:04.097961	2025-11-24 18:23:04.097961	3	+56930762639	f	2026-01-31	7	102	0	\N	\N	275.00	PKG-56486481764443	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
470	Maximiliano B	\N	rio 90	accesorio gamer	2025-11-24 18:23:04.111377	2025-11-24 18:23:04.111377	3	+56930762640	f	2026-02-01	7	92	0	\N	\N	510.00	PKG-88996493673833	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
472	Pilar E	\N	lagos 82	objeto hogar	2025-11-24 18:23:04.121982	2025-11-24 18:23:04.121982	3	+56930762641	f	2026-02-02	7	83	0	\N	\N	200.00	PKG-70658947489324	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
474	Tadeo P	\N	costa azul 5	pedido interno	2025-11-24 18:23:04.133081	2025-11-24 18:23:04.133081	3	+56930762642	f	2026-02-03	7	105	0	\N	\N	330.00	PKG-04181496980941	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
476	Agustina L	\N	montaña 2	mueble pequeño	2025-11-24 18:23:04.14586	2025-11-24 18:23:04.14586	3	+56930762643	f	2026-02-04	7	96	0	\N	\N	780.00	PKG-81503295864387	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
478	Julián F	\N	avenida 5	pedido rápido	2025-11-24 18:23:04.158189	2025-11-24 18:23:04.158189	3	+56930762644	f	2026-02-05	7	102	0	\N	\N	120.00	PKG-11716743876323	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
481	Marta A	\N	luna 7	mercadería	2025-11-24 18:23:04.175108	2025-11-24 18:23:04.175108	3	+56930762645	f	2026-02-06	7	115	0	\N	\N	0.00	PKG-29882267762267	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
483	Leandro D	\N	avenida 15	ropa invierno	2025-11-24 18:23:04.186523	2025-11-24 18:23:04.186523	3	+56930762646	f	2026-02-07	7	100	0	\N	\N	290.00	PKG-81922879857340	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
485	Emilia G	\N	pasaje 8	perfume	2025-11-24 18:23:04.197984	2025-11-24 18:23:04.197984	3	+56930762647	f	2026-02-08	7	83	0	\N	\N	0.00	PKG-53951469103284	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
487	Benjamín C	\N	bosque 17	artículo cocina	2025-11-24 18:23:04.210348	2025-11-24 18:23:04.210348	3	+56930762648	f	2026-02-09	7	105	0	\N	\N	230.00	PKG-68318028173390	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
489	Inés H	\N	cerro 88	producto nuevo	2025-11-24 18:23:04.221905	2025-11-24 18:23:04.221905	3	+56930762649	f	2026-02-10	7	92	0	\N	\N	480.00	PKG-20418836289498	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
491	Alonso T	\N	rio largo 22	insumo técnico	2025-11-24 18:23:04.237184	2025-11-24 18:23:04.237184	3	+56930762650	f	2026-02-11	7	102	0	\N	\N	310.00	PKG-47981690417590	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
493	Constanza Y	\N	ruta 44	accesorio hogar	2025-11-24 18:23:04.248272	2025-11-24 18:23:04.248272	3	+56930762651	f	2026-02-12	7	115	0	\N	\N	160.00	PKG-89498542940604	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
495	Kevin M	\N	croacia 5	caja pequeña	2025-11-24 18:23:04.258941	2025-11-24 18:23:04.258941	3	+56930762652	f	2026-02-13	7	83	0	\N	\N	120.00	PKG-92371774456296	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
497	Aranza R	\N	loto 66	juguete	2025-11-24 18:23:04.27039	2025-11-24 18:23:04.27039	3	+56930762653	f	2026-02-14	7	96	0	\N	\N	0.00	PKG-52109232451924	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
499	Thiago S	\N	avenida 99	comida	2025-11-24 18:23:04.281931	2025-11-24 18:23:04.281931	3	+56930762654	f	2026-02-15	7	105	0	\N	\N	0.00	PKG-72956700552905	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
501	Juan José L	\N	faro 3	lámpara	2025-11-24 18:23:04.295976	2025-11-24 18:23:04.295976	3	+56930762655	f	2026-02-16	7	102	0	\N	\N	0.00	PKG-06763138463476	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
503	Fernanda C	\N	pedro 6	productos varios	2025-11-24 18:23:04.306177	2025-11-24 18:23:04.306177	3	+56930762656	f	2026-02-17	7	83	0	\N	\N	140.00	PKG-31601873726217	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
505	Elías U	\N	calle 10	notebook	2025-11-24 18:23:04.316472	2025-11-24 18:23:04.316472	3	+56930762657	f	2026-02-18	7	100	0	\N	\N	0.00	PKG-65327443177823	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
504	Alfredo Z	\N	subida 4	implementos	2025-11-24 18:23:04.308557	2025-11-24 18:23:04.308557	3	+56930762659	f	2026-02-20	7	96	0	\N	\N	0.00	PKG-71149202576903	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
506	Romina B	\N	rosales 11	accesorio auto	2025-11-24 18:23:04.323355	2025-11-24 18:23:04.323355	3	+56930762660	f	2026-02-21	7	105	0	\N	\N	180.00	PKG-38279170542979	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
508	Sherly V	\N	rio gris 2	té especial	2025-11-24 18:23:04.334861	2025-11-24 18:23:04.334861	3	+56930762661	f	2026-02-22	7	83	0	\N	\N	0.00	PKG-42482616980952	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
510	Leonardo H	\N	lira 44	servicio técnico	2025-11-24 18:23:04.346567	2025-11-24 18:23:04.346567	3	+56930762662	f	2026-02-23	7	102	0	\N	\N	520.00	PKG-91598666643577	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
512	Amparo J	\N	pedro 19	taza cerámica	2025-11-24 18:23:04.356554	2025-11-24 18:23:04.356554	3	+56930762663	f	2026-02-24	7	100	0	\N	\N	110.00	PKG-28486807482701	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
514	Elvira P	\N	rio profundo 1	insumos limpeza	2025-11-24 18:23:04.366599	2025-11-24 18:23:04.366599	3	+56930762664	f	2026-02-25	7	115	0	\N	\N	140.00	PKG-27803459296003	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
516	Oliver Y	\N	avenida 121	material oficina	2025-11-24 18:23:04.381495	2025-11-24 18:23:04.381495	3	+56930762665	f	2026-02-26	7	83	0	\N	\N	260.00	PKG-53539286848638	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
518	Selena A	\N	los cedros 3	plato vidrio	2025-11-24 18:23:04.392099	2025-11-24 18:23:04.392099	3	+56930762666	f	2026-02-27	7	92	0	\N	\N	130.00	PKG-23386499248890	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
520	Eduardo T	\N	ulmo 17	producto premium	2025-11-24 18:23:04.40354	2025-11-24 18:23:04.40354	3	+56930762667	f	2026-02-28	7	105	0	\N	\N	870.00	PKG-58534051173952	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
522	Rocío E	\N	lago azul 8	regalo especial	2025-11-24 18:23:04.414841	2025-11-24 18:23:04.414841	3	+56930762668	f	2026-03-01	7	96	0	\N	\N	190.00	PKG-45701671052656	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
524	Mario R	\N	arbustos 7	audífonos	2025-11-24 18:23:04.425833	2025-11-24 18:23:04.425833	3	+56930762669	f	2026-03-02	7	102	0	\N	\N	0.00	PKG-76338675778538	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
507	Trinidad M	\N	carmen 77	artículos bebés	2025-11-24 18:23:04.32711	2025-11-24 18:23:04.32711	3	+56930762658	f	2026-02-19	7	92	0	\N	\N	260.00	PKG-80581184989678	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
509	Alfredo Z	\N	subida 4	implementos	2025-11-24 18:23:04.338726	2025-11-24 18:23:04.338726	3	+56930762659	f	2026-02-20	7	96	0	\N	\N	0.00	PKG-02276191144310	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
511	Romina B	\N	rosales 11	accesorio auto	2025-11-24 18:23:04.353398	2025-11-24 18:23:04.353398	3	+56930762660	f	2026-02-21	7	105	0	\N	\N	180.00	PKG-86257805736335	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
513	Sherly V	\N	rio gris 2	té especial	2025-11-24 18:23:04.365192	2025-11-24 18:23:04.365192	3	+56930762661	f	2026-02-22	7	83	0	\N	\N	0.00	PKG-12468695228349	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
515	Leonardo H	\N	lira 44	servicio técnico	2025-11-24 18:23:04.375835	2025-11-24 18:23:04.375835	3	+56930762662	f	2026-02-23	7	102	0	\N	\N	520.00	PKG-11869381028106	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
517	Amparo J	\N	pedro 19	taza cerámica	2025-11-24 18:23:04.386662	2025-11-24 18:23:04.386662	3	+56930762663	f	2026-02-24	7	100	0	\N	\N	110.00	PKG-41523977116429	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
519	Elvira P	\N	rio profundo 1	insumos limpeza	2025-11-24 18:23:04.397316	2025-11-24 18:23:04.397316	3	+56930762664	f	2026-02-25	7	115	0	\N	\N	140.00	PKG-13114772106299	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
521	Oliver Y	\N	avenida 121	material oficina	2025-11-24 18:23:04.413167	2025-11-24 18:23:04.413167	3	+56930762665	f	2026-02-26	7	83	0	\N	\N	260.00	PKG-93436272430938	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
523	Selena A	\N	los cedros 3	plato vidrio	2025-11-24 18:23:04.424587	2025-11-24 18:23:04.424587	3	+56930762666	f	2026-02-27	7	92	0	\N	\N	130.00	PKG-19846380356793	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
525	Eduardo T	\N	ulmo 17	producto premium	2025-11-24 18:23:04.435482	2025-11-24 18:23:04.435482	3	+56930762667	f	2026-02-28	7	105	0	\N	\N	870.00	PKG-48277547837387	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
526	Rocío E	\N	lago azul 8	regalo especial	2025-11-24 18:23:04.444039	2025-11-24 18:23:04.444039	3	+56930762668	f	2026-03-01	7	96	0	\N	\N	190.00	PKG-62321465754687	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
527	Mario R	\N	arbustos 7	audífonos	2025-11-24 18:23:04.450663	2025-11-24 18:23:04.450663	3	+56930762669	f	2026-03-02	7	102	0	\N	\N	0.00	PKG-04689283120728	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
528	Cristina 1	\N	ninune	algo puede	2025-11-24 18:24:25.095856	2025-11-24 18:24:25.095856	3	+56930762571	t	2025-11-24	7	102	0	\N	\N	0.00	PKG-11233705348746	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
529	Carlos 1	\N	rasaz	rata	2025-11-24 18:24:25.104074	2025-11-24 18:24:25.104074	3	+56930762572	t	2025-11-25	7	96	0	\N	\N	0.00	PKG-91490972648043	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
530	Ana Soto	\N	avenida 1	entrega rápida	2025-11-24 18:24:25.114379	2025-11-24 18:24:25.114379	3	+56930762573	t	2025-11-26	7	105	0	\N	\N	500.00	PKG-00161464706773	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
531	Luis Rojas	\N	calle sur 22	paquete frágil	2025-11-24 18:24:25.123964	2025-11-24 18:24:25.123964	3	+56930762574	t	2025-11-27	7	102	0	\N	\N	320.00	PKG-41968324738879	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
532	María Vera	\N	los pinos 44	documentos	2025-11-24 18:24:25.138056	2025-11-24 18:24:25.138056	3	+56930762575	t	2025-11-28	7	92	0	\N	\N	90.00	PKG-34807771009221	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
533	Pablo Díaz	\N	oro verde 11	hogar	2025-11-24 18:24:25.147046	2025-11-24 18:24:25.147046	3	+56930762576	t	2025-11-29	7	115	0	\N	\N	0.00	PKG-25293547004330	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
534	Daniela Paz	\N	central 98	solicitud nueva	2025-11-24 18:24:25.154299	2025-11-24 18:24:25.154299	3	+56930762577	t	2025-11-30	7	105	0	\N	\N	245.00	PKG-84107514615664	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
535	José Toro	\N	rio azul 9	compra online	2025-11-24 18:24:25.161557	2025-11-24 18:24:25.161557	3	+56930762578	t	2025-12-01	7	83	0	\N	\N	600.00	PKG-81147532887218	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
536	Carla Núñez	\N	pedro 33	prueba	2025-11-24 18:24:25.168992	2025-11-24 18:24:25.168992	3	+56930762579	t	2025-12-02	7	100	0	\N	\N	0.00	PKG-65202038491606	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
537	Marcos León	\N	avenida 2	último pedido	2025-11-24 18:24:25.181021	2025-11-24 18:24:25.181021	3	+56930762580	t	2025-12-03	7	105	0	\N	\N	350.00	PKG-58036267833266	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
538	Vanessa M	\N	los robles 77	caja pequeña	2025-11-24 18:24:25.188735	2025-11-24 18:24:25.188735	3	+56930762581	t	2025-12-04	7	102	0	\N	\N	180.00	PKG-65297861582532	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
539	Hugo Sáez	\N	mirador 12	ropa nueva	2025-11-24 18:24:25.196355	2025-11-24 18:24:25.196355	3	+56930762582	t	2025-12-05	7	96	0	\N	\N	0.00	PKG-17907311502120	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
540	Elena Cruz	\N	sur 14	delivery	2025-11-24 18:24:25.202479	2025-11-24 18:24:25.202479	3	+56930762583	t	2025-12-06	7	92	0	\N	\N	0.00	PKG-94696730996465	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
541	Ricardo V	\N	norte 8	encargo urgente	2025-11-24 18:24:25.209455	2025-11-24 18:24:25.209455	3	+56930762584	t	2025-12-07	7	83	0	\N	\N	700.00	PKG-46562093171126	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
542	Sonia Pinto	\N	colón 334	accesorios	2025-11-24 18:24:25.218936	2025-11-24 18:24:25.218936	3	+56930762585	t	2025-12-08	7	105	0	\N	\N	0.00	PKG-52436525458925	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
543	Andrés G	\N	puente 9	libro	2025-11-24 18:24:25.226124	2025-11-24 18:24:25.226124	3	+56930762586	t	2025-12-09	7	115	0	\N	\N	0.00	PKG-46840993222055	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
544	Karen Soto	\N	monjitas 22	autoparte	2025-11-24 18:24:25.232609	2025-11-24 18:24:25.232609	3	+56930762587	t	2025-12-10	7	83	0	\N	\N	0.00	PKG-80682877959081	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
545	Lorena V	\N	los sauces 8	artículo hogar	2025-11-24 18:24:25.238411	2025-11-24 18:24:25.238411	3	+56930762588	t	2025-12-11	7	102	0	\N	\N	160.00	PKG-84481482620364	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
546	Esteban R	\N	monte 66	producto nuevo	2025-11-24 18:24:25.244188	2025-11-24 18:24:25.244188	3	+56930762589	t	2025-12-12	7	96	0	\N	\N	260.00	PKG-03741005812872	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
547	Felipe N	\N	costanera 77	paquete chico	2025-11-24 18:24:25.252324	2025-11-24 18:24:25.252324	3	+56930762590	t	2025-12-13	7	105	0	\N	\N	115.00	PKG-56090305975610	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
548	Claudia S	\N	tramonto 34	envío estándar	2025-11-24 18:24:25.259207	2025-11-24 18:24:25.259207	3	+56930762591	t	2025-12-14	7	100	0	\N	\N	240.00	PKG-66411791152505	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
549	Matías L	\N	pasaje 5	solicitud cliente	2025-11-24 18:24:25.265526	2025-11-24 18:24:25.265526	3	+56930762592	t	2025-12-15	7	92	0	\N	\N	390.00	PKG-20530140186731	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
550	Susana J	\N	catedral 11	regalo	2025-11-24 18:24:25.271438	2025-11-24 18:24:25.271438	3	+56930762593	t	2025-12-16	7	83	0	\N	\N	0.00	PKG-05234602890988	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
551	Bernardo T	\N	los boldos 3	fragil	2025-11-24 18:24:25.277245	2025-11-24 18:24:25.277245	3	+56930762594	f	2025-12-17	7	105	0	\N	\N	0.00	PKG-34004024950330	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
552	Fabiola U	\N	sur alto 91	repuesto	2025-11-24 18:24:25.285188	2025-11-24 18:24:25.285188	3	+56930762595	f	2025-12-18	7	102	0	\N	\N	0.00	PKG-61060612685031	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
553	Sebastián Z	\N	avenida 4	envío rápido	2025-11-24 18:24:25.290692	2025-11-24 18:24:25.290692	3	+56930762596	f	2025-12-19	7	96	0	\N	\N	410.00	PKG-17707775538804	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
554	Nadia P	\N	norte chico 1	producto bebé	2025-11-24 18:24:25.296241	2025-11-24 18:24:25.296241	3	+56930762597	f	2025-12-20	7	83	0	\N	\N	150.00	PKG-78460417425334	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
555	Ramiro C	\N	los maquis 8	consulta	2025-11-24 18:24:25.301708	2025-11-24 18:24:25.301708	3	+56930762598	f	2025-12-21	7	92	0	\N	\N	200.00	PKG-44225240576814	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
556	Gabriela F	\N	krauss 10	electrónica	2025-11-24 18:24:25.307288	2025-11-24 18:24:25.307288	3	+56930762599	f	2025-12-22	7	105	0	\N	\N	0.00	PKG-49309201489408	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
557	Pedro M	\N	avenida 9	zapatos	2025-11-24 18:24:25.315192	2025-11-24 18:24:25.315192	3	+56930762600	f	2025-12-23	7	115	0	\N	\N	0.00	PKG-60848178000839	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
558	Brenda H	\N	luna 33	ropa	2025-11-24 18:24:25.320747	2025-11-24 18:24:25.320747	3	+56930762601	f	2025-12-24	7	100	0	\N	\N	0.00	PKG-83598571745051	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
559	Diego A	\N	sol 72	caja mediana	2025-11-24 18:24:25.327138	2025-11-24 18:24:25.327138	3	+56930762602	f	2025-12-25	7	102	0	\N	\N	315.00	PKG-52685831488659	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
560	Valentina Q	\N	carmen 8	utensilios	2025-11-24 18:24:25.333068	2025-11-24 18:24:25.333068	3	+56930762603	f	2025-12-26	7	83	0	\N	\N	0.00	PKG-34536002449427	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
561	Rodrigo P	\N	estrella 41	encomienda	2025-11-24 18:24:25.339707	2025-11-24 18:24:25.339707	3	+56930762604	f	2025-12-27	7	105	0	\N	\N	0.00	PKG-28402888779362	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
562	Sara K	\N	pedro 90	manual	2025-11-24 18:24:25.347766	2025-11-24 18:24:25.347766	3	+56930762605	f	2025-12-28	7	96	0	\N	\N	0.00	PKG-03905475976490	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
563	Juan A	\N	flora 19	teléfono	2025-11-24 18:24:25.35341	2025-11-24 18:24:25.35341	3	+56930762606	f	2025-12-29	7	102	0	\N	\N	0.00	PKG-67348958241150	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
564	Alicia G	\N	monteverde 8	accesorios	2025-11-24 18:24:25.359116	2025-11-24 18:24:25.359116	3	+56930762607	f	2025-12-30	7	100	0	\N	\N	0.00	PKG-59937232786840	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
565	Roberto Y	\N	angamos 3	compra online	2025-11-24 18:24:25.364825	2025-11-24 18:24:25.364825	3	+56930762608	f	2025-12-31	7	83	0	\N	\N	510.00	PKG-13556796092103	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
566	Lucía J	\N	santana 17	artículo oficina	2025-11-24 18:24:25.370434	2025-11-24 18:24:25.370434	3	+56930762609	f	2026-01-01	7	92	0	\N	\N	230.00	PKG-59855138671228	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
567	Gonzalo H	\N	paceo 91	pedido recurrente	2025-11-24 18:24:25.378439	2025-11-24 18:24:25.378439	3	+56930762610	f	2026-01-02	7	105	0	\N	\N	330.00	PKG-78103562463095	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
568	Mariela R	\N	avenida 12	ropa deportiva	2025-11-24 18:24:25.384188	2025-11-24 18:24:25.384188	3	+56930762611	f	2026-01-03	7	102	0	\N	\N	260.00	PKG-46744994728518	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
569	Joel D	\N	fast 55	producto importado	2025-11-24 18:24:25.389789	2025-11-24 18:24:25.389789	3	+56930762612	f	2026-01-04	7	115	0	\N	\N	720.00	PKG-43984982353480	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
570	Mónica T	\N	tribuna 90	dispositivo	2025-11-24 18:24:25.395257	2025-11-24 18:24:25.395257	3	+56930762613	f	2026-01-05	7	100	0	\N	\N	0.00	PKG-71946796364980	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
571	Patricio S	\N	balmaceda 99	regalo cliente	2025-11-24 18:24:25.402095	2025-11-24 18:24:25.402095	3	+56930762614	f	2026-01-06	7	83	0	\N	\N	195.00	PKG-54422843153925	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
572	Javiera K	\N	olmos 14	delivery express	2025-11-24 18:24:25.411024	2025-11-24 18:24:25.411024	3	+56930762615	f	2026-01-07	7	92	0	\N	\N	350.00	PKG-31855484305746	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
573	Ismael N	\N	teja sur 22	productos varios	2025-11-24 18:24:25.416803	2025-11-24 18:24:25.416803	3	+56930762616	f	2026-01-08	7	105	0	\N	\N	430.00	PKG-12649021714624	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
574	Beatriz O	\N	urmeneta 1	agua embotellada	2025-11-24 18:24:25.42256	2025-11-24 18:24:25.42256	3	+56930762617	f	2026-01-09	7	102	0	\N	\N	90.00	PKG-93435805346332	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
575	Froilán Z	\N	comandante 7	libro de estudio	2025-11-24 18:24:25.428055	2025-11-24 18:24:25.428055	3	+56930762618	f	2026-01-10	7	96	0	\N	\N	240.00	PKG-28905189215551	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
576	Denisse Q	\N	ramón 88	petición especial	2025-11-24 18:24:25.433551	2025-11-24 18:24:25.433551	3	+56930762619	f	2026-01-11	7	83	0	\N	\N	610.00	PKG-20813754001732	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
577	Alan V	\N	rio alto 3	insumo médico	2025-11-24 18:24:25.441484	2025-11-24 18:24:25.441484	3	+56930762620	f	2026-01-12	7	92	0	\N	\N	980.00	PKG-78179856422619	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
578	Olga M	\N	quinta 4	vestuario	2025-11-24 18:24:25.447005	2025-11-24 18:24:25.447005	3	+56930762621	f	2026-01-13	7	105	0	\N	\N	0.00	PKG-23669849196269	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
579	Bastián E	\N	canal 87	envío simple	2025-11-24 18:24:25.452482	2025-11-24 18:24:25.452482	3	+56930762622	f	2026-01-14	7	102	0	\N	\N	130.00	PKG-40775509602324	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
580	Ximena T	\N	canto 11	caja gigante	2025-11-24 18:24:25.458486	2025-11-24 18:24:25.458486	3	+56930762623	f	2026-01-15	7	100	0	\N	\N	540.00	PKG-01539811472985	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
581	César L	\N	alto sur 2	entrega express	2025-11-24 18:24:25.464247	2025-11-24 18:24:25.464247	3	+56930762624	f	2026-01-16	7	83	0	\N	\N	320.00	PKG-35386769091144	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
582	Florencia I	\N	patio 66	elemento frágil	2025-11-24 18:24:25.474059	2025-11-24 18:24:25.474059	3	+56930762625	f	2026-01-17	7	96	0	\N	\N	470.00	PKG-12420894557715	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
583	Jeremías F	\N	loma 17	pedido	2025-11-24 18:24:25.480357	2025-11-24 18:24:25.480357	3	+56930762626	f	2026-01-18	7	105	0	\N	\N	230.00	PKG-42871740155288	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
584	Carolina D	\N	los sauces 1	compra cliente	2025-11-24 18:24:25.486773	2025-11-24 18:24:25.486773	3	+56930762627	f	2026-01-19	7	102	0	\N	\N	160.00	PKG-04511072497380	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
585	Tomás G	\N	los acacios 9	pieza repuesto	2025-11-24 18:24:25.493352	2025-11-24 18:24:25.493352	3	+56930762628	f	2026-01-20	7	92	0	\N	\N	490.00	PKG-13801946249500	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
586	Romina H	\N	avenida 44	regalo sorpresa	2025-11-24 18:24:25.499861	2025-11-24 18:24:25.499861	3	+56930762629	f	2026-01-21	7	115	0	\N	\N	150.00	PKG-26443145487549	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
587	Gabriel C	\N	pedro II 8	objecto nuevo	2025-11-24 18:24:25.511764	2025-11-24 18:24:25.511764	3	+56930762630	f	2026-01-22	7	83	0	\N	\N	280.00	PKG-67904428539140	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
588	Fernanda P	\N	monte real 3	accesorio hogar	2025-11-24 18:24:25.519442	2025-11-24 18:24:25.519442	3	+56930762631	f	2026-01-23	7	96	0	\N	\N	330.00	PKG-92313576285038	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
589	Héctor M	\N	colón 81	producto digital	2025-11-24 18:24:25.527172	2025-11-24 18:24:25.527172	3	+56930762632	f	2026-01-24	7	105	0	\N	\N	525.00	PKG-47874166211645	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
590	Paola Y	\N	estrella 33	pañales	2025-11-24 18:24:25.534054	2025-11-24 18:24:25.534054	3	+56930762633	f	2026-01-25	7	102	0	\N	\N	0.00	PKG-88774397603146	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
591	Ángel A	\N	sol 100	alimento	2025-11-24 18:24:25.540353	2025-11-24 18:24:25.540353	3	+56930762634	f	2026-01-26	7	92	0	\N	\N	0.00	PKG-62926156372832	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
592	Yesenia L	\N	avenida 7	bebida	2025-11-24 18:24:25.548652	2025-11-24 18:24:25.548652	3	+56930762635	f	2026-01-27	7	100	0	\N	\N	0.00	PKG-60155929611275	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
593	Rafael O	\N	oro 55	solicitud general	2025-11-24 18:24:25.557588	2025-11-24 18:24:25.557588	3	+56930762636	f	2026-01-28	7	83	0	\N	\N	150.00	PKG-48643509350985	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
594	Valery R	\N	verde 44	producto gourmet	2025-11-24 18:24:25.565697	2025-11-24 18:24:25.565697	3	+56930762637	f	2026-01-29	7	105	0	\N	\N	740.00	PKG-45254125716750	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
595	Cristóbal T	\N	central 19	repuesto auto	2025-11-24 18:24:25.572255	2025-11-24 18:24:25.572255	3	+56930762638	f	2026-01-30	7	96	0	\N	\N	350.00	PKG-60524861746609	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
596	Lina J	\N	pedregal 11	insumo técnico	2025-11-24 18:24:25.578912	2025-11-24 18:24:25.578912	3	+56930762639	f	2026-01-31	7	102	0	\N	\N	275.00	PKG-82584073184298	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
597	Maximiliano B	\N	rio 90	accesorio gamer	2025-11-24 18:24:25.588304	2025-11-24 18:24:25.588304	3	+56930762640	f	2026-02-01	7	92	0	\N	\N	510.00	PKG-70164239368426	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
598	Pilar E	\N	lagos 82	objeto hogar	2025-11-24 18:24:25.594631	2025-11-24 18:24:25.594631	3	+56930762641	f	2026-02-02	7	83	0	\N	\N	200.00	PKG-73502217548854	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
599	Tadeo P	\N	costa azul 5	pedido interno	2025-11-24 18:24:25.601567	2025-11-24 18:24:25.601567	3	+56930762642	f	2026-02-03	7	105	0	\N	\N	330.00	PKG-45831352419576	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
600	Agustina L	\N	montaña 2	mueble pequeño	2025-11-24 18:24:25.608225	2025-11-24 18:24:25.608225	3	+56930762643	f	2026-02-04	7	96	0	\N	\N	780.00	PKG-22224379577512	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
601	Julián F	\N	avenida 5	pedido rápido	2025-11-24 18:24:25.615012	2025-11-24 18:24:25.615012	3	+56930762644	f	2026-02-05	7	102	0	\N	\N	120.00	PKG-28335121258990	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
602	Marta A	\N	luna 7	mercadería	2025-11-24 18:24:25.624495	2025-11-24 18:24:25.624495	3	+56930762645	f	2026-02-06	7	115	0	\N	\N	0.00	PKG-08168151653469	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
603	Leandro D	\N	avenida 15	ropa invierno	2025-11-24 18:24:25.631774	2025-11-24 18:24:25.631774	3	+56930762646	f	2026-02-07	7	100	0	\N	\N	290.00	PKG-13486319857237	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
604	Emilia G	\N	pasaje 8	perfume	2025-11-24 18:24:25.64081	2025-11-24 18:24:25.64081	3	+56930762647	f	2026-02-08	7	83	0	\N	\N	0.00	PKG-36481794811996	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
605	Benjamín C	\N	bosque 17	artículo cocina	2025-11-24 18:24:25.648308	2025-11-24 18:24:25.648308	3	+56930762648	f	2026-02-09	7	105	0	\N	\N	230.00	PKG-41402131662631	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
606	Inés H	\N	cerro 88	producto nuevo	2025-11-24 18:24:25.655112	2025-11-24 18:24:25.655112	3	+56930762649	f	2026-02-10	7	92	0	\N	\N	480.00	PKG-76456084402586	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
607	Alonso T	\N	rio largo 22	insumo técnico	2025-11-24 18:24:25.664371	2025-11-24 18:24:25.664371	3	+56930762650	f	2026-02-11	7	102	0	\N	\N	310.00	PKG-07800803040183	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
608	Constanza Y	\N	ruta 44	accesorio hogar	2025-11-24 18:24:25.672129	2025-11-24 18:24:25.672129	3	+56930762651	f	2026-02-12	7	115	0	\N	\N	160.00	PKG-34046070262748	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
609	Kevin M	\N	croacia 5	caja pequeña	2025-11-24 18:24:25.678771	2025-11-24 18:24:25.678771	3	+56930762652	f	2026-02-13	7	83	0	\N	\N	120.00	PKG-58510300936142	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
610	Aranza R	\N	loto 66	juguete	2025-11-24 18:24:25.685411	2025-11-24 18:24:25.685411	3	+56930762653	f	2026-02-14	7	96	0	\N	\N	0.00	PKG-16707250696529	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
611	Thiago S	\N	avenida 99	comida	2025-11-24 18:24:25.692192	2025-11-24 18:24:25.692192	3	+56930762654	f	2026-02-15	7	105	0	\N	\N	0.00	PKG-98154545410926	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
612	Juan José L	\N	faro 3	lámpara	2025-11-24 18:24:25.701374	2025-11-24 18:24:25.701374	3	+56930762655	f	2026-02-16	7	102	0	\N	\N	0.00	PKG-27122150994848	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
613	Fernanda C	\N	pedro 6	productos varios	2025-11-24 18:24:25.707701	2025-11-24 18:24:25.707701	3	+56930762656	f	2026-02-17	7	83	0	\N	\N	140.00	PKG-34386616648992	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
614	Elías U	\N	calle 10	notebook	2025-11-24 18:24:25.714724	2025-11-24 18:24:25.714724	3	+56930762657	f	2026-02-18	7	100	0	\N	\N	0.00	PKG-37971171818689	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
615	Trinidad M	\N	carmen 77	artículos bebés	2025-11-24 18:24:25.724644	2025-11-24 18:24:25.724644	3	+56930762658	f	2026-02-19	7	92	0	\N	\N	260.00	PKG-29568989214328	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
616	Alfredo Z	\N	subida 4	implementos	2025-11-24 18:24:25.732265	2025-11-24 18:24:25.732265	3	+56930762659	f	2026-02-20	7	96	0	\N	\N	0.00	PKG-86446855792675	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
617	Romina B	\N	rosales 11	accesorio auto	2025-11-24 18:24:25.742587	2025-11-24 18:24:25.742587	3	+56930762660	f	2026-02-21	7	105	0	\N	\N	180.00	PKG-27443461535810	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
618	Sherly V	\N	rio gris 2	té especial	2025-11-24 18:24:25.748943	2025-11-24 18:24:25.748943	3	+56930762661	f	2026-02-22	7	83	0	\N	\N	0.00	PKG-73684999186590	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
619	Leonardo H	\N	lira 44	servicio técnico	2025-11-24 18:24:25.754887	2025-11-24 18:24:25.754887	3	+56930762662	f	2026-02-23	7	102	0	\N	\N	520.00	PKG-46201759902435	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
620	Amparo J	\N	pedro 19	taza cerámica	2025-11-24 18:24:25.761015	2025-11-24 18:24:25.761015	3	+56930762663	f	2026-02-24	7	100	0	\N	\N	110.00	PKG-07098755049123	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
621	Elvira P	\N	rio profundo 1	insumos limpeza	2025-11-24 18:24:25.766885	2025-11-24 18:24:25.766885	3	+56930762664	f	2026-02-25	7	115	0	\N	\N	140.00	PKG-99611673956414	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
622	Oliver Y	\N	avenida 121	material oficina	2025-11-24 18:24:25.775804	2025-11-24 18:24:25.775804	3	+56930762665	f	2026-02-26	7	83	0	\N	\N	260.00	PKG-51646559264431	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
623	Selena A	\N	los cedros 3	plato vidrio	2025-11-24 18:24:25.782312	2025-11-24 18:24:25.782312	3	+56930762666	f	2026-02-27	7	92	0	\N	\N	130.00	PKG-93614646998910	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
624	Eduardo T	\N	ulmo 17	producto premium	2025-11-24 18:24:25.788104	2025-11-24 18:24:25.788104	3	+56930762667	f	2026-02-28	7	105	0	\N	\N	870.00	PKG-47837286245209	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
625	Rocío E	\N	lago azul 8	regalo especial	2025-11-24 18:24:25.794742	2025-11-24 18:24:25.794742	3	+56930762668	f	2026-03-01	7	96	0	\N	\N	190.00	PKG-72711774553252	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
626	Mario R	\N	arbustos 7	audífonos	2025-11-24 18:24:25.801906	2025-11-24 18:24:25.801906	3	+56930762669	f	2026-03-02	7	102	0	\N	\N	0.00	PKG-65694565231311	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
627	Juan Pérez	\N	Av. Providencia 123	Paquete con ropa	2025-11-24 18:51:20.766435	2025-11-24 18:51:20.766435	3	+56912345678	f	2025-12-15	7	105	0	\N	\N	15000.00	PKG-56931293138506	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
628	María González	\N	Los Leones 456	Electrónicos	2025-11-24 18:51:20.779037	2025-11-24 18:51:20.779037	3	+56987654321	t	2025-12-16	7	96	0	\N	\N	25000.00	PKG-49661711428425	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
629	Pedro Ramírez	\N	Santa Rosa 789	Libros	2025-11-24 18:51:20.789621	2025-11-24 18:51:20.789621	3	+56956781234	f	2025-12-17	7	92	0	\N	\N	8000.00	PKG-24427888385424	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
630	Juan Pérez	customer1@example.com	Av. Providencia 123	Paquete con ropa	2025-11-24 19:48:07.024512	2025-11-24 19:48:07.024512	2	+56912345678	f	2025-11-25	7	105	0	\N	\N	15000.00	PKG-24088760039898	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
631	Pedro Ramírez	customer3@example.com	Santa Rosa 789	Libros	2025-11-24 19:48:07.041527	2025-11-24 19:48:07.041527	4	+56956781234	f	2025-12-17	7	92	0	\N	\N	8000.00	PKG-66157952637551	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
632	Juan Pérez	customer1@example.com	Av. Providencia 123	Paquete con ropa	2025-11-24 19:50:20.835397	2025-11-24 19:50:20.835397	2	+56912345678	f	2025-11-25	7	105	0	\N	\N	15000.00	PKG-30415086123018	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
633	Pedro Ramírez	customer3@example.com	Santa Rosa 789	Libros	2025-11-24 19:50:20.851312	2025-11-24 19:50:20.851312	4	+56956781234	f	2025-12-17	7	92	0	\N	\N	8000.00	PKG-34211984587453	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
634	Juan Pérez	customer1@example.com	Av. Providencia 123	Paquete con ropa	2025-11-24 19:59:33.276167	2025-11-24 19:59:33.276167	2	+56912345678	f	2025-11-25	7	105	0	\N	\N	15000.00	PKG-28466597680985	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
635	Pedro Ramírez	customer3@example.com	Santa Rosa 789	Libros	2025-11-24 19:59:33.295074	2025-11-24 19:59:33.295074	4	+56956781234	f	2025-12-17	7	92	0	\N	\N	8000.00	PKG-29988478714532	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
636	Juan Pérez	customer1@example.com	Av. Providencia 123	Paquete con ropa	2025-11-24 20:05:28.458196	2025-11-24 20:05:28.458196	2	+56912345678	f	2025-11-25	7	105	0	\N	\N	15000.00	PKG-64239745512418	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
637	María González	luzmdiaz20231@gmail.com	Los Leones 456	Electrónicos	2025-11-24 20:05:28.467496	2025-11-24 20:05:28.467496	9	+56987654321	t	2025-11-26	7	96	0	\N	\N	25000.00	PKG-70891014361712	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
638	Pedro Ramírez	customer3@example.com	Santa Rosa 789	Libros	2025-11-24 20:05:28.476065	2025-11-24 20:05:28.476065	4	+56956781234	f	2025-12-17	7	92	0	\N	\N	8000.00	PKG-40812258216277	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	\N
639	Juan Pérez	customer1@example.com	Av. Providencia 123	Paquete con ropa	2025-11-25 03:21:46.043692	2025-11-25 03:21:46.043692	2	+56912345678	f	2025-11-25	7	105	0	\N	\N	15000.00	PKG-29744515636541	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	30
640	María González	luzmdiaz20231@gmail.com	Los Leones 456	Electrónicos	2025-11-25 03:21:46.051613	2025-11-25 03:21:46.051613	9	+56987654321	t	2025-11-26	7	96	0	\N	\N	25000.00	PKG-57959138905025	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	30
641	Pedro Ramírez	luzmdiaz20231@gmail.com	Santa Rosa 789	Libros	2025-11-25 03:21:46.063886	2025-11-25 03:21:46.063886	9	+56956781234	f	2025-12-17	7	92	0	\N	\N	8000.00	PKG-46146573868168	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	30
642	Juan Pérez	customer1@example.com	Av. Providencia 123	Paquete con ropa	2025-11-25 03:35:24.212694	2025-11-25 03:35:24.212694	2	+56912345678	f	2025-11-25	7	105	0	\N	\N	15000.00	PKG-09019892577782	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	31
643	María González	luzmdiaz20231@gmail.com	Los Leones 456	Electrónicos	2025-11-25 03:35:24.221978	2025-11-25 03:35:24.221978	9	+56987654321	t	2025-11-26	7	96	0	\N	\N	25000.00	PKG-89568261006237	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	31
644	Pedro Ramírez	luzmdiaz20231@gmail.com	Santa Rosa 789	Libros	2025-11-25 03:35:24.229184	2025-11-25 03:35:24.229184	9	+56956781234	f	2025-12-17	7	92	0	\N	\N	8000.00	PKG-42265771237064	\N	[]	\N	0	\N	\N	\N	\N	\N	\N	\N	f	31
\.


--
-- Data for Name: regions; Type: TABLE DATA; Schema: public; Owner: omen
--

COPY public.regions (id, name, created_at, updated_at) FROM stdin;
1	Región de Arica y Parinacota	2025-11-21 14:34:36.73331	2025-11-21 14:34:36.73331
2	Región de Tarapacá	2025-11-21 14:34:36.764541	2025-11-21 14:34:36.764541
3	Región de Antofagasta	2025-11-21 14:34:36.801916	2025-11-21 14:34:36.801916
4	Región de Atacama	2025-11-21 14:34:36.846036	2025-11-21 14:34:36.846036
5	Región de Coquimbo	2025-11-21 14:34:36.890468	2025-11-21 14:34:36.890468
6	Región de Valparaíso	2025-11-21 14:34:36.96199	2025-11-21 14:34:36.96199
7	Región Metropolitana	2025-11-21 14:34:37.133859	2025-11-21 14:34:37.133859
8	Región de O'Higgins	2025-11-21 14:34:37.348769	2025-11-21 14:34:37.348769
9	Región del Maule	2025-11-21 14:34:37.489231	2025-11-21 14:34:37.489231
10	Región de Ñuble	2025-11-21 14:34:37.613496	2025-11-21 14:34:37.613496
11	Región del Biobío	2025-11-21 14:34:37.701814	2025-11-21 14:34:37.701814
12	Región de La Araucanía	2025-11-21 14:34:37.84464	2025-11-21 14:34:37.84464
13	Región de Los Ríos	2025-11-21 14:34:37.986197	2025-11-21 14:34:37.986197
14	Región de Los Lagos	2025-11-21 14:34:38.044432	2025-11-21 14:34:38.044432
15	Región de Aysén	2025-11-21 14:34:38.179579	2025-11-21 14:34:38.179579
16	Región de Magallanes	2025-11-21 14:34:38.229824	2025-11-21 14:34:38.229824
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: omen
--

COPY public.schema_migrations (version) FROM stdin;
20251121112800
20251121022546
20251121020239
20251121015351
20251120213212
20251120205107
20251120160755
20251120042958
20251120033201
20251118010644
20251118002726
20251117233308
20251117041426
20251114142716
20251114142703
20251114142652
20251114135931
20251113182332
20251113163448
20251113163436
20251113163244
20251121184311
20251124173812
20251125031149
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: omen
--

COPY public.users (id, email, encrypted_password, reset_password_token, reset_password_sent_at, remember_created_at, created_at, updated_at, admin, role, show_logo_on_labels, rut, phone, company, active, delivery_charge) FROM stdin;
1	admin@paqueteria.com	$2a$12$8Nu1ew0m7V4Iz4KJPJnPbO9tDd..xOTw2P1KfRhrKk1ri.lderlm6	\N	\N	\N	2025-11-21 14:34:38.474042	2025-11-21 14:34:38.474042	t	0	t	11.111.111-1	+56900000000	Administración	t	0.00
2	customer1@example.com	$2a$12$Nc5/WmFIrcPujW1f9ib1Q.nH1KXz0sFL/IPJM.PZ0vf.mjVzwfmPe	\N	\N	\N	2025-11-21 14:34:38.650027	2025-11-21 14:34:38.650027	f	1	t	12.345.678-9	+56987654321	Empresa ABC S.A.	t	5000.00
4	customer3@example.com	$2a$12$0YzugYKIfUr6K3KI.ykIk.Hxs5KaGVMVopWBN3x84.P9KqtStuyem	\N	\N	\N	2025-11-21 14:34:39.000693	2025-11-21 14:34:39.000693	f	1	t	34.567.890-1	+56998765432	Logística 123 SpA	t	6000.00
5	inactive@example.com	$2a$12$/Ks7WHkjnmtjdYOGoMxrxOgCJgm.JRg.P..1qXPihmbfyKHbCywTm	\N	\N	\N	2025-11-21 14:34:39.175666	2025-11-21 14:34:39.175666	f	1	t	45.678.901-2	+56911112222	Empresa Inactiva S.A.	f	3000.00
6	driver1@example.com	$2a$12$lcyMPWWs3pQFvNYltmp12u4iTQosOrOIGTaYrAKpoe7.tpROn3epa	\N	\N	\N	2025-11-21 14:34:39.35355	2025-11-21 14:34:39.35355	f	2	t	56.789.012-3	+56922223333	\N	t	0.00
7	driver2@example.com	$2a$12$3ADzY2TaVXnMgWQp6iBp7evoZh5X7oJXOFUeSrbm.Q92akc9SGBiq	\N	\N	\N	2025-11-21 14:34:39.528598	2025-11-21 14:34:39.528598	f	2	t	67.890.123-4	+56933334444	\N	t	0.00
3	customer2@example.com	$2a$12$AvCzobBGQ54w.L9XJcbCr.6jxNj4Y0khC4i4CR/y8J8IfxkAeRk3y	\N	\N	\N	2025-11-21 14:34:38.824761	2025-11-21 16:01:04.198868	f	1	t	23.456.789-0	+56912345678	Comercial XYZ Ltda.	t	4500.00
9	luzmdiaz20231@gmail.com	$2a$12$sxxfZ/8mOM0fGZOmc2P0/OfSS0o5mFOYjkJaPWfDQmkj.7KlcIDiy	\N	\N	\N	2025-11-21 15:11:23.869277	2025-11-21 19:38:33.406335	f	1	t	12.345.678-k	+56930762570	Fospuca	t	1000.00
8	johkcolom@gmail.com	$2a$12$2MTQOQCcIQMuDn4YXKr4feymrhsfFhCB5vDHwmPYf2C31CUmDH5Pq	\N	\N	\N	2025-11-21 15:05:07.829218	2025-11-25 03:37:47.257621	f	2	t	45.678.901-8	+56930762570	\N	t	0.00
\.


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: omen
--

SELECT pg_catalog.setval('public.active_storage_attachments_id_seq', 33, true);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: omen
--

SELECT pg_catalog.setval('public.active_storage_blobs_id_seq', 33, true);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE SET; Schema: public; Owner: omen
--

SELECT pg_catalog.setval('public.active_storage_variant_records_id_seq', 1, false);


--
-- Name: bulk_uploads_id_seq; Type: SEQUENCE SET; Schema: public; Owner: omen
--

SELECT pg_catalog.setval('public.bulk_uploads_id_seq', 31, true);


--
-- Name: communes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: omen
--

SELECT pg_catalog.setval('public.communes_id_seq', 347, true);


--
-- Name: packages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: omen
--

SELECT pg_catalog.setval('public.packages_id_seq', 644, true);


--
-- Name: regions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: omen
--

SELECT pg_catalog.setval('public.regions_id_seq', 16, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: omen
--

SELECT pg_catalog.setval('public.users_id_seq', 9, true);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: omen
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: omen
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: omen
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: omen
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: bulk_uploads bulk_uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: omen
--

ALTER TABLE ONLY public.bulk_uploads
    ADD CONSTRAINT bulk_uploads_pkey PRIMARY KEY (id);


--
-- Name: communes communes_pkey; Type: CONSTRAINT; Schema: public; Owner: omen
--

ALTER TABLE ONLY public.communes
    ADD CONSTRAINT communes_pkey PRIMARY KEY (id);


--
-- Name: packages packages_pkey; Type: CONSTRAINT; Schema: public; Owner: omen
--

ALTER TABLE ONLY public.packages
    ADD CONSTRAINT packages_pkey PRIMARY KEY (id);


--
-- Name: regions regions_pkey; Type: CONSTRAINT; Schema: public; Owner: omen
--

ALTER TABLE ONLY public.regions
    ADD CONSTRAINT regions_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: omen
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: omen
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: omen
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: omen
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: omen
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: omen
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_bulk_uploads_on_created_at; Type: INDEX; Schema: public; Owner: omen
--

CREATE INDEX index_bulk_uploads_on_created_at ON public.bulk_uploads USING btree (created_at);


--
-- Name: index_bulk_uploads_on_status; Type: INDEX; Schema: public; Owner: omen
--

CREATE INDEX index_bulk_uploads_on_status ON public.bulk_uploads USING btree (status);


--
-- Name: index_bulk_uploads_on_user_id; Type: INDEX; Schema: public; Owner: omen
--

CREATE INDEX index_bulk_uploads_on_user_id ON public.bulk_uploads USING btree (user_id);


--
-- Name: index_communes_on_name; Type: INDEX; Schema: public; Owner: omen
--

CREATE INDEX index_communes_on_name ON public.communes USING btree (name);


--
-- Name: index_communes_on_region_id; Type: INDEX; Schema: public; Owner: omen
--

CREATE INDEX index_communes_on_region_id ON public.communes USING btree (region_id);


--
-- Name: index_communes_on_region_id_and_name; Type: INDEX; Schema: public; Owner: omen
--

CREATE UNIQUE INDEX index_communes_on_region_id_and_name ON public.communes USING btree (region_id, name);


--
-- Name: index_packages_on_assigned_courier_id; Type: INDEX; Schema: public; Owner: omen
--

CREATE INDEX index_packages_on_assigned_courier_id ON public.packages USING btree (assigned_courier_id);


--
-- Name: index_packages_on_bulk_upload_id; Type: INDEX; Schema: public; Owner: omen
--

CREATE INDEX index_packages_on_bulk_upload_id ON public.packages USING btree (bulk_upload_id);


--
-- Name: index_packages_on_commune_id; Type: INDEX; Schema: public; Owner: omen
--

CREATE INDEX index_packages_on_commune_id ON public.packages USING btree (commune_id);


--
-- Name: index_packages_on_created_at; Type: INDEX; Schema: public; Owner: omen
--

CREATE INDEX index_packages_on_created_at ON public.packages USING btree (created_at);


--
-- Name: index_packages_on_exchange; Type: INDEX; Schema: public; Owner: omen
--

CREATE INDEX index_packages_on_exchange ON public.packages USING btree (exchange);


--
-- Name: index_packages_on_loading_date; Type: INDEX; Schema: public; Owner: omen
--

CREATE INDEX index_packages_on_loading_date ON public.packages USING btree (loading_date);


--
-- Name: index_packages_on_region_and_commune; Type: INDEX; Schema: public; Owner: omen
--

CREATE INDEX index_packages_on_region_and_commune ON public.packages USING btree (region_id, commune_id);


--
-- Name: index_packages_on_region_id; Type: INDEX; Schema: public; Owner: omen
--

CREATE INDEX index_packages_on_region_id ON public.packages USING btree (region_id);


--
-- Name: index_packages_on_status; Type: INDEX; Schema: public; Owner: omen
--

CREATE INDEX index_packages_on_status ON public.packages USING btree (status);


--
-- Name: index_packages_on_status_and_assigned_courier_id; Type: INDEX; Schema: public; Owner: omen
--

CREATE INDEX index_packages_on_status_and_assigned_courier_id ON public.packages USING btree (status, assigned_courier_id);


--
-- Name: index_packages_on_status_and_loading_date; Type: INDEX; Schema: public; Owner: omen
--

CREATE INDEX index_packages_on_status_and_loading_date ON public.packages USING btree (status, loading_date);


--
-- Name: index_packages_on_tracking_code; Type: INDEX; Schema: public; Owner: omen
--

CREATE UNIQUE INDEX index_packages_on_tracking_code ON public.packages USING btree (tracking_code);


--
-- Name: index_packages_on_user_id; Type: INDEX; Schema: public; Owner: omen
--

CREATE INDEX index_packages_on_user_id ON public.packages USING btree (user_id);


--
-- Name: index_packages_on_user_id_and_status; Type: INDEX; Schema: public; Owner: omen
--

CREATE INDEX index_packages_on_user_id_and_status ON public.packages USING btree (user_id, status);


--
-- Name: index_regions_on_name; Type: INDEX; Schema: public; Owner: omen
--

CREATE UNIQUE INDEX index_regions_on_name ON public.regions USING btree (name);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: omen
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_phone; Type: INDEX; Schema: public; Owner: omen
--

CREATE INDEX index_users_on_phone ON public.users USING btree (phone);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: omen
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_role; Type: INDEX; Schema: public; Owner: omen
--

CREATE INDEX index_users_on_role ON public.users USING btree (role);


--
-- Name: index_users_on_role_and_active; Type: INDEX; Schema: public; Owner: omen
--

CREATE INDEX index_users_on_role_and_active ON public.users USING btree (role, active);


--
-- Name: index_users_on_rut; Type: INDEX; Schema: public; Owner: omen
--

CREATE UNIQUE INDEX index_users_on_rut ON public.users USING btree (rut) WHERE (rut IS NOT NULL);


--
-- Name: packages fk_rails_5d67383791; Type: FK CONSTRAINT; Schema: public; Owner: omen
--

ALTER TABLE ONLY public.packages
    ADD CONSTRAINT fk_rails_5d67383791 FOREIGN KEY (region_id) REFERENCES public.regions(id);


--
-- Name: bulk_uploads fk_rails_68d991ee6f; Type: FK CONSTRAINT; Schema: public; Owner: omen
--

ALTER TABLE ONLY public.bulk_uploads
    ADD CONSTRAINT fk_rails_68d991ee6f FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: omen
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: communes fk_rails_9f434ab280; Type: FK CONSTRAINT; Schema: public; Owner: omen
--

ALTER TABLE ONLY public.communes
    ADD CONSTRAINT fk_rails_9f434ab280 FOREIGN KEY (region_id) REFERENCES public.regions(id);


--
-- Name: packages fk_rails_bb26f220aa; Type: FK CONSTRAINT; Schema: public; Owner: omen
--

ALTER TABLE ONLY public.packages
    ADD CONSTRAINT fk_rails_bb26f220aa FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: omen
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: packages fk_rails_df4e66461e; Type: FK CONSTRAINT; Schema: public; Owner: omen
--

ALTER TABLE ONLY public.packages
    ADD CONSTRAINT fk_rails_df4e66461e FOREIGN KEY (bulk_upload_id) REFERENCES public.bulk_uploads(id);


--
-- Name: packages fk_rails_e7a8b8d357; Type: FK CONSTRAINT; Schema: public; Owner: omen
--

ALTER TABLE ONLY public.packages
    ADD CONSTRAINT fk_rails_e7a8b8d357 FOREIGN KEY (commune_id) REFERENCES public.communes(id);


--
-- Name: packages fk_rails_f4740280c9; Type: FK CONSTRAINT; Schema: public; Owner: omen
--

ALTER TABLE ONLY public.packages
    ADD CONSTRAINT fk_rails_f4740280c9 FOREIGN KEY (assigned_courier_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

\unrestrict 1bt34ivBgLlbyaHkQdk405DhLTRIUBAHtciqcB07fchlAelsrgS0i1sCjg8pMOC

