-- An activity can be marked done, after operation and before the off-track states.
begin;
update ai_management.module_registry
set statuses=array['Đề xuất','Đang trao đổi','POC','Triển khai chính thức','Pilot','Vận hành','Hoàn thành','Tạm dừng','Dừng']
where kind='collaboration';
commit;
