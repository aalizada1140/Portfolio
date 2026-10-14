Select * from address;
Select * from address_type;
Select * from call_type;
Select * from calls;
Select * from complaint_type;
Select * from complaints_and_support_requests;
Select * from payment_method_type;
Select * from payments;
Select * from services;
Select * from sms_informations;
Select * from sms_types;
Select * from subscribers;
Select * from tariff_informations;
Select * from tariffs;
Select * from technical_data;
Select * from users;

-- 1. Abonentlərin yaş qrupuna görə və cinsiyyətə görə bölgüsünü göstər:
--    Yaş qrupları aşağıdakı şəkildədi
--    18 və aşağı
--    19-30
--    31-50
--    51 və yuxarı
--    Ekrana yaş aralığı,cins və say haqqında informasiyalar çıxsın.

    with age_range as (
                     Select sb.subscribers_id,
                            gender,
                            case 
                                 when trunc(months_between(sysdate, birth_date)/12) <=18 then '18 və aşağı'
                                 when trunc(months_between(sysdate, birth_date)/12) between 19 and 30 then '19-30'
                                 when trunc(months_between(sysdate, birth_date)/12) between 31 and 50 then '31-50'
                                 when trunc(months_between(sysdate, birth_date)/12) >= 51 then '51 və yuxarı'
                                 else '-'
                             end as age_range
                       from subscribers sb
                     )
         /*       gender_group as (
                                  Select subscribers_id,
                                         decode(gender,'Male',1) as 'kisi',
                                         decode(gender,'Female',1) as 'qadin'
                                    from  
                                         )*/
     Select age_range,gender,count(subscribers_id) as count_in_ages from age_range group by age_range, gender order by age_range;
--2.Hər abonent üçün son ödəniş tarixini və məbləğini göstər: 
--    Ekrana Ad, soyad, son ödəniş tarixi, məbləği və ödənişin üsulu haqqında informasiyalar çıxsın.
            Select pay.subscribers_id,
                   sb.name||' '||sb.surname,
                   max(pay.payment_date),
                   pay.amount,
                   sb.EMAIL,
                   sb.PHONE_NUMBER,
                   sb.STATUS
              from payments pay
              join 
                   subscribers sb
                on pay.subscribers_id = sb.subscribers_id
              group by pay.subscribers_id,
                       pay.amount,
                       sb.name,
                       sb.surname,
                       sb.EMAIL,
                       sb.PHONE_NUMBER,
                       sb.STATUS
              order by pay.subscribers_id; 
              
-- 3.Aktiv xidmətlər üzrə abonentlərin sayını və ümumi ödəniş məbləğini göstər:
--    Ekrana xidmətin adı,abonentlərin sayını və ümumi ödəniş məbləği haqqında informasiyalar çıxsın. 
       Select pay_m.name,
              count(subscribers_id),
              sum(pay.amount)
         from payments pay
         join payment_method_type pay_m
           on pay.payment_type_id = pay_m.payment_type_id
        group by pay_m.payment_type_id,
                 pay_m.name
        order by pay_m.payment_type_id;
-- 4.Hər abonent üçün edilən zənglərin sayını və ümumi zəng müddətini göstər:
--    Ekrana ad, soyad, abonent üçün edilən zənglərin sayını, ümumi zəng müddətini, zəngin tipi haqqında informasiyalar çıxsın.
      
      
      Select sub.name,
             sub.surname,
             count(c.caller_id) as number_of_calls,
             sum(c.call_duration) as total_duration,
             c.call_type as send_receive,
             c_t.name as call_type_2
        from subscribers sub
        join calls c
          on sub.subscribers_id = c.caller_id
        join call_type c_t
          on c.call_type_id = c_t.call_type_id
       group by sub.name,
             sub.surname,
             c.call_type,
             c_t.name;
--5.Hər abonent üçün tarifə görə aylıq ödədikləri məbləği və zənglərin sayını göstər:
--    Ekrana ad, soyad,tarifə görə aylıq ödədikləri məbləğ və zənglərin sayı haqqında informasiyalar çıxsın. 
      
      Select sub.name,
             sub.surname,
             tinfo.monthly_subscription,
             count(c.caller_id) as number_of_calls
        from subscribers sub
        join calls c
          on sub.subscribers_id = c.caller_id
        join services srv  
          on c.service_id = srv.service_id
        join tariff_informations tinfo
          on srv.tariff_id = tinfo.tariff_id
       group by sub.name,
             sub.surname,
             tinfo.monthly_subscription; 
          
      
--6.Zənglərin növünə görə abonentlərin sayını və ümumi zəng müddətini göstər:
             
             Select c_t.name as call_type,
                    count(c.caller_id) as number_of_subscribers,
                    sum(c.call_duration) as total_duration
               from subscribers sub
               join calls c
                 on sub.subscribers_id = c.caller_id
               join call_type c_t
                 on c_t.call_type_id = c.call_type_id
              group by c_t.name;    
              
