create table org_data.ucb_people
(
    id                   UUID        NOT NULL PRIMARY KEY DEFAULT public.uuid_generate_v4(),
    calnet_uid           bigint      not null,
    kerberos_principal   varchar,
    first_name           varchar,
    last_name            varchar,
    display_name         varchar,
    email                varchar,
    official_email       varchar,
    ou                   varchar,
    org                  varchar,
    affiliations         varchar[]   not null             default '{}',
    affiliations_summary json        not null             default '{}',
    dn                   varchar     not null,
    expired_ts           timestamptz,
    created_at           timestamptz not null,
    updated_at           timestamptz not null,

    UNIQUE (calnet_uid)

);

create index on org_data.ucb_people (calnet_uid);
create index on org_data.ucb_people (kerberos_principal);
create index on org_data.ucb_people (first_name);
create index on org_data.ucb_people (last_name);
create index on org_data.ucb_people (email);
create index on org_data.ucb_people (official_email);
create index on org_data.ucb_people (ou);
create index on org_data.ucb_people (org);



