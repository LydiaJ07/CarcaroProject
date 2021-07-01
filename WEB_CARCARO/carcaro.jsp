<%@page language="java" %>
<%@page import="java.util.Date" %>
<%@page import="java.text.SimpleDateFormat" %>
<%@page import="java.sql.*, javax.sql.*, java.io.*, java.net.URL, java.util.*" %>
<%@page contentType="text/html; charset=utf-8" %>

<!DOCTYPE html>
<head>
    <meta charset="UTF-8">
    <title>CARCARO 카카오 - 최근 서울 교통 상황 확인</title>
    <link rel="stylesheet" href="css.css">
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"
        integrity="sha256-/xUj+3OJU5yExlq6GSYGSHk7tPXikynS7ogEvDej/m4=" crossorigin="anonymous"></script>
</head>
<body>
<%
request.setCharacterEncoding("utf-8");

Date now_time = new Date(); //오늘 날짜

SimpleDateFormat df_search = new SimpleDateFormat("yyyy-MM-dd");
SimpleDateFormat df_print_1 = new SimpleDateFormat("MM월 dd일(");
SimpleDateFormat df_print_2 = new SimpleDateFormat(") hh:mma");

Calendar today = Calendar.getInstance(); //날짜 계산
today.add(Calendar.DATE, -1);
String day_before = df_search.format(today.getTime());
today.add(Calendar.DATE, -7);
String week_before = df_search.format(today.getTime());

String dayResult ="";
switch(now_time.getDay()){
    case 0 :
    dayResult = "일";
    break;
    case 1 :
    dayResult = "월";
    break;
    case 2 :
    dayResult = "화";
    break;
    case 3 :
    dayResult = "수";
    break;
    case 4 :
    dayResult = "목";
    break;
    case 5 :
    dayResult = "금";
    break;
    case 6 :
    dayResult = "토";
    break;
}

String nowTimePrint = df_print_1.format(now_time) + dayResult + df_print_2.format(now_time);

Class.forName("com.mysql.jdbc.Driver");
Connection conn = DriverManager.getConnection("jdbc:mysql://192.168.23.71:3306/kopo36", "root", "wjdthdud12");
Statement stmt = conn.createStatement();

ResultSet rset = stmt.executeQuery("select * from seoulSpeedData where date='" + df_search.format(now_time) + "' order by recordTime desc limit 1;");

//현재 속도
double seoul_speed_now =0;

//기록 시간
String time_now = "00:03";

//통제 정보
int total_control_num = 0;
int control_type1 = 0;
int control_type2 = 0;
int control_type3 = 0;
while(rset.next()) {
    time_now = rset.getString(2);
    seoul_speed_now = Double.parseDouble((rset.getString(3)).replace("km/h", ""));
    total_control_num = rset.getInt(7);
    control_type1 = rset.getInt(8);
    control_type2 = rset.getInt(9);
    control_type3 = rset.getInt(10);

    String word = "은";
    if((rset.getString(4)).equals(rset.getString(6))) word = "도";

%>
    <div id="body_entire_wrap">
        <div id="body1_wrap">
            <div id="msg_wrap">
                <div class="msg_location">
                    <span id="title">지금의 서울 </span>
                    <span id="time"><%= nowTimePrint %></span>
                </div>
                <div id="weather_msg_wrap">
                    <div class="msg_box">오늘의 날씨 <%= rset.getString(11) %></div>
                    <div class="msg_box">미세먼지 <%= rset.getString(12) %> • 초미세먼지 <%= rset.getString(13) %></div>
                </div>
                <div id="traffic_msg_wrap">
                    <div class="msg_box">
                        서울은 <%= rset.getString(4) %> (<%= rset.getString(3) %>) 
                        도심<%= word %> <%= rset.getString(6) %> (<%= rset.getString(5) %>)
                    </div>
<%
}

rset.close();

rset = stmt.executeQuery("select replace(Seoul_speed, 'km/h', '') from seoulSpeedData where date='" + day_before + "' and recordTime='" + time_now + "';");

while(rset.next()) {
    int diff = (int)(seoul_speed_now - Double.parseDouble(rset.getString(1)));

    if (seoul_speed_now < Double.parseDouble(rset.getString(1))) {
        out.print(
        "<div class='msg_box'>어제 같은 시간보다  " + diff*(-1) + "km/h 더 막혀요😓</div>" +
        "<div class='msg_box'>🚗5분 일찍 출발하세요</div>"
        );
    } else if (seoul_speed_now == Double.parseDouble(rset.getString(1))) {
        out.print(
            "<div class='msg_box'>어제와 교통 상황이 비슷해요🙂</div>"
            );
    } else {
        out.print(
            "<div class='msg_box'>어제 같은 시간 보다 " + diff + "km/h만큼 빨리갈 수 있어요🤩</div>" +
            "<div class='msg_box'>여유롭게 출발해도 좋아요!☕</div>"
            );
    }
}

rset.close();

String msg_control = "출발 전 통제 구간 정보를 확인하세요!";
if(total_control_num == 0) {
    msg_control = "교통 통제가 없어요! 안심하고 운전하세요😁";
}

%>
                </div>
                <div id="traffic_msg_wrap">
                    <div class="msg_box">🚦지금 서울 내 교통 통제 총 <%= total_control_num %>건</div>
                    <div class="msg_box"><%= msg_control %></div>
                </div>
                <div>
                    <div class="msg_location" style="margin-top: 20px;"><span class="body2_title">교통 통제 정보</span></div>
                    <div id="body2_msg_wrap">
                        <div class="body2_count_box">서울 내 교통 통제 총 <%= total_control_num %>건</div>
                        <div class="body2_count_box">공사/집회 <%= control_type1 %>건</div>
                        <div class="body2_count_box">사고/고장 <%= control_type2 %>건</div>
                        <div class="body2_count_box">기상/화재 <%= control_type3 %>건</div>
                    </div>
                    <div id="body2_msg_wrap">

