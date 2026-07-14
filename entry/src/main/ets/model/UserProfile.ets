/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0.
 */

/**
 * Editable user information shown on the profile page.
 *
 * Keep this model free of UI dependencies so it can also be reused by a
 * future account page or cloud synchronization service.
 */
import { CommonConstants as Const } from '../common/constants/CommonConstants';

export default class UserProfile {
  avatarUri: string = '';
  /** Empty means the system placeholder; otherwise this is a bundled avatar id. */
  avatarId: string = '';
  nickname: string = Const.NICK_NAME;
  signature: string = Const.SIGNATURE;
  gender: string = '保密';
  birthDate: string = '1990-01-01';
  height: number = 170;
  weight: number = 60;
}
