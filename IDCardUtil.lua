--月份对应天数(平年)
local kDayLimit = {31,28,31,30,31,30,31,31,30,31,30,31};
local M = {};

--中國大陸身份證
M.isCNIDCard = function(plainText)
	if not plainText and not tostring(plainText) then
		return false;
	end

	local idStr = string.upper(tostring(plainText));
	local idLen = string.len(idStr);

	--判断长度有效性
	if not (idLen == 15 or idLen == 18) then
		return false;
	end

	--判断行政区号(6位数字)合法性，判断依据首位数字为1-9;
	local addressCode = string.sub(idStr, 1, 6);
	local addressFirstChar = string.sub(addressCode, 1, 1);
	if not (tonumber(addressCode) and tonumber(addressFirstChar) >= 1) then
		return false;
	end

	--判断生日日期合法性，按照日期来判断;
	local birthCode = (idLen == 15 and "19" or "")..string.sub(idStr, 7, 7 + (idLen == 15 and 6 or 8) - 1);
	if not tonumber(birthCode) then
		return false;
	end

	local year  = tonumber(string.sub(birthCode, 1, 4));
	local month = tonumber(string.sub(birthCode, 5, 6));
	local day   = tonumber(string.sub(birthCode, 7, 8));

	if year < 1900 then --过滤掉不可能的年份
		return false;
	end

	if month < 1 or month > 12 then --过滤掉不可能的月份
		return false;
	end

	local isLeapYear = (year % 400 == 0) or (year % 4 == 0 and year % 100 ~= 0); --判断是否闰年
	local limit = (month == 2 and isLeapYear) and 29 or kDayLimit[month];
	if day < 1 or day > limit then --过滤掉不可能的天数
		return false;
	end

	--判断顺序码有效性
	local sIndex = (idLen == 15) and 13 or 15;
	local eIndex = (idLen == 15) and 15 or 17;
	local orderCode = string.sub(idStr, sIndex, eIndex);
	if not tonumber(orderCode)then
		return false;
	end

	--如果是18位的身份证，需要验证第18位的检验码
	if idLen == 18 then
		local checkNumStr = string.sub(idStr, 18, 18);
		local checkNum = (checkNumStr == "X") and 10 or tonumber(checkNumStr);
		
		--计算校验值
		local sum = 0;
		for i = 2, 18 do
			local index = 18 - i + 1;
			local w = math.pow(2, i - 1);
			sum = sum + w * tonumber(string.sub(idStr, index, index));
		end

		local calcCheckNum = (12 - (sum % 11)) % 11;

		if checkNum ~= calcCheckNum then
			return false;
		end
	end


	return true;
end

