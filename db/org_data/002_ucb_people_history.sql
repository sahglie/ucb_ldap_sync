CREATE TABLE org_data.ucb_people_history
(
    id             UUID                     NOT NULL PRIMARY KEY DEFAULT public.uuid_generate_v4(),
    item_type      VARCHAR                  NOT NULL,
    item_id        UUID                     NOT NULL,
    event          VARCHAR                  NOT NULL,
    whodunnit      VARCHAR,
    object         JSONB,
    object_changes JSONB,
    created_at     TIMESTAMP WITH TIME ZONE NOT NULL
);

create index on org_data.ucb_people_history (item_type, item_id);
