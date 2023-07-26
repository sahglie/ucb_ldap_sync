CREATE TABLE org_data.org_units_history
(
    id             uuid        not nulL primary key default public.uuid_generate_v4(),
    item_type      varchar     not nulL,
    item_id        varchar     not nulL,
    event          varchar     not NULl,
    whodunnit      varchar,
    object         jsonb,
    object_changes jsonb,
    created_at     timestamptz not null
);

create index on org_data.org_units_history (item_type, item_id);