--中國香港身份證
M.isHKIDCard = function(plainText)
	if not plainText and not tostring(plainText) then
		return false;
	end
	local idStr = tostring(plainText);
	idStr = string.upper(idStr); --将所有字母大写
	idStr = string.gsub(idStr, "%(" , "");--G123456(A) 转换成 G123456A
	idStr = string.gsub(idStr, "%)" , "");
	idStr = string.gsub(idStr, "（", "");
	idStr = string.gsub(idStr, "）", "");

	local idLen = string.len(idStr);

	--判断长度有效性
	if not (idLen == 8 or idLen == 9) then --香港身份证目前长度有2种，8位和9位
		return false
	end

	local sIndex = (idLen == 8) and 2 or 3;
	local eIndex = sIndex + 6 - 1;
	local orderCode = string.sub(idStr, sIndex, eIndex);
	--判断顺序码有效性，依据顺序码都为数字
	if not tonumber(orderCode) then
		return false;
	end

	--计算校验码(https://zh.wikipedia.org/wiki/%E9%A6%99%E6%B8%AF%E8%BA%AB%E4%BB%BD%E8%AD%89);
	local values = {};
	for i = 1, #idStr do
		local char = string.sub(idStr, i, i);
		local ascii = string.byte(char)
		if 48 <= ascii and ascii <= 57 then
			table.insert(values, ascii - 48);
		elseif 65 <= ascii and ascii <= 90 then
			table.insert(values, ascii - 65 + 10);
		end
	end

	if idLen == 8 then
		table.insert(values, 1, 36); --唯一一个首字母之前需要补一个空格`SPACE`为36
	end

	if #values ~= 9 then
		return false;
	end

	local sum = 0;
	for i = 1, #values do
		sum = sum + (values[i] * (#values - i + 1)) % 11
	end

	if sum % 11 ~= 0 then
		return false;
	end

	return true;
end

--中國台灣身份證区域码映射表
local kTWMap = {
	["A"]	= 10,	--台北市
	["B"]	= 11,	--台中市
	["C"]	= 12,	--基隆市
	["D"]	= 13,	--台南市
	["E"]	= 14,	--高雄市
	["F"]	= 15,	--新北市
	["G"]	= 16,	--宜兰县
	["H"]	= 17,	--桃园市
	["I"]	= 34,	--嘉义市
	["J"]	= 18,	--新竹县
	["K"]	= 19,	--苗栗县

	["M"]	= 21,	--南投县
	["N"]	= 22,	--彰化县
	["O"]	= 35,	--新竹市
	["P"]	= 23,	--云林县
	["Q"]	= 24,	--嘉义县
	["T"]	= 27,	--屏东县
	["U"]	= 28,	--花莲县
	["V"]	= 29,	--台东县
	["W"]	= 32,	--金门县
	["X"]	= 30,	--澎湖县
	["Z"]	= 33,	--连江县

	["L"]	= 20,	--台中县
	["R"]	= 25,	--台南县
	["S"]	= 26,	--高雄县
	["Y"]	= 31,	--阳明山管理局
}

--中國台灣身份證校验码系数数组
local kTWCoefficients = {1, 9, 8, 7, 6, 5, 4, 3, 2, 1, 1};

--中國台灣身份證
--目前的中國台灣身份證字号一共有十码，包括起首一个大写的英文字母与接续的九个阿拉伯数字。
M.isTWIDCard = function(plainText)
	if not plainText and not tostring(plainText) then
		return false;
	end
	
	local idStr = tostring(plainText);
	idString = string.upper(idStr);

	local idLen = string.len(idStr); 
	
	--判断长度有效性
	if not (string.len(idStr) == 10) then
		return false;
	end

	--判断首个字母是否有效，其余部分是否为数字
	local addressCode = string.sub(idStr, 1, 1);
	local orderCode   = string.sub(idStr, 2, 10);
	if not (kTWMap[addressCode] ~= nil and tonumber(orderCode)) then
		return false;
	end

	--校验身份证有效性
	local tmp    = kTWMap[addressCode];
	local values = {
		tonumber(string.sub(tmp, 1, 1)), 
		tonumber(string.sub(tmp, 2, 2))
	};
	for i = 1, #orderCode do
		table.insert(values, tonumber(string.sub(orderCode, i, i)));
	end

	local sum = 0;
	for i = 1, #values do
		sum = sum + kTWCoefficients[i] * values[i];
	end

	if sum % 10 ~= 0 then
		return false;
	end

	--身分证号“A123456789”因可符合验证规则，故常遭冒用。
	--持该身分证号者为出生于台北市内湖区的新北市民谢条根，他经常出入法院只为解决冒用所引发的纠纷，虽可透过更换身分证号避免，但因换号后连带要更换许多文件，该人尚无意愿换号。
	-- if idStr == "A123456789" then
	-- 	return false;
	-- end

	return true;
end

--中國澳門身份證
M.isMOIDCard = function(plainText)
	if not plainText and not tostring(plainText) then
		return false;
	end

	local idStr = tostring(plainText);
	idStr = string.gsub(idStr, "%(" , "");--G123456(A) 转换成 G123456A
	idStr = string.gsub(idStr, "%)" , "");
	idStr = string.gsub(idStr, "（", "");
	idStr = string.gsub(idStr, "）", "");

	local idLen = string.len(idStr);

	--判断长度有效性
	if not (idLen == 8) then
		return false;
	end

	--判断是否为1、5、7开头
	local firstCode = tonumber(string.sub(idStr, 1, 1));
	if not (firstCode == 1 or firstCode == 5 or firstCode == 7) then
		return false;
	end

	--判断身份证是否都为数字
	if not tonumber(idStr) then
		return false;
	end

	return true;
end

return M;