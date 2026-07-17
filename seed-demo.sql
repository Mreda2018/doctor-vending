-- ============================================================
-- DOCTOR VENDING — DEMO DATA
-- Run this AFTER schema.sql, in Supabase → SQL Editor → Run.
-- Safe to run once. It will skip itself if products already exist.
-- To reset later: TRUNCATE the tables (or drop & re-run schema.sql), then run this again.
--   Expiry dates are relative to "today", so the expiry alerts always look right.
-- ============================================================

-- FEFO refill helper (same logic as the app): consumes earliest-expiry batches,
-- records the exact allocation, and stores the weighted-average cost.
create or replace function pg_temp.refill_line(p_issue uuid, p_prod uuid, p_loc uuid, p_qty numeric, p_price numeric)
returns void language plpgsql as $f$
declare
  need numeric := p_qty; take numeric; b record;
  total_cost numeric := 0; alloc jsonb := '[]'::jsonb;
begin
  for b in select id, qty_remaining, unit_cost from batches
           where product_id = p_prod and location_id = p_loc and qty_remaining > 0
           order by coalesce(expiry_date,'9999-12-31'), created_at loop
    exit when need <= 0;
    take := least(need, b.qty_remaining);
    update batches set qty_remaining = qty_remaining - take where id = b.id;
    total_cost := total_cost + take * b.unit_cost;
    alloc := alloc || jsonb_build_object('b', b.id, 'q', take);
    need := need - take;
  end loop;
  if need > 0 then raise exception 'demo: not enough stock for product %', p_prod; end if;
  insert into issue_items(issue_id, product_id, qty, unit_cost, unit_price, alloc)
  values (p_issue, p_prod, p_qty, round(total_cost / p_qty, 4), p_price, alloc);
end;
$f$;

do $$
declare
  l_dxb uuid; l_uaq uuid; l_auh uuid;
  c_cof uuid; c_snk uuid; c_cho uuid; c_wat uuid; c_cup uuid;
  s_snk uuid; s_bev uuid; s_cof uuid; s_pak uuid;
  e_mah uuid; e_you uuid; e_kar uuid; e_omr uuid;
  m1 uuid; m2 uuid; m3 uuid; m4 uuid; m5 uuid; m6 uuid;
  p_bean uuid; p_cup uuid; p_lay uuid; p_dor uuid; p_pri uuid;
  p_kit uuid; p_sni uuid; p_gal uuid; p_wat uuid; p_pep uuid; p_rb uuid; p_oj uuid;
  pur uuid; iss uuid; trf uuid; bwat uuid; bcost numeric; bexp date;
