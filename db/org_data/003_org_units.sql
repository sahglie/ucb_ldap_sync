create table org_data.org_units
(
    code       varchar      not null primary key,
    name       varchar      not null,
    hierarchy  public.ltree not null,
    level      integer      not null,
    dn         varchar,
    expired_ts timestamptz,
    created_at timestamptz  not null,
    updated_at timestamptz  not null
);