--7.Hər tarif üzrə abonentlərin orta yaşını göstər:

      Select tinfo.tariff_name,
             round(avg(months_between(sysdate, birth_date)/12)) as average_age
        from subscribers sub
        join calls c
          on sub.subscribers_id = c.caller_id
        join services srv  
          on c.service_id = srv.service_id
        join tariff_informations tinfo
          on srv.tariff_id = tinfo.tariff_id
       group by tinfo.tariff_name; 
       
--8.Son 6 ayda edilən ödənişlərin məbləğini və xidmətlərin sayını abonentlər üzrə göstər.
--    Ekrana abonentin adı, abonentin soyadı, xidmətlərin sayı və 6 ayda edilən ödənişlərin məbləği haqqında informasiyalar çıxsın.
     
     Select sub.name,
            sub.surname,
            count(c.service_id) as number_of_services,
            sum(pay.amount) as paid_last_6months
       from subscribers sub
       join calls c
         on sub.subscribers_id = c.caller_id
       join payments pay 
         on c.caller_id = pay.subscribers_id
        and to_char(pay.payment_date, 'mm') <= 6
      group by sub.name,
               sub.surname;
     
--9.Hər şikayət növü üzrə həll olunma müddətinin orta dəyərini və şikayət sayını göstər:
      Select req.complaint_type_id,
             ct.complaint_type_name,
             avg(req.resolution_date - req.submission_date) as avg_solution_days,
             count(req.complaint_id) as complaint_count
        from complaints_and_support_requests req
        join complaint_type ct
          on req.complaint_type_id = ct.complaint_type_id
          and lower(req.status) = 'solved'
       group by ct.complaint_type_name,
                req.complaint_type_id
       order by req.complaint_type_id;
--10. Hər abonent üçün son 12 ayda göndərilən SMS-lərin sayını və SMS məzmununu göstər:
     
     Select sub.subscribers_id,
            sub.name,
            sub.surname,
            count(smsi.sms_id) over(partition by sub.subscribers_id order by sub.subscribers_id) as sms_last_12_months,
            smsi.sms_content
       from subscribers sub
       join sms_informations smsi
         on sub.subscribers_id = smsi.sender_id
           and 
            months_between(sysdate,smsi.sms_date) <=12;
  --    group by sub.subscribers_id,
   --            sub.name,
    --           sub.surname;
           --    smsi.sms_content;
           
  /*   Select sub.subscribers_id,
            sub.name,
            sub.surname,
            count(smsi.sms_id),
            smst.name
       from subscribers sub
       join sms_informations smsi
         on sub.subscribers_id = smsi.sender_id
           and 
            months_between(sysdate,smsi.sms_date) <=12
       join sms_types smst
         on smsi.sms_type_id = smst.sms_type_id
   group by sub.subscribers_id,
            sub.name,
            sub.surname,
            smst.name
   order by sub.subscribers_id,
            sub.name,
            sub.surname,
            smst.name;
        */
    
--11.Hər abonent üçün edilən zənglərin ümumi müddətini və ödəniş məlumatlarını göstər:    
--   Ekrana abonentin adı, abonentin soyadı, zənglərin ümumi müddətini ödəniş məlumatları haqqında informasiyalar çıxsın. 
 
      Select sub.name,
             sub.surname,
             sum(c.call_duration) as call_duration,
             tinfo.tariff_name,
             tinfo.monthly_subscription,
             count(call_id)*tinfo.call_price as total_call_price
        from subscribers sub
        join calls c 
          on sub.subscribers_id = c.caller_id
        join services ser
          on c.service_id = ser.service_id 
        join tariff_informations tinfo
          on ser.tariff_id = tinfo.tariff_id
          and lower(tinfo.status) = 'active'
       group by sub.name,
                sub.surname,
                tinfo.tariff_name,
                tinfo.monthly_subscription,
                tinfo.call_price;
      
--12. Hər abonent üçün son 12 ayda göndərilən SMS-lərin məzmununu və göndərilən SMS növlərini göstər:
--   Ekrana abonentin adı, soyadı, son 12 ayda göndərilən SMS-lərin məzmununu və göndərilən SMS növləri haqqında informasiyalar çıxsın.  
 Select sub.subscribers_id,
            sub.name,
            sub.surname,
            count(smsi.sms_id) over(partition by sub.subscribers_id order by sub.subscribers_id) as sms_last_12_months,
            smsi.sms_content,
            smst.name
       from subscribers sub
       join sms_informations smsi
         on sub.subscribers_id = smsi.sender_id
           and 
            months_between(sysdate,smsi.sms_date) <=12
       join sms_types smst
         on smsi.sms_type_id = smst.sms_type_id;

