create table categories (
	id integer,
	name text
);

create table db_meta(
        id integer,
        name text,
        version integer,
	created timestamp,
	modified timestamp,
	backup timestamp,
	modnum integer,
	type text,
	creator text,

        resdb bool,
	readonly bool,
	appinfodirty bool,
	backup bool,
	oktoinstallnewer bool,
	resetafterinstall bool,
	copyprevention bool,
	stream bool,
	hidden bool,
	launchabledata bool,
	recyclable bool,
	bundle bool,
	opendb bool
        );

create table record_attribute (id integer,
	busy bool,
	del bool,
	secret bool,
	dirty bool);

