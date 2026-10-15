"use client";
import Image from "next/image";
import { useEffect, useRef, useState, useSyncExternalStore, type FormEvent } from "react";
import { moduleMap, type CatalogRecord, type Membership } from "@/lib/catalog";
import { dossierPath, readTrail, type DossierCrumb } from "@/lib/dossier";
import RecordList from "./record-list";
import RecordEditor from "./record-editor";
import RecordDetail from "./record-detail";
import DocumentLibrary from "./document-library";
import ExecutiveDashboard from "./executive-dashboard";
import ModuleDashboard, { dashboardKinds } from "./module-dashboard";
import GlobalSearch from "./global-search";
import DirectoryPage from "./directory-page";
import { api, ApiError, Badge, confirmDiscardChanges, ErrorBox, Icon, Loading, message, useResource } from "./ui";

type Session={user:{id:string;email:string}|null;membership:Membership|null;configured:boolean};

const roles={admin:"Quản trị viên",editor:"Biên tập viên",reader:"Chỉ đọc"};
function subscribe(callback:()=>void){window.addEventListener("hashchange",callback);return()=>window.removeEventListener("hashchange",callback);}
function getHash(){return window.location.hash.slice(1)||"overview";}
function decodeQuery(value:string){try{return decodeURIComponent(value);}catch{return value;}}
function navigate(path:string){window.location.hash=path;window.scrollTo({top:0});}
function Brand({dark=false}:{dark?:boolean}){return <div className={`brand${dark?" brand-on-dark":""}`}><Image src={`/brand/logo-pvn-lockup-horizontal-${dark?"white":"color"}.png`} width={200} height={50} alt="Petrovietnam" priority/><div className="brand-product"><strong>AI WORKSPACE</strong></div></div>;}
function Login({onLogin}:{onLogin:()=>void}){
  const [account,setAccount]=useState("");const [password,setPassword]=useState("");const [busy,setBusy]=useState(false);const [error,setError]=useState<string|null>(null);
  async function submit(event:FormEvent){event.preventDefault();setBusy(true);setError(null);try{await api("/api/auth/login",{method:"POST",body:JSON.stringify({account:account.trim(),password})});setPassword("");onLogin();}catch(e){setError(message(e));}finally{setBusy(false);}}
  return <main className="login-page"><div className="login-brand"><Brand dark/><div className="login-story"><span className="brand-rule"/><h1>Thông tin kết nối.<br/>Tri thức dùng chung.</h1><p>Cơ sở dữ liệu về đơn vị, hợp tác, bài toán, dữ liệu và đào tạo AI trong Petrovietnam.</p><div className="login-catalog"><span>Hồ sơ & nguồn</span><span>Bài toán & dữ liệu</span><span>Đào tạo & hội thảo</span></div></div><p className="login-footer">Tập đoàn Công nghiệp - Năng lượng Quốc gia Việt Nam</p></div><section className="login-form-wrap"><form className="login-form" onSubmit={submit}><div className="login-form-title"><h2>Đăng nhập</h2><p>Truy cập không gian quản trị danh mục AI.</p></div><label className="field">Email hoặc tên tài khoản<input name="account" autoComplete="username" required autoFocus value={account} onChange={e=>setAccount(e.target.value)} placeholder="Tài khoản của bạn"/><small>Tên ngắn được sử dụng với miền @pvn.vn.</small></label><label className="field">Mật khẩu<input name="password" type="password" autoComplete="current-password" required value={password} onChange={e=>setPassword(e.target.value)}/></label><ErrorBox error={error}/><button className="button primary login-submit" disabled={busy}>{busy?"Đang đăng nhập…":"Đăng nhập"}<Icon name="arrow"/></button><div className="login-access"><Icon name="shield"/><p>Quyền truy cập được cấp riêng cho ứng dụng. Liên hệ quản trị viên nếu tài khoản chưa được phân quyền.</p></div></form></section></main>;
}
export default function CatalogApp(){
  const session=useResource<{data:Session}>("/api/session");const hash=useSyncExternalStore(subscribe,getHash,()=>"overview");
  const [menu,setMenu]=useState(false);const [edit,setEdit]=useState<CatalogRecord|null>(null);const [error,setError]=useState<string|null>(null);const [loggingOut,setLoggingOut]=useState(false);
  const sidebarRef=useRef<HTMLElement>(null);
  // The last tab, list or dashboard shown before opening a record, so leaving the record returns there.
  const lastPage=useRef<string|null>(null);
  const [viewedKind,setViewedKind]=useState("");
  useEffect(()=>{if(!menu)return;const previous=document.activeElement as HTMLElement|null;sidebarRef.current?.querySelector<HTMLButtonElement>("button.mobile-only")?.focus();return()=>previous?.focus();},[menu]);
  const [pathname,queryString=""]=hash.split("?"); const [route,param=""]=pathname.split("/"); const routeParams=new URLSearchParams(queryString); const trail=readTrail(routeParams.get("trail")); const tab=routeParams.get("tab") || "overview";const membership=session.data?.data.membership;
  async function logout(){setLoggingOut(true);setError(null);try{await api("/api/auth/logout",{method:"POST"});setEdit(null);navigate("overview");session.refresh();}catch(e){setError(message(e));}finally{setLoggingOut(false);}}
  function go(path:string){if(!confirmDiscardChanges())return;setMenu(false);setEdit(null);navigate(path);}
  const recordPath=dossierPath;
  function open(id:string,origin?:DossierCrumb){go(recordPath(id,"overview",origin?[...trail,origin]:[]));}
  function openListed(id:string){open(id);}
  useEffect(()=>{if(route!=="record"&&route!=="new")lastPage.current=hash;},[route,hash]);
  function back(kind?:string){const previous=trail.at(-1); if(previous)go(recordPath(previous.id,previous.tab,trail.slice(0,-1)));else go(lastPage.current??(kind?`module/${navKind(kind)}`:"overview"));}
  function changeTab(next:string){if(!confirmDiscardChanges())return;navigate(recordPath(param,next,trail));}
  // Work items live in the item catalogue, opened from the standard problem tab.
  const navKind=(kind:string)=>kind==="work_item"?"use_case":kind;
  function create(kind:string,preset?:Record<string,string>){go(`new/${kind}${preset?`?${new URLSearchParams(preset)}`:""}`);}
  if(session.loading) return <main className="center-state"><Brand/><Loading label="Đang kiểm tra quyền truy cập…"/></main>;
  if(session.error instanceof ApiError&&session.error.status===401) return <Login onLogin={session.refresh}/>;
  if(session.error) return <main className="center-state"><Brand/><h1>Chưa thể kết nối ứng dụng</h1><p>Kiểm tra cấu hình kết nối và trạng thái dịch vụ.</p><ErrorBox error={session.error} retry={session.refresh}/></main>;
  if(session.data&&!session.data.data.configured) return <main className="center-state"><Brand/><h1>Ứng dụng đang chờ cấu hình</h1><p>Quản trị viên cần hoàn tất kết nối dữ liệu trước khi đăng nhập.</p><button className="button" onClick={session.refresh}>Kiểm tra lại</button></main>;
  if(!session.data?.data.user) return <Login onLogin={session.refresh}/>;
  if(!membership) return <main className="center-state"><Brand/><Icon name="shield" size={40}/><h1>Chưa được cấp quyền truy cập</h1><p>Tài khoản {session.data.data.user.email} đã đăng nhập nhưng chưa là thành viên của ứng dụng Danh mục AI.</p><p>Liên hệ quản trị viên để được cấp quyền phù hợp.</p><ErrorBox error={error}/><div className="actions"><button className="button primary" onClick={session.refresh}>Kiểm tra lại quyền</button><button className="button" disabled={loggingOut} onClick={logout}>Đăng xuất</button></div></main>;
  const canWrite=membership.role!=="reader"; const activeMod=(route==="module"||route==="new")?moduleMap[param]:null;
  return <div className="app-shell"><a className="skip-link" href="#main">Chuyển đến nội dung</a>{menu&&<button aria-label="Đóng điều hướng" className="sidebar-backdrop" onClick={()=>setMenu(false)}/>}<aside ref={sidebarRef} className={`sidebar ${menu?"is-open":""}`} onKeyDown={event=>{if(!menu)return;if(event.key==="Escape"){setMenu(false);return;}if(event.key!=="Tab")return;const items=Array.from(sidebarRef.current?.querySelectorAll<HTMLElement>("button:not(:disabled),a[href],input,summary")||[]).filter(item=>item.getClientRects().length);const first=items[0],last=items[items.length-1];if(event.shiftKey&&document.activeElement===first){event.preventDefault();last?.focus();}else if(!event.shiftKey&&document.activeElement===last){event.preventDefault();first?.focus();}}}><div className="sidebar-brand"><Brand dark/><button className="icon-button mobile-only" aria-label="Đóng điều hướng" onClick={()=>setMenu(false)}><Icon name="close"/></button></div><nav aria-label="Điều hướng chính"><p className="nav-caption">KHÔNG GIAN QUẢN TRỊ</p>
        <button className={`nav-item ${route==="overview"?"active":""}`} aria-current={route==="overview"?"page":undefined} onClick={()=>go("overview")}><Icon name="grid"/>Tổng quan</button>
        {[
          {kind:"use_case",label:"Danh mục hạng mục",icon:"spark",caption:"LỘ TRÌNH AI"},
          {kind:"collaboration",label:"Triển khai & hợp tác",icon:"file"},
          {kind:"partner",label:"Đối tác",icon:"people"},
          {kind:"unit",label:"Đơn vị",icon:"building"},
          {kind:"expert",label:"Chuyên gia",icon:"user"},
        ].map(item=>{const active=navKind(activeMod?.kind|| (route==="record"?viewedKind:""))===item.kind;return <span key={item.kind} className="nav-entry">{item.caption&&<p className="nav-caption">{item.caption}</p>}<button className={`nav-item ${active?"active":""}`} aria-current={active?"page":undefined} onClick={()=>go(`module/${item.kind}`)}><Icon name={item.icon}/>{item.label}</button></span>;})}
        <div className="nav-divider"/>
        <button className={`nav-item ${route==="documents"?"active":""}`} aria-current={route==="documents"?"page":undefined} onClick={()=>go("documents")}><Icon name="folder"/>File & tài liệu</button>
        <button className={`nav-item ${route==="directory"?"active":""}`} aria-current={route==="directory"?"page":undefined} onClick={()=>go("directory")}><Icon name="book"/>Danh bạ</button>
      </nav><div className="sidebar-account"><div className="avatar">{(membership.display_name||session.data.data.user.email).slice(0,1).toUpperCase()}</div><div><strong>{membership.display_name||session.data.data.user.email}</strong><span>{roles[membership.role]}</span></div><button className="icon-button" aria-label="Đăng xuất" disabled={loggingOut} onClick={logout}><Icon name="logout"/></button></div></aside><div className="workspace"><header className="topbar"><button className="icon-button mobile-only" aria-label="Mở điều hướng" aria-expanded={menu} onClick={()=>setMenu(true)}><Icon name="menu"/></button><div className="topbar-title"><span>Danh mục AI</span><span aria-hidden="true">/</span><strong>{activeMod?.label||(route==="record"?"Hồ sơ":route==="documents"?"File & tài liệu":route==="directory"?"Danh bạ":route==="search"?"Tra cứu":"Tổng quan")}</strong></div><GlobalSearch key={route==="search"?`search-${param}`:pathname} initial={route==="search"?decodeQuery(param):""} onOpen={id=>open(id)} onSearch={query=>go(`search/${encodeURIComponent(query)}`)}/><Badge>{roles[membership.role]}</Badge></header><main id="main" tabIndex={-1} className="main-content"><ErrorBox error={error}/>{route==="record" && trail.length>0 && <nav className="dossier-breadcrumb" aria-label="Đường dẫn hồ sơ">{trail.map((crumb,index)=><button className="text-button" key={`${crumb.id}-${index}`} onClick={()=>go(recordPath(crumb.id,crumb.tab,trail.slice(0,index)))}>{crumb.title}<Icon name="arrow" size={14}/></button>)}</nav>}{edit&&canWrite?<RecordEditor key={edit.id} kind={edit.kind} record={edit} onCancel={()=>setEdit(null)} onSave={record=>{setEdit(null);go(recordPath(record.id,tab,trail));}}/>:route==="new"&&activeMod&&canWrite?<RecordEditor key={`new-${param}`} kind={param} preset={Object.fromEntries([...routeParams].filter(([key])=>activeMod?.fields.some(field=>field.key===key)))} onCancel={()=>back(param)} onSave={record=>open(record.id)}/>:route==="record"&&param?<RecordDetail key={param} id={param} membership={membership} onOpen={open} onEdit={setEdit} onBack={back} onDeleted={back} onKind={setViewedKind} activeTab={tab} onTab={changeTab}/>:route==="module"&&activeMod&&dashboardKinds.has(param)?<ModuleDashboard key={param} kind={param} canWrite={canWrite} onOpen={id=>openListed(id)} onCreate={create}/>:route==="module"&&activeMod?<RecordList key={param} kind={param} canWrite={canWrite} onOpen={openListed} onCreate={create}/>:route==="search"?<RecordList key={hash} initialQuery={decodeQuery(param)} canWrite={canWrite} onOpen={openListed} onCreate={create}/>:route==="documents"?<DocumentLibrary membership={membership} onOpen={open}/>:route==="directory"?<DirectoryPage onOpen={open}/>:<ExecutiveDashboard canWrite={canWrite} onCreate={create} onOpenModule={kind=>go(`module/${kind}`)} onOpenRecord={open}/>}</main><footer className="app-footer"><div><strong>Petrovietnam</strong><span>Tập đoàn Công nghiệp – Năng lượng Quốc gia Việt Nam</span></div><span>AI WORKSPACE</span></footer></div></div>;
}