begin
  if (select count(*) from products) > 0 then
    raise notice 'Products already exist — demo data skipped.';
    return;
  end if;

  select id into l_dxb from locations where name='Dubai Warehouse';
  select id into l_uaq from locations where name='Umm Al Quwain Warehouse';
  select id into l_auh from locations where name='Abu Dhabi Warehouse';
  select id into c_cof from categories where name='Coffee Beans';
  select id into c_snk from categories where name='Snacks & Chips';
  select id into c_cho from categories where name='Chocolate';
  select id into c_wat from categories where name='Water & Drinks';
  select id into c_cup from categories where name='Cups & Consumables';

  -- Suppliers
  insert into suppliers(name,contact_person,phone,email) values
    ('Gulf Snacks Distribution','Ahmed Saeed','+971 50 111 2233','sales@gulfsnacks.ae') returning id into s_snk;
  insert into suppliers(name,contact_person,phone,email) values
    ('Emirates Beverage Co','Sara Khalil','+971 52 444 5566','orders@emiratesbev.ae') returning id into s_bev;
  insert into suppliers(name,contact_person,phone,email) values
    ('Roastery Bros Coffee','Khaled Nasser','+971 55 777 8899','hello@roasterybros.ae') returning id into s_cof;
  insert into suppliers(name,contact_person,phone,email) values
    ('Packaging Plus LLC','Mona Adib','+971 56 222 3344','info@packplus.ae') returning id into s_pak;

  -- Employees
  insert into employees(name,phone,role) values ('Mahmoud Adel','+971 50 900 1122','Route Driver') returning id into e_mah;
  insert into employees(name,phone,role) values ('Youssef Hassan','+971 50 900 3344','Route Driver') returning id into e_you;
  insert into employees(name,phone,role) values ('Karim Nabil','+971 50 900 5566','Technician') returning id into e_kar;
  insert into employees(name,phone,role) values ('Omar Fathy','+971 50 900 7788','Supervisor') returning id into e_omr;

  -- Products
  insert into products(name,sku,category_id,unit,cost_price,sale_price,min_stock) values
    ('Arabica Coffee Beans 1kg','COF-ARB',c_cof,'kg',42.00,68.00,10) returning id into p_bean;
  insert into products(name,sku,category_id,unit,cost_price,sale_price,min_stock) values
    ('Cappuccino Cups (sleeve 50)','CUP-50',c_cup,'pack',9.00,15.00,20) returning id into p_cup;
  insert into products(name,sku,category_id,unit,cost_price,sale_price,min_stock) values
    ('Lay''s Classic 40g','SNK-LAY',c_snk,'pc',1.20,3.00,60) returning id into p_lay;
  insert into products(name,sku,category_id,unit,cost_price,sale_price,min_stock) values
    ('Doritos Nacho 40g','SNK-DOR',c_snk,'pc',1.40,3.50,60) returning id into p_dor;
  insert into products(name,sku,category_id,unit,cost_price,sale_price,min_stock) values
    ('Pringles Original 40g','SNK-PRI',c_snk,'pc',2.10,5.00,40) returning id into p_pri;
  insert into products(name,sku,category_id,unit,cost_price,sale_price,min_stock) values
    ('KitKat 4-Finger','CHO-KIT',c_cho,'pc',1.60,4.00,50) returning id into p_kit;
  insert into products(name,sku,category_id,unit,cost_price,sale_price,min_stock) values
    ('Snickers 50g','CHO-SNI',c_cho,'pc',1.70,4.00,50) returning id into p_sni;
  insert into products(name,sku,category_id,unit,cost_price,sale_price,min_stock) values
    ('Galaxy Milk 40g','CHO-GAL',c_cho,'pc',1.80,4.00,40) returning id into p_gal;
  insert into products(name,sku,category_id,unit,cost_price,sale_price,min_stock) values
    ('Water 330ml','WAT-330',c_wat,'pc',0.70,2.00,100) returning id into p_wat;
  insert into products(name,sku,category_id,unit,cost_price,sale_price,min_stock) values
    ('Pepsi 330ml Can','WAT-PEP',c_wat,'pc',1.50,3.50,80) returning id into p_pep;
  insert into products(name,sku,category_id,unit,cost_price,sale_price,min_stock) values
    ('Red Bull 250ml','WAT-RB',c_wat,'pc',4.50,9.00,30) returning id into p_rb;
  insert into products(name,sku,category_id,unit,cost_price,sale_price,min_stock) values
    ('Orange Juice 250ml','WAT-OJ',c_wat,'pc',2.20,5.00,30) returning id into p_oj;

  -- Machines
  insert into machines(code,name,type,site,location_id,status) values
    ('DXB-01','Marina Office Tower','combo','Dubai Marina',l_dxb,'active') returning id into m1;
  insert into machines(code,name,type,site,location_id,status) values
    ('DXB-02','Deira City Centre','snacks','Deira Mall',l_dxb,'active') returning id into m2;
  insert into machines(code,name,type,site,location_id,status) values
    ('DXB-03','Business Bay Clinic','coffee','Business Bay',l_dxb,'active') returning id into m3;
  insert into machines(code,name,type,site,location_id,status) values
    ('UAQ-01','UAQ University','combo','Umm Al Quwain',l_uaq,'active') returning id into m4;
  insert into machines(code,name,type,site,location_id,status) values
    ('AUH-01','Corniche Hospital','coffee','Abu Dhabi Corniche',l_auh,'active') returning id into m5;
  insert into machines(code,name,type,site,location_id,status) values
    ('AUH-02','Marina Mall AUH','snacks','Abu Dhabi',l_auh,'maintenance') returning id into m6;

  -- ===== Purchases & batches =====
  -- Dubai snacks/chocolate
  insert into purchases(supplier_id,location_id,ref_no,date) values (s_snk,l_dxb,'GS-1042',current_date-95) returning id into pur;
  insert into batches(purchase_id,product_id,location_id,qty_received,qty_remaining,unit_cost,expiry_date) values
    (pur,p_lay,l_dxb,500,500,1.20,current_date+120),
    (pur,p_dor,l_dxb,400,400,1.40,current_date+120),
    (pur,p_pri,l_dxb,200,200,2.10,current_date+150),
    (pur,p_kit,l_dxb,400,400,1.60,current_date+90),
    (pur,p_sni,l_dxb,400,400,1.70,current_date+90),
    (pur,p_gal,l_dxb,300,300,1.80,current_date+22);   -- near expiry -> amber alert
  -- Dubai drinks
  insert into purchases(supplier_id,location_id,ref_no,date) values (s_bev,l_dxb,'EB-2210',current_date-85) returning id into pur;
  insert into batches(purchase_id,product_id,location_id,qty_received,qty_remaining,unit_cost,expiry_date) values
    (pur,p_wat,l_dxb,800,800,0.70,current_date+200),
    (pur,p_pep,l_dxb,500,500,1.50,current_date+100),
    (pur,p_rb ,l_dxb,40 ,40 ,4.50,current_date+200),
    (pur,p_oj ,l_dxb,60 ,60 ,2.20,current_date+18);   -- near expiry -> amber alert
  -- Dubai coffee + cups
  insert into purchases(supplier_id,location_id,ref_no,date) values (s_cof,l_dxb,'RB-337',current_date-90) returning id into pur;
  insert into batches(purchase_id,product_id,location_id,qty_received,qty_remaining,unit_cost,expiry_date) values
    (pur,p_bean,l_dxb,60,60,42.00,current_date+240);
  insert into purchases(supplier_id,location_id,ref_no,date) values (s_pak,l_dxb,'PP-118',current_date-90) returning id into pur;
  insert into batches(purchase_id,product_id,location_id,qty_received,qty_remaining,unit_cost,expiry_date) values
    (pur,p_cup,l_dxb,40,40,9.00,current_date+300);

  -- Abu Dhabi
  insert into purchases(supplier_id,location_id,ref_no,date) values (s_snk,l_auh,'GS-1050',current_date-55) returning id into pur;
  insert into batches(purchase_id,product_id,location_id,qty_received,qty_remaining,unit_cost,expiry_date) values
    (pur,p_kit,l_auh,150,150,1.60,current_date+90),
    (pur,p_sni,l_auh,150,150,1.70,current_date+90),
    (pur,p_lay,l_auh,25 ,25 ,1.20,current_date-4);    -- EXPIRED -> red alert + waste demo
  insert into purchases(supplier_id,location_id,ref_no,date) values (s_cof,l_auh,'RB-340',current_date-55) returning id into pur;
  insert into batches(purchase_id,product_id,location_id,qty_received,qty_remaining,unit_cost,expiry_date) values
    (pur,p_bean,l_auh,30,30,43.00,current_date+240),
    (pur,p_cup ,l_auh,20,20,9.00 ,current_date+300);
  insert into purchases(supplier_id,location_id,ref_no,date) values (s_bev,l_auh,'EB-2255',current_date-55) returning id into pur;
  insert into batches(purchase_id,product_id,location_id,qty_received,qty_remaining,unit_cost,expiry_date) values
    (pur,p_wat,l_auh,300,300,0.72,current_date+200);

  -- Umm Al Quwain
  insert into purchases(supplier_id,location_id,ref_no,date) values (s_snk,l_uaq,'GS-1061',current_date-50) returning id into pur;
  insert into batches(purchase_id,product_id,location_id,qty_received,qty_remaining,unit_cost,expiry_date) values
    (pur,p_lay,l_uaq,200,200,1.25,current_date+120),
    (pur,p_kit,l_uaq,150,150,1.65,current_date+90);
  insert into purchases(supplier_id,location_id,ref_no,date) values (s_bev,l_uaq,'EB-2260',current_date-50) returning id into pur;
  insert into batches(purchase_id,product_id,location_id,qty_received,qty_remaining,unit_cost,expiry_date) values
    (pur,p_wat,l_uaq,300,300,0.72,current_date+200),
    (pur,p_pep,l_uaq,200,200,1.55,current_date+100);

  -- ===== Refills (spread over 6 months; newest are relative to today) =====
  -- Feb
  insert into issues(date,employee_id,machine_id,location_id) values ('2026-02-10',e_mah,m1,l_dxb) returning id into iss;
  perform pg_temp.refill_line(iss,p_lay,l_dxb,30,3.00); perform pg_temp.refill_line(iss,p_kit,l_dxb,25,4.00);
  perform pg_temp.refill_line(iss,p_wat,l_dxb,40,2.00); perform pg_temp.refill_line(iss,p_pep,l_dxb,20,3.50);
  insert into issues(date,employee_id,machine_id,location_id) values ('2026-02-18',e_you,m2,l_dxb) returning id into iss;
  perform pg_temp.refill_line(iss,p_dor,l_dxb,25,3.50); perform pg_temp.refill_line(iss,p_sni,l_dxb,20,4.00);
  perform pg_temp.refill_line(iss,p_gal,l_dxb,15,4.00);
  insert into issues(date,employee_id,machine_id,location_id) values ('2026-02-22',e_mah,m5,l_auh) returning id into iss;
  perform pg_temp.refill_line(iss,p_bean,l_auh,4,68.00); perform pg_temp.refill_line(iss,p_cup,l_auh,3,15.00);
  perform pg_temp.refill_line(iss,p_wat,l_auh,30,2.00);
  -- Mar
  insert into issues(date,employee_id,machine_id,location_id) values ('2026-03-08',e_you,m1,l_dxb) returning id into iss;
  perform pg_temp.refill_line(iss,p_lay,l_dxb,35,3.00); perform pg_temp.refill_line(iss,p_kit,l_dxb,30,4.00);
  perform pg_temp.refill_line(iss,p_wat,l_dxb,45,2.00); perform pg_temp.refill_line(iss,p_pep,l_dxb,25,3.50);
  insert into issues(date,employee_id,machine_id,location_id) values ('2026-03-15',e_mah,m4,l_uaq) returning id into iss;
  perform pg_temp.refill_line(iss,p_lay,l_uaq,25,3.00); perform pg_temp.refill_line(iss,p_kit,l_uaq,20,4.00);
  perform pg_temp.refill_line(iss,p_wat,l_uaq,35,2.00); perform pg_temp.refill_line(iss,p_pep,l_uaq,20,3.50);
  insert into issues(date,employee_id,machine_id,location_id) values ('2026-03-25',e_you,m3,l_dxb) returning id into iss;
  perform pg_temp.refill_line(iss,p_bean,l_dxb,5,68.00); perform pg_temp.refill_line(iss,p_cup,l_dxb,4,15.00);
  perform pg_temp.refill_line(iss,p_wat,l_dxb,30,2.00);
  -- Apr
  insert into issues(date,employee_id,machine_id,location_id) values ('2026-04-05',e_mah,m2,l_dxb) returning id into iss;
  perform pg_temp.refill_line(iss,p_pri,l_dxb,20,5.00); perform pg_temp.refill_line(iss,p_dor,l_dxb,25,3.50);
  perform pg_temp.refill_line(iss,p_sni,l_dxb,20,4.00);
  insert into issues(date,employee_id,machine_id,location_id) values ('2026-04-14',e_you,m5,l_auh) returning id into iss;
  perform pg_temp.refill_line(iss,p_bean,l_auh,4,68.00); perform pg_temp.refill_line(iss,p_cup,l_auh,3,15.00);
  perform pg_temp.refill_line(iss,p_wat,l_auh,30,2.00);
  insert into issues(date,employee_id,machine_id,location_id) values ('2026-04-21',e_mah,m1,l_dxb) returning id into iss;
  perform pg_temp.refill_line(iss,p_lay,l_dxb,30,3.00); perform pg_temp.refill_line(iss,p_gal,l_dxb,20,4.00);
  perform pg_temp.refill_line(iss,p_wat,l_dxb,40,2.00); perform pg_temp.refill_line(iss,p_rb,l_dxb,8,9.00);
  -- May
  insert into issues(date,employee_id,machine_id,location_id) values ('2026-05-06',e_you,m4,l_uaq) returning id into iss;
  perform pg_temp.refill_line(iss,p_lay,l_uaq,25,3.00); perform pg_temp.refill_line(iss,p_kit,l_uaq,20,4.00);
  perform pg_temp.refill_line(iss,p_wat,l_uaq,35,2.00); perform pg_temp.refill_line(iss,p_pep,l_uaq,20,3.50);
  insert into issues(date,employee_id,machine_id,location_id) values ('2026-05-16',e_mah,m3,l_dxb) returning id into iss;
  perform pg_temp.refill_line(iss,p_bean,l_dxb,5,68.00); perform pg_temp.refill_line(iss,p_cup,l_dxb,4,15.00);
  perform pg_temp.refill_line(iss,p_wat,l_dxb,30,2.00);
  insert into issues(date,employee_id,machine_id,location_id) values ('2026-05-27',e_you,m2,l_dxb) returning id into iss;
  perform pg_temp.refill_line(iss,p_dor,l_dxb,25,3.50); perform pg_temp.refill_line(iss,p_sni,l_dxb,25,4.00);
  perform pg_temp.refill_line(iss,p_pri,l_dxb,15,5.00);
  -- Jun
  insert into issues(date,employee_id,machine_id,location_id) values ('2026-06-07',e_mah,m1,l_dxb) returning id into iss;
  perform pg_temp.refill_line(iss,p_lay,l_dxb,35,3.00); perform pg_temp.refill_line(iss,p_kit,l_dxb,30,4.00);
  perform pg_temp.refill_line(iss,p_wat,l_dxb,45,2.00); perform pg_temp.refill_line(iss,p_pep,l_dxb,25,3.50);
  perform pg_temp.refill_line(iss,p_oj,l_dxb,10,5.00);
  insert into issues(date,employee_id,machine_id,location_id) values ('2026-06-18',e_you,m5,l_auh) returning id into iss;
  perform pg_temp.refill_line(iss,p_bean,l_auh,4,68.00); perform pg_temp.refill_line(iss,p_cup,l_auh,3,15.00);
  perform pg_temp.refill_line(iss,p_wat,l_auh,30,2.00);
  insert into issues(date,employee_id,machine_id,location_id) values ('2026-06-28',e_mah,m4,l_uaq) returning id into iss;
  perform pg_temp.refill_line(iss,p_lay,l_uaq,25,3.00); perform pg_temp.refill_line(iss,p_kit,l_uaq,20,4.00);
  perform pg_temp.refill_line(iss,p_wat,l_uaq,35,2.00);
  -- This month (relative to today, always populates "this month" KPIs)
  insert into issues(date,employee_id,machine_id,location_id) values (current_date-14,e_you,m1,l_dxb) returning id into iss;
  perform pg_temp.refill_line(iss,p_lay,l_dxb,30,3.00); perform pg_temp.refill_line(iss,p_kit,l_dxb,25,4.00);
  perform pg_temp.refill_line(iss,p_wat,l_dxb,40,2.00); perform pg_temp.refill_line(iss,p_pep,l_dxb,20,3.50);
  perform pg_temp.refill_line(iss,p_rb,l_dxb,7,9.00);
  insert into issues(date,employee_id,machine_id,location_id) values (current_date-7,e_mah,m3,l_dxb) returning id into iss;
  perform pg_temp.refill_line(iss,p_bean,l_dxb,5,68.00); perform pg_temp.refill_line(iss,p_cup,l_dxb,4,15.00);
  perform pg_temp.refill_line(iss,p_wat,l_dxb,30,2.00);
  insert into issues(date,employee_id,machine_id,location_id) values (current_date-2,e_you,m2,l_dxb) returning id into iss;
  perform pg_temp.refill_line(iss,p_dor,l_dxb,20,3.50); perform pg_temp.refill_line(iss,p_sni,l_dxb,20,4.00);
  perform pg_temp.refill_line(iss,p_gal,l_dxb,15,4.00);

  -- ===== Collections (cash pulled from machines) =====
  insert into collections(date,machine_id,employee_id,amount,notes) values
    ('2026-02-12',m1,e_mah,300,'Route A'), ('2026-02-20',m2,e_you,205,null), ('2026-02-24',m5,e_mah,150,null),
    ('2026-03-10',m1,e_you,320,null), ('2026-03-17',m4,e_mah,255,'UAQ run'), ('2026-03-27',m3,e_you,185,null),
    ('2026-04-07',m2,e_mah,210,null), ('2026-04-16',m5,e_you,160,null), ('2026-04-23',m1,e_mah,300,null),
    ('2026-05-08',m4,e_you,250,null), ('2026-05-18',m3,e_mah,180,null), ('2026-05-29',m2,e_you,235,null),
    ('2026-06-09',m1,e_mah,335,null), ('2026-06-20',m5,e_you,155,null), ('2026-06-30',m4,e_mah,245,null),
    (current_date-11,m1,e_you,310,null), (current_date-6,m3,e_mah,175,null), (current_date-1,m2,e_you,200,'Latest run');

  -- ===== One transfer: Water 100 from Dubai -> UAQ =====
  select id, unit_cost, expiry_date into bwat, bcost, bexp
    from batches where product_id=p_wat and location_id=l_dxb and qty_remaining>=100
    order by coalesce(expiry_date,'9999-12-31'), created_at limit 1;
  insert into transfers(date,from_location_id,to_location_id,employee_id,notes)
    values (current_date-9,l_dxb,l_uaq,e_kar,'Top-up UAQ warehouse') returning id into trf;
  insert into transfer_items(transfer_id,product_id,qty,unit_cost,alloc)
    values (trf,p_wat,100,bcost,jsonb_build_array(jsonb_build_object('b',bwat,'q',100)));
  update batches set qty_remaining = qty_remaining - 100 where id = bwat;
  insert into batches(transfer_id,product_id,location_id,qty_received,qty_remaining,unit_cost,expiry_date)
    values (trf,p_wat,l_uaq,100,100,bcost,bexp);

  -- ===== Waste / adjustments =====
  -- Expired Lay's at Abu Dhabi
  perform 1;
  declare bexp_lay uuid;
  begin
    select id into bexp_lay from batches where product_id=p_lay and location_id=l_auh and expiry_date < current_date limit 1;
    insert into adjustments(date,batch_id,product_id,location_id,qty,reason,notes)
      values (current_date-3,bexp_lay,p_lay,l_auh,10,'expired','Past expiry, pulled from shelf');
    update batches set qty_remaining = qty_remaining - 10 where id = bexp_lay;
  end;
  -- Damaged Pepsi at Dubai
  declare bpep uuid;
  begin
    select id into bpep from batches where product_id=p_pep and location_id=l_dxb order by created_at limit 1;
    insert into adjustments(date,batch_id,product_id,location_id,qty,reason,notes)
      values (current_date-20,bpep,p_pep,l_dxb,6,'damaged','Dented cans');
    update batches set qty_remaining = qty_remaining - 6 where id = bpep;
  end;

  raise notice 'Demo data loaded successfully.';
end $$;

drop function if exists pg_temp.refill_line(uuid,uuid,uuid,numeric,numeric);
