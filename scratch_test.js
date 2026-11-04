const math = Math;

function degreesToRadians(degrees) {
  return (degrees * math.PI) / 180.0;
}
function radiansToDegrees(radians) {
  return (radians * 180.0) / math.PI;
}
function unwindAngle(angle) {
  const value = angle % 360.0;
  return value < 0 ? value + 360.0 : value;
}
function normalizeToScale(number, max) {
  return number - max * math.floor(number / max);
}
function quadrantShiftAngle(angle) {
  if (angle >= -180 && angle <= 180) {
    return angle;
  }
  return angle - 360 * math.round(angle / 360);
}

function julianDay(year, month, day, hours = 0) {
  const trunc = (val) => math.trunc(val);
  let Y = trunc(month > 2 ? year : year - 1);
  let M = trunc(month > 2 ? month : month + 12);
  let D = day + (hours / 24);
  let A = trunc(Y / 100);
  let B = trunc(2 - A + trunc(A / 4));
  let i0 = trunc(365.25 * (Y + 4716));
  let i1 = trunc(30.6001 * (M + 1));
  return i0 + i1 + D + B - 1524.5;
}

function julianCentury(jd) {
  return (jd - 2451545.0) / 36525;
}

function meanSolarLongitude(T) {
  const term1 = 280.4664567;
  const term2 = 36000.76983 * T;
  const term3 = 0.0003032 * math.pow(T, 2);
  return unwindAngle(term1 + term2 + term3);
}

function meanSolarAnomaly(T) {
  const term1 = 357.52911;
  const term2 = 35999.05029 * T;
  const term3 = 0.0001537 * math.pow(T, 2);
  return unwindAngle(term1 + term2 - term3);
}

function solarEquationOfTheCenter(T, M) {
  const mrad = degreesToRadians(M);
  return (1.914602 - (0.004817 * T) - (0.000014 * math.pow(T, 2))) * math.sin(mrad)
       + (0.019993 - 0.000101 * T) * math.sin(2 * mrad)
       + 0.000289 * math.sin(3 * mrad);
}

function apparentSolarLongitude(T, L0) {
  const omega = 125.04 - 1934.136 * T;
  const lambda = L0 - 0.00569 - 0.00478 * math.sin(degreesToRadians(omega));
  return unwindAngle(lambda);
}

function meanObliquityOfTheEcliptic(T) {
  return 23.439291 - 0.0130042 * T - 0.00000016 * math.pow(T, 2) + 0.000000504 * math.pow(T, 3);
}

function apparentObliquityOfTheEcliptic(T, eps0) {
  const omega = 125.04 - 1934.136 * T;
  return eps0 + 0.00256 * math.cos(degreesToRadians(omega));
}

function solarCoordinates(jd) {
  const T = julianCentury(jd);
  const L0 = meanSolarLongitude(T);
  const M = meanSolarAnomaly(T);
  const C = solarEquationOfTheCenter(T, M);
  const trueLong = unwindAngle(L0 + C);
  const appLong = apparentSolarLongitude(T, trueLong);
  const eps0 = meanObliquityOfTheEcliptic(T);
  const eps = apparentObliquityOfTheEcliptic(T, eps0);
  
  const appLongRad = degreesToRadians(appLong);
  const epsRad = degreesToRadians(eps);
  
  const declination = radiansToDegrees(math.asin(math.sin(epsRad) * math.sin(appLongRad)));
  const rightAscension = unwindAngle(radiansToDegrees(math.atan2(math.cos(epsRad) * math.sin(appLongRad), math.cos(appLongRad))));
  const apparentSiderealTime = unwindAngle(280.46061837 + 360.98564736629 * (jd - 2451545.0) + 0.000387933 * math.pow(T, 2) - math.pow(T, 3) / 38710000);
  return { declination, rightAscension, apparentSiderealTime };
}

const lat = 23.8103;
const lng = 90.4125;
const date = new Date(2026, 10, 4); // Nov 4 2026
const jd = julianDay(date.getFullYear(), date.getMonth() + 1, date.getDate(), 0);
const solar = solarCoordinates(jd);
const prevSolar = solarCoordinates(jd - 1);
const nextSolar = solarCoordinates(jd + 1);

const lw = lng * -1;
const m0 = normalizeToScale((solar.rightAscension + lw - solar.apparentSiderealTime) / 360, 1);
const theta = unwindAngle(solar.apparentSiderealTime + 360.985647 * m0);
const a = solar.rightAscension; // approx
const H = quadrantShiftAngle(theta - lw - a);
const dm = H / -360;
const transit = (m0 + dm) * 24;

console.log("JD:", jd);
console.log("approx transit UT hours:", m0 * 24);
console.log("corrected transit UT hours:", transit);
console.log("In UTC:", Math.floor(transit) + ":" + Math.floor((transit % 1) * 60));
console.log("In Dhaka (+6h):", Math.floor(transit + 6) + ":" + Math.floor((transit % 1) * 60));

