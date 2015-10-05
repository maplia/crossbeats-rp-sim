create table if not exists `_musics` (
		`id` int(4) not null auto_increment
	, `text_id` varchar(64) not null
	, `number` int(4) not null
	, `lookup_key` varchar(128)
	, `title` varchar(128) not null
	, `subtitle` varchar(128)
	, `sort_key` varchar(128)
	, `esy_level` float
	, `esy_notes` int(4)
	, `std_level` float
	, `std_notes` int(4)
	, `hrd_level` float
	, `hrd_notes` int(4)
	, `mas_level` float
	, `mas_notes` int(4)
	, `unl_level` float
	, `unl_notes` int(4)
	, `limited` int(1) not null default 0
	, `display` int(1) not null default 1
	, `created_at` datetime default null
	, `updated_at` datetime default null
	, primary key (`id`)
	, unique key `text_id` (`text_id`)
	, unique key `sort_key` (`sort_key`)
	, unique key `lookup_key` (`lookup_key`)
) default charset=utf8;

create table if not exists `rptargets` (
	   `id` int(4) not null auto_increment
	 , `music_id` int(4) not null
	 , `span_s` datetime not null
	 , `span_e` datetime not null
	 , `created_at` datetime default null
	 , `updated_at` datetime default null
	 , primary key (`id`)
	 , unique key `music` (`music_id`, `span_s`)
) default charset=utf8;

create or replace view `musics` as
select `_musics`.`id` as `id`
	, `_musics`.`text_id` as `text_id`
	, `_musics`.`number` as `number`
	, `_musics`.`lookup_key` as `lookup_key`
	, `_musics`.`title` as `title`
	, `_musics`.`subtitle` as `subtitle`
	, `_musics`.`sort_key` as `sort_key`
	, `_musics`.`esy_level` as `esy_level`
	, `_musics`.`esy_notes` as `esy_notes`
	, `_musics`.`std_level` as `std_level`
	, `_musics`.`std_notes` as `std_notes`
	, `_musics`.`hrd_level` as `hrd_level`
	, `_musics`.`hrd_notes` as `hrd_notes`
	, `_musics`.`mas_level` as `mas_level`
	, `_musics`.`mas_notes` as `mas_notes`
	, `_musics`.`unl_level` as `unl_level`
	, `_musics`.`unl_notes` as `unl_notes`
	, (case when exists (select 1
							 from `rptargets`
							where `_musics`.`id` = `rptargets`.`music_id`
								and `rptargets`.`span_s` <= now()
								and `rptargets`.`span_e` > now()) then 1 else 0 end) as `monthly`
	, `_musics`.`limited` as `limited`
	, `_musics`.`created_at` as `created_at`
	, `_musics`.`updated_at` as `updated_at`
  from `_musics`
 where `_musics`.`display` = 1;

create table if not exists `courses` (
	  `id` int(4) not null auto_increment
	, `text_id` varchar(64) not null
	, `lookup_key` varchar(128)
	, `name` varchar(64) not null
	, `sort_key` varchar(64) not null
	, `level` float not null
	, `created_at` datetime default null
	, `updated_at` datetime default null
	, primary key (`id`)
	, unique key `text_id` (`text_id`)
	, unique key `lookup_key` (`lookup_key`)
) default charset=utf8;

create table if not exists `course_musics` (
	  `id` int(4) not null auto_increment
	, `course_id` int(4) not null
	, `seq` int(1) not null
	, `music_id` int(4) not null
	, `diff` int(1) not null
	, `created_at` datetime default null
	, `updated_at` datetime default null
	, primary key (`id`)
	, unique key `music` (`course_id`, `seq`)
) default charset=utf8;

create table if not exists `users` (
	  `id` int(4) not null auto_increment
	, `name` varchar(64) not null
	, `password` varchar(64) not null
	, `game_id` varchar(16)
	, `game_id_display` int default 0
	, `comment` text
	, `point` float default 0
	, `point_updated_at` datetime default null
	, `display` int(1) default 1
	, `created_at` datetime default null
	, `updated_at` datetime default null
	, primary key (`id`)
) default charset=utf8;

create table if not exists `skills` (
	  `id` int(4) not null auto_increment
	, `user_id` int(4) not null
	, `music_id` int(4) not null
	, `esy_stat` int(1) default 0
	, `esy_locked` int(1) default 0
	, `esy_gauge` int(1) default 0
	, `esy_point` float
	, `esy_rate` float
	, `esy_rank` int(2) default 0
	, `esy_combo` int(2) default 0
	, `std_stat` int(1) default 0
	, `std_locked` int(1) default 0
	, `std_gauge` int(1) default 0
	, `std_point` float
	, `std_rate` float
	, `std_rank` int(2) default 0
	, `std_combo` int(2) default 0
	, `hrd_stat` int(1) default 0
	, `hrd_locked` int(1) default 0
	, `hrd_gauge` int(1) default 0
	, `hrd_point` float
	, `hrd_rate` float
	, `hrd_rank` int(2) default 0
	, `hrd_combo` int(2) default 0
	, `mas_stat` int(1) default 0
	, `mas_locked` int(1) default 0
	, `mas_gauge` int(1) default 0
	, `mas_point` float
	, `mas_rate` float
	, `mas_rank` int(2) default 0
	, `mas_combo` int(2) default 0
	, `unl_stat` int(1) default 0
	, `unl_locked` int(1) default 0
	, `unl_gauge` int(1) default 0
	, `unl_point` float
	, `unl_rate` float
	, `unl_rank` int(2) default 0
	, `unl_combo` int(2) default 0
	, `comment` varchar(128)
	, `best_diff` int(1) default null
	, `best_point` float default null
	, `iglock_best_diff` int(1) default null
	, `iglock_best_point` float default null
	, `created_at` datetime default null
	, `updated_at` datetime default null
	, primary key (`id`)
	, unique key `skill` (`user_id`, `music_id`)
) default charset=utf8;

create table if not exists `course_skills` (
	  `id` int(4) not null auto_increment
	, `user_id` int(4) not null
	, `course_id` int(4) not null
	, `stat` int(1) not null default 0
	, `point` float
	, `rate` float
	, `combo` int(2) default 0
	, `comment` varchar(128)
	, `created_at` datetime default null
	, `updated_at` datetime default null
	, primary key (`id`)
	, unique key `skill` (`user_id`, `course_id`)
) default charset=utf8;

create table if not exists `events` (
	  `id` int(4) not null auto_increment
	, `text_id` varchar(64) not null
	, `section` int(1) default 0
	, `title` varchar(64) not null
	, `start_date` datetime not null
	, `end_date` datetime not null 
	, `created_at` datetime default null
	, `updated_at` datetime default null
	, primary key (`id`)
	, unique key `music` (`text_id`, `section`)
) default charset=utf8;

create table if not exists `event_musics` (
	  `id` int(4) not null auto_increment
	, `event_id` int(4) not null
	, `seq` int(2) not null
	, `music_id` int(4) not null
	, `created_at` datetime default null
	, `updated_at` datetime default null
	, primary key (`id`)
	, unique key `music` (`event_id`, `seq`, `music_id`)
) default charset=utf8;