-- 13. Hər abonent üçün son 6 ayda edilən ödənişlərin məbləğini və xidmətlərin sayını göstər:
--   Ekrana abonentin adı, soyadı, son 6 ayda edilən ödənişlərin məbləğini və xidmətlərin sayı haqqında informasiyalar çıxsın.

      Select sub.name,
            sub.surname,
            sum(pay.amount) as paid_last_6months,
            count(c.service_id) as number_of_services
       from subscribers sub
       join calls c
         on sub.subscribers_id = c.caller_id
       join payments pay 
         on c.caller_id = pay.subscribers_id
        and to_char(pay.payment_date, 'mm') <= 6
      group by sub.name,
               sub.surname;
        
-- 14. Hər abonent üçün ödənişlər və şikayətlərin məbləğini göstər:
--   Ekrana abonentin adı, soyadı, hər abonent üçün ödənişlər və şikayətlərin sayı haqqında informasiyalar çıxsın.

      Select sub.name,
             sub.surname,
             sum(pay.amount) as amount,
             count(req.complaint_id) as complaint_counts
        from subscribers sub
        join complaints_and_support_requests req
          on sub.subscribers_id = req.subscribers_id
        join payments pay
          on pay.subscribers_id = req.subscribers_id
       group by sub.name,
             sub.surname;
             
-- 15. Hər tarif üzrə abonentlərin yaş qruplarına görə və aylıq ödədikləri məbləğin orta dəyərini göstər:
--     Ekrana tarifin adı, yaş qrupları, aylıq ödədikləri məbləğin orta dəyəri haqqında informasiyalar çıxsın. 
Select * from payments;
Select * from tariff_informations;
Select * from services;
Select * from calls;
Select * from subscribers;

        with age_range as (
                     Select sb.subscribers_id,
                            case 
                                 when trunc(months_between(sysdate, birth_date)/12) <=18 then '18 və aşağı'
                                 when trunc(months_between(sysdate, birth_date)/12) between 19 and 30 then '19-30'
                                 when trunc(months_between(sysdate, birth_date)/12) between 31 and 50 then '31-50'
                                 when trunc(months_between(sysdate, birth_date)/12) >= 51 then '51 və yuxarı'
                                 else '-'
                             end as age_range
                       from subscribers sb
                     )
     Select tinfo.tariff_name,
            age_range,
            avg(pay.amount)
       from age_range age
       join payments pay
         on pay.subscribers_id = age.subscribers_id
       join calls c
         on c.caller_id = pay.subscribers_id
       join services ser
         on c.service_id = ser.service_id
       join tariff_informations tinfo 
         on ser.tariff_id = tinfo.tariff_id
      group by tinfo.tariff_name,
               age.age_range,
               trunc(pay.payment_date, 'MM');
-- 16. Hər abonentin ümumi ödədiyi məbləği və onların ödədikləri məbləğin tariflərin ortalama ödəmə məbləğindən yüksək olub 
--     olmadığını göstərən sorğu:

               Select sub.subscribers_id,
                     (Select sum(pay.amount) from payments pay where sub.subscribers_id = pay.subscribers_id) as total_amount
                 from subscribers sub
                 where sub.total_amount
                )
            Select
                   avg(count(c.caller_id)*sum(tinfo.monthly_subscription))
              from calls c
              join services ser
                on c.service_id = ser.service_id
              join tariff_informations tinfo
                on ser.tariff_id = tinfo.tariff_id
             group by ser.tariff_id;    
                
         
         
                   Select
                          count(c.caller_id)*sum(tinfo.monthly_subscription)
                     from calls c
                     join services ser
                       on c.service_id = ser.service_id
                     join tariff_informations tinfo
                       on ser.tariff_id = tinfo.tariff_id
                    group by ser.tariff_id;
                    
-- 17. Hər abonentin zənglərin ümumi müddətini və onların zəng müddətinin abonentin yaş qrupunun ortalama zəng müddətindən 
--     yüksək olub olmadığını göstərən sorğu:             
     with age_range as (
                     Select sb.subscribers_id,
                            case 
                                 when trunc(months_between(sysdate, birth_date)/12) <=18 then '18 və aşağı'
                                 when trunc(months_between(sysdate, birth_date)/12) between 19 and 30 then '19-30'
                                 when trunc(months_between(sysdate, birth_date)/12) between 31 and 50 then '31-50'
                                 when trunc(months_between(sysdate, birth_date)/12) >= 51 then '51 və yuxarı'
                                 else '-'
                             end as age
                       from subscribers sb
                       
                     )
       Select a.*,
              sum(c.call_duration) as total_call_duration,
              avg(c.call_duration) as avg_call_duration,
              sum(c.call_duration) - avg(c.call_duration) as diff_between_sum_avg
         from age_range a
         join calls c
           on a.subscribers_id = c.caller_id
       group by a.age,
                a.subscribers_id;
         
      


      

     




