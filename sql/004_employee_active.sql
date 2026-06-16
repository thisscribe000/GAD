alter table employees add column is_active boolean not null default true;

create index idx_employees_active on employees(is_active);