<%
rset = stmt.executeQuery("select * from seoulTrafficControl where date='" + df_search.format(now_time) + "' order by recordTime desc limit " + total_control_num + ";");

while(rset.next()) {

%>
                        <div class="body2_msg_box">
                            <b><%= rset.getString(3) %></b> <%= rset.getString(4) %>  
                            <br>시작 <%= rset.getString(5) %> 종료 <%= rset.getString(6) %>
                        </div>
<%
}
%>
                    </div>
                </div>
            </div>
        </div>
        <div id="body2_wrap">
            <div class="msg_location">
                <span id="title">지나간 서울 </span>
            </div>
<%
    rset = stmt.executeQuery("select " +
    "(select recordTime from seoulSpeedData where date = '" + day_before + "' order by Seoul_speed desc limit 1), " +
    "(select recordTime from seoulSpeedData where date = '" + day_before + "' order by Seoul_speed limit 1);"
    );

    String maxTime = "";
    String minTime = "";

    while(rset.next()) {
        maxTime = rset.getString(1);
        minTime = rset.getString(2);
    }
    rset.close();

    rset = stmt.executeQuery(
    "select " +
    "(select Seoul_speed from seoulSpeedData where date = '" + day_before + "' and recordTime = '" + maxTime + "'), " +
    "(select Seoul_speed from seoulSpeedData where date = '" + day_before + "' and recordTime = '" + minTime + "');"
    );

    while(rset.next()) {
%>
            <div class="msg_location"><span class="body2_title">어제의 서울</span></div>
            <div id="body2_msg_wrap">
                <div class="info_box">
                    😨 가장 막힌 시간 : <%= maxTime.substring(0, 2) %>시 (<%= rset.getString(1) %>)
                </div>
                <div class="info_box">
                    😄 가장 쾌적한 시간 : <%= minTime.substring(0, 2) %>시 (<%= rset.getString(2) %>)
                </div>
            </div>
<%
        }
        rset.close();

        String QueryTxt = "select ";
        for (int i = 0; i < 24; i++) {
            String hour = "";

            if (i < 10) {
                hour += "0" + i;                
            } else {
                hour += i;
            }

            String temp_query= "(select round(avg(Seoul_speed)) from seoulSpeedData where recordTime like '" 
                                                                + hour + "%' and date='" + day_before + "'), ";


            if(i == 23) {
                QueryTxt += temp_query.replace(", ", "") + ";";
            } else {
                QueryTxt += temp_query;
            }
        }

        rset = stmt.executeQuery(QueryTxt);
        
        
        out.print(
            "<div id='graph_wrap'>" +
                "<ul class='ratio'>"
        );


        while(rset.next()) {
            int percentage = 0;
            for (int i =1; i < 25; i ++) {
                percentage = (int)((double)rset.getInt(i)/40*100);
                out.print("<li><div style='height:" + percentage +  "%'><em>" + rset.getInt(i) + "</em></div></li>");

            }                
%>
                </ul>
                <div id="footer_wrap">
                    <span>0시</span>
                    <span>1시</span>
                    <span>2시</span>
                    <span>3시</span>
                    <span>4시</span>
                    <span>5시</span>
                    <span>6시</span>
                    <span>7시</span>
                    <span>8시</span>
                    <span>9시</span>
                    <span>10시</span>
                    <span>11시</span>
                    <span>12시</span>
                    <span>13시</span>
                    <span>14시</span>
                    <span>15시</span>
                    <span>16시</span>
                    <span>17시</span>
                    <span>18시</span>
                    <span>19시</span>
                    <span>20시</span>
                    <span>21시</span>
                    <span>22시</span>
                    <span>23시</span>
                </div>
                <p id="graph_unit">*단위: km/h</p>
            </div>
            <br>
            <hr>
<%      
        }
        rset.close();

        rset = stmt.executeQuery(
            "select date, avg(Seoul_speed) as ave from seoulSpeedData where date>='" + week_before + "' && date<='" + day_before + "' group by date order by ave;"
        );

        while (rset.next()) {
            //out.print(rset.getString(1));
            //out.print(rset.getInt(2));

            //String min_date = rset.getString(1);
            //String max_date = rset.getString(size/2);
        }
%>
            <div class="msg_location"><span class="body2_title">지난주 서울</span></div>
            <div id="body2_msg_wrap">
                <div class="info_box">😨 가장 막힌 요일 : 금요일 (14.2km/h)</div>
                <div class="info_box">😄 가장 쾌적한 요일 : 목요일 (19.6km/h)</div>
            </div>
            <div id="graph2_wrap">
                <ul class="ratio">
                    <li><div style="height:50%"><em>14</em></div></li>
                    <li><div style="height:60%"><em>15</em></div></li>
                    <li><div style="height:70%"><em>17</em></div></li>
                    <li><div style="height:90%"><em>19</em></div></li>
                    <li><div style="height:55%"><em>14</em></div></li>

                    <li><div style="height:60%"><em>15</em></div></li>
                    <li><div style="height:80%"><em>18</em></div></li>

                </ul>
                <div id="footer_wrap">
                    <span>일</span>
                    <span>월</span>
                    <span>화</span>
                    <span>수</span>
                    <span>목</span>
                    <span>금</span>
                    <span>토</span>
                </div>
                <p id="graph_unit">*단위: km/h</p>
            </div>
            <hr>
        </div>
    </div>
    <%
rset.close();
stmt.close();
conn.close();
%>
</body>
</html>
